import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_calls_page.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/color.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AdminCallPage extends StatefulWidget {
  final User user;
  final IncomingCall call;

  const AdminCallPage({
    Key? key,
    required this.user,
    required this.call,
  }) : super(key: key);

  @override
  State<AdminCallPage> createState() => _AdminCallPageState();
}

class _AdminCallPageState extends State<AdminCallPage> {
  String _callStatus = "Connecting...";
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;
  String? _recordingPath;
  StreamSubscription? _statusSubscription;
  bool _isEnding = false;

  // --- NEW: For the call timer ---
  Timer? _timer;
  int _callDurationInSeconds = 0;

  String get _durationString {
    final duration = Duration(seconds: _callDurationInSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCallTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationInSeconds++;
      });
    });
  }
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    _setupAndJoin();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusSubscription?.cancel();
    if (!_isEnding) {
      _endCall();
    }
    super.dispose();
  }

  Future<void> _setupAndJoin() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: "b476113d691f42dcb7bc6882021afc9c",
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
            setState(() {
              _isJoined = true;
              _callStatus = "Waiting for user...";
            });

            try {
              final FirebaseServices firebaseServices = FirebaseServices();
              final adminUserModel =
              await firebaseServices.getUserWithId(id: widget.user.uid);

              await FirebaseFirestore.instance
                  .collection('companion_calls')
                  .doc(widget.call.doc.id)
                  .update({
                'receiverId': adminUserModel.alterEgoId,
              });
              print(
                  "Updated call document with admin alterEgoId: ${adminUserModel.alterEgoId}");
            } catch (e) {
              print("Error updating call document with alterEgoId: $e");
            }

            _startRecording();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
              _callStatus = "Connected";
            });
            _startCallTimer();
            FirebaseFirestore.instance
                .collection('companion_calls')
                .doc(widget.call.doc.id)
                .update({'status': 'active'});
          },
          onUserOffline:
              (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _endCall();
          },
          onError: (ErrorCodeType err, String msg) {
            print('[Agora Error] err: $err, msg: $msg');
            _endCall();
          },
        ),
      );

      // --- NEW: Status Listener to detect User hangup ---
      _statusSubscription = FirebaseFirestore.instance
          .collection('companion_calls')
          .doc(widget.call.doc.id)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final status = data['status'];
          // If User ends or misses the call while Admin is joined/connecting
          if ((status == 'ended' || status == 'missed') && _isJoined) {
            _endCall();
          }
        }
      });

      await _join();
    } catch (e) {
      print("Error setting up Agora for admin: $e");
      setState(() {
        _callStatus = "Failed to connect.";
      });
    }
  }


  Future<void> _join() async {
    String token;
    try {
      await widget.user.getIdToken(true);

      final callable =
      FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': widget.call.channelName,
        'uid': 1, // The admin will have a static UID of 1
      });
      token = result.data['token'];
      print("Successfully fetched Admin Agora token.");
    } catch (e) {
      print("Error fetching Admin Agora token: $e");
      setState(() {
        _callStatus = "Error: Could not get admin token.";
      });
      _endCall();
      return;
    }

    await _engine
        ?.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine?.joinChannel(
      token: token,
      channelId: widget.call.channelName,
      options: const ChannelMediaOptions(),
      uid: 1, // Admin user uid, must be non-zero
    );
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _recordingPath = '${directory.path}/rec_${widget.call.doc.id}.aac';

    try {
      await _engine?.startAudioRecording(AudioRecordingConfiguration(
        filePath: _recordingPath!,
        fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
        quality: AudioRecordingQualityType.audioRecordingQualityMedium,
      ));
      print("Recording started at: $_recordingPath");
    } catch (e) {
      print("!!! CRITICAL: Error starting audio recording: $e");
      _recordingPath = null;
    }
  }

  Future<void> _stopRecordingAndUpload({String status = 'ended'}) async {
    if (_recordingPath == null) {
      await FirebaseFirestore.instance
          .collection('companion_calls')
          .doc(widget.call.doc.id)
          .update({'status': status, 'endedAt': FieldValue.serverTimestamp()})
          .catchError((e) => print("Error updating status: $e"));
      return;
    }

    await _engine?.stopAudioRecording();
    File file = File(_recordingPath!);
    if (await file.exists()) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('companion_recordings/${widget.call.doc.id}.aac');
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('companion_calls')
            .doc(widget.call.doc.id)
            .update({
          'recordingUrl': downloadUrl,
          'status': status,
          'endedAt': FieldValue.serverTimestamp()
        });
        await file.delete();
      } catch (e) {
        await FirebaseFirestore.instance
            .collection('companion_calls')
            .doc(widget.call.doc.id)
            .update({'status': status, 'endedAt': FieldValue.serverTimestamp()});
      }
    } else {
      await FirebaseFirestore.instance
          .collection('companion_calls')
          .doc(widget.call.doc.id)
          .update({'status': status, 'endedAt': FieldValue.serverTimestamp()});
    }
    _recordingPath = null;
  }


  Future<void> _endCall() async {
    if (_isEnding) return;
    _isEnding = true;
    _timer?.cancel();
    _statusSubscription?.cancel();

    String finalStatus = (_remoteUid != null) ? 'ended' : 'rejected';

    await _stopRecordingAndUpload(status: finalStatus);

    if (mounted) {
      Navigator.of(context).pop();
    }

    if (_engine != null) {
      await _engine?.leaveChannel();
      Future.delayed(const Duration(milliseconds: 200), () {
        _engine?.release();
        _engine = null;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    // --- NEW: Extract details for the UI ---
    final moodIcon = Constant.USER_SESSION_MOODS[widget.call.moodId];
    final hasLocation = widget.call.locationData.isNotEmpty;
    // --- END NEW ---

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorPrimary.withValues(alpha: 0.5), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.support_agent,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  widget.call.title,
                  style: GoogleFonts.lato(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _callStatus == "Connected" ? _durationString : _callStatus,
                style: GoogleFonts.lato(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              // --- NEW: Display Mood and Location ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(moodIcon, style: const TextStyle(fontSize: 22)),
                    if (hasLocation) const SizedBox(width: 12),
                    if (hasLocation)
                      Icon(Icons.location_on,
                          color: Colors.grey.shade400, size: 18),
                    if (hasLocation) const SizedBox(width: 4),
                    if (hasLocation)
                      Flexible(
                        child: Text(
                          widget.call.locationData,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // --- END NEW ---
              const Spacer(flex: 3),
              _buildHangUpButton(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHangUpButton() {
    return GestureDetector(
      onTap: () {
        _endCall();
      },
      child: const CircleAvatar(
        radius: 35,
        backgroundColor: Colors.red,
        child: Icon(
          Icons.call_end,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
