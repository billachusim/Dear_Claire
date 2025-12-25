import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_calls_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/color.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../utils/constant.dart';

class AdminLiveCallPage extends StatefulWidget {
  final User user;
  final IncomingCall call; // MODIFIED

  const AdminLiveCallPage({
    Key? key,
    required this.user,
    required this.call, // MODIFIED
  }) : super(key: key);

  @override
  State<AdminLiveCallPage> createState() => _AdminLiveCallPageState();
}

class _AdminLiveCallPageState extends State<AdminLiveCallPage> {
  String _callStatus = "Connecting to Live Session...";
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _localUserJoined = false;
  String? _recordingPath;

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
    _timer?.cancel();
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
    _timer?.cancel(); // NEW
    _endCall();
    super.dispose();
  }

  Future<void> _setupAndJoin() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: "b476113d691f42dcb7bc6882021afc9c",
      ));
      await _engine!.enableVideo();

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
            setState(() {
              _localUserJoined = true;
              _isJoined = true;
              _callStatus = "Waiting for user...";
            });

            try {
              final FirebaseServices firebaseServices = FirebaseServices();
              final adminUserModel = await firebaseServices.getUserWithId(id: widget.user.uid);
              await FirebaseFirestore.instance
                  .collection('live_sessions')
                  .doc(widget.call.doc.id)
                  .update({'receiverId': adminUserModel.alterEgoId});
              print("Updated live session with admin alterEgoId: ${adminUserModel.alterEgoId}");
            } catch (e) {
              print("Error updating live session with alterEgoId: $e");
            }
            _startRecording();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
              _callStatus = "Connected";
            });
            _startCallTimer(); // NEW: Start timer when connected
            FirebaseFirestore.instance
                .collection('live_sessions')
                .doc(widget.call.doc.id)
                .update({'status': 'active'});
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _endCall();
          },
          onError: (ErrorCodeType err, String msg) {
            print('[Agora Error] err: $err, msg: $msg');
            _endCall();
          },
        ),
      );
      await _join();
    } catch (e) {
      print("Error setting up Agora for admin: $e");
    }
  }

  Future<void> _join() async {
    String token;
    try {
      await widget.user.getIdToken(true);
      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': widget.call.channelName,
        'uid': 1,
      });
      token = result.data['token'];
    } catch (e) {
      print("Error fetching Admin Agora token for Live Session: $e");
      _endCall();
      return;
    }

    await _engine?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.startPreview();
    await _engine?.joinChannel(
      token: token,
      channelId: widget.call.channelName,
      options: const ChannelMediaOptions(),
      uid: 1,
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
      print("Live Session audio recording started at: $_recordingPath");
    } catch (e) {
      print("!!! CRITICAL: Error starting live session recording: $e");
      _recordingPath = null;
    }
  }

  Future<void> _stopRecordingAndUpload() async {
    if (_recordingPath == null) {
      await FirebaseFirestore.instance
          .collection('live_sessions')
          .doc(widget.call.doc.id)
          .update({'status': 'ended'}).catchError((e) => print("Error updating status: $e"));
      return;
    }

    await _engine?.stopAudioRecording();
    File file = File(_recordingPath!);
    String? downloadUrl;
    try {
      if (await file.exists()) {
        final storageRef = FirebaseStorage.instance.ref().child('live_session_recordings/${widget.call.doc.id}.aac');
        await storageRef.putFile(file);
        downloadUrl = await storageRef.getDownloadURL();
        await file.delete();
      }
    } catch (e) {
      print("Error uploading live session recording: $e");
    }

    try {
      await FirebaseFirestore.instance
          .collection('live_sessions')
          .doc(widget.call.doc.id)
          .update({'recordingUrl': downloadUrl, 'status': 'ended'});
    } catch (e) {
      print("Error performing final update on live session document: $e");
    }
    _recordingPath = null;
  }

  Future<void> _endCall() async {
    _timer?.cancel(); // NEW
    await _stopRecordingAndUpload();
    if (_engine != null) {
      await _engine?.stopPreview();
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _remoteVideo(),
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: _localUserJoined
                        ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 1),
                      ),
                    )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
            _toolbar(),
            // --- NEW: Display Timer and Title ---
            _callInfoOverlay(),
            // --- END NEW ---
          ],
        ),
      ),
    );
  }


  Widget _callInfoOverlay() {
    // --- NEW: Extract mood and location for UI ---
    final moodIcon = Constant.USER_SESSION_MOODS[widget.call.moodId];
    final hasLocation = widget.call.locationData.isNotEmpty;
    // --- END NEW ---

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Title ---
              Text(
                widget.call.title,
                style: GoogleFonts.lato(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // --- Status and Timer ---
              Text(
                _callStatus == "Connected" ? _durationString : _callStatus,
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
              ),
              // --- NEW: Display Mood and Location ---
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(moodIcon, style: const TextStyle(fontSize: 16)),
                  if (hasLocation) const SizedBox(width: 10),
                  if (hasLocation)
                    Icon(Icons.location_on, color: Colors.grey.shade300, size: 14),
                  if (hasLocation) const SizedBox(width: 4),
                  if (hasLocation)
                    Text(
                      widget.call.locationData,
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              // --- END NEW ---
            ],
          ),
        ),
      ),
    );
  }


  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.call.channelName),
        ),
      );
    } else {
      // Placeholder UI before the remote user joins
      return Container(
        color: Pallet.colorSecondary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white70, size: 60),
              const SizedBox(height: 20),
              Text(
                'Waiting for user to join...',
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _endCall,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
          )
        ],
      ),
    );
  }
}
