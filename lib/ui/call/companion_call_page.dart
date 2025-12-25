import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/create_session/session_model.dart';import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_calls_page.dart';
import '../../widgets/pre_call_dialog.dart';

class CompanionCallPage extends StatefulWidget {
  final User user;
  final CallSetupDetails callDetails;
  final IncomingCall? incomingCall;
  const CompanionCallPage({
    Key? key,
    required this.user,
    required this.callDetails,
    this.incomingCall,
  }) : assert(callDetails != null || incomingCall != null, "Either callDetails or incomingCall must be provided"),
        super(key: key);

  @override
  State<CompanionCallPage> createState() => _CompanionCallPageState();
}


class _CompanionCallPageState extends State<CompanionCallPage> {
  String _callStatus = "Calling Claire...";
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;

  String? _channelName;
  String? _callDocId;

  StreamSubscription? _callDocSubscription;
  bool _diaryCreationInProgress = false;

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
      if (mounted) {
        setState(() {
          _callDurationInSeconds++;
        });
      }
    });
  }
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    if (widget.incomingCall != null) {
      // SCENARIO B: We are JOINING an existing call from an admin
      print("Joining an existing companion call...");
      _callDocId = widget.incomingCall!.doc.id;
      _channelName = widget.incomingCall!.channelName;
      // Skip _initiateCall and go straight to setting up the engine
      _setupVoiceSDKEngine();
    } else {
      // SCENARIO A: We are INITIATING a new call to an admin
      print("Initiating a new companion call...");
      _initiateCall();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // NEW: Stop the timer
    _callDocSubscription?.cancel();
    _endCall();
    super.dispose();
  }

  Future<void> _initiateCall() async {
    try {
      final callerId = widget.user.uid;
      final callId = const Uuid().v4();
      _callDocId = callId;
      _channelName = 'companion_call_$callId';
      final adminId = "claire_admin";

      await FirebaseFirestore.instance.collection('companion_calls').doc(_callDocId).set({
        'callerId': callerId,
        'receiverId': adminId,
        'channelName': _channelName,
        'status': 'dialing',
        'createdAt': FieldValue.serverTimestamp(),
        'recordingUrl': null,
        'title': widget.callDetails.title,
        'moodId': widget.callDetails.moodId,
        'isPrivate': widget.callDetails.isPrivate,
        'repliesEnabled': widget.callDetails.repliesEnabled,
        'locationEnabled': widget.callDetails.locationEnabled,
        'locationData': widget.callDetails.locationData,
      });

      _listenForRecording();
      await _setupVoiceSDKEngine();

    } catch (e) {
      print("Error initiating call: $e");
      setState(() {
        _callStatus = "Failed to start call. Authentication might have failed.";
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _listenForRecording() {
    if (_callDocId == null) return;
    _callDocSubscription = FirebaseFirestore.instance
        .collection('companion_calls')
        .doc(_callDocId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || _diaryCreationInProgress) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final recordingUrl = data['recordingUrl'] as String?;
      final status = data['status'] as String?;

      if (recordingUrl != null && recordingUrl.isNotEmpty && status == 'ended') {
        _diaryCreationInProgress = true; // Prevent multiple executions
        await _createDiarySessionFromCall(recordingUrl);
        _callDocSubscription?.cancel();
      }
    });
  }

  Future<void> _createDiarySessionFromCall(String audioUrl) async {
    // This method remains unchanged
    print('COMPANION_CALL: Creating diary session from URL: $audioUrl');

    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();

    final currentUserInfo = await _firebaseServices.getUserWithId(id: widget.user.uid);
    if (currentUserInfo == null) {
      print('COMPANION_CALL: Failed to get user model for diary creation.');
      return;
    }

    final callDoc = await FirebaseFirestore.instance.collection('companion_calls').doc(_callDocId).get();
    if (!callDoc.exists) {
      print('COMPANION_CALL: Original call document not found. Cannot create session.');
      return;
    }
    final callData = callDoc.data() as Map<String, dynamic>;

    CreateSessionModel sessionObject = CreateSessionModel();
    final randomColor = Constant.DIARY_COLORS_HEXCODE[Random().nextInt(Constant.DIARY_COLORS_HEXCODE.length)];
    String finalLocationString = '#CompanionCall';
    if (callData['locationEnabled'] == true && (callData['locationData'] as String).isNotEmpty) {
      finalLocationString = callData['locationData'];
    }

    sessionObject.audioUrl = audioUrl;
    sessionObject.containsAudio = true;
    sessionObject.userAvatarUrl = currentUserInfo.avatarUrl;
    sessionObject.userNickname = currentUserInfo.nickname;
    sessionObject.title = callData['title'] ?? "Companion Call Session";
    sessionObject.private = callData['isPrivate'] ?? true;
    sessionObject.repliesEnabled = callData['repliesEnabled'] ?? false;
    sessionObject.message = "This diary session was recorded during a Companion Mode call with Claire. #CompanionCall";
    sessionObject.colorHex = randomColor;
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = currentUserInfo.userId;
    sessionObject.moodId = callData['moodId'] ?? 17;
    sessionObject.location = finalLocationString;
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessful = await _firebaseServices.createSession(session: sessionObject);

    if (isSuccessful) {
      print('COMPANION_CALL: Firestore session created successfully.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your call has been saved to your diary.")));
      }
    } else {
      print('COMPANION_CALL: Failed to create Firestore session.');
    }
  }

  Future<void> _setupVoiceSDKEngine() async {
    if (_channelName == null) {
      print("Channel name is not set. Cannot setup Agora engine.");
      return;
    }
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: "b476113d691f42dcb7bc6882021afc9c",
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _isJoined = true;
            _callStatus = "Ringing...";
          });
          if (_callDocId != null) {
            FirebaseFirestore.instance
                .collection('companion_calls')
                .doc(_callDocId)
                .update({'status': 'ringing'});
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _callStatus = "Connected";
          });
          // --- NEW: Start the timer when admin joins ---
          _startCallTimer();
          // --- END NEW ---
          if (_callDocId != null) {
            FirebaseFirestore.instance
                .collection('companion_calls')
                .doc(_callDocId)
                .update({'status': 'active'});
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _endCall();
        },
        onError: (ErrorCodeType err, String msg) {
          print('[Agora Error] err: $err, msg: $msg');
          setState(() {
            _callStatus = "Error. Please try again.";
          });
          _endCall();
        },
      ),
    );
    await _join();
  }

  Future<void> _join() async {
    // This method remains unchanged
    if (_channelName == null) return;
    String token;
    try {
      await widget.user.getIdToken(true);
      final callable =
      FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': _channelName,
      });
      token = result.data['token'];
      print("Successfully fetched Agora token for Companion Call.");
    } catch (e) {
      print("Error fetching Agora token: $e");
      setState(() {
        _callStatus = "Error: Could not get token.";
      });
      _endCall();
      return;
    }
    await _engine?.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine?.joinChannel(
      token: token,
      channelId: _channelName!,
      options: const ChannelMediaOptions(),
      uid: 0,
    );
  }


  Future<void> _endCall() async {
    _timer?.cancel();
    await _callDocSubscription?.cancel();

    // --- FIX: Update status on hangup if call was not connected ---
    if (_remoteUid == null && _callDocId != null) {
      // If no admin ever joined, mark the call as 'missed'.
      await FirebaseFirestore.instance
          .collection('companion_calls')
          .doc(_callDocId)
          .update({'status': 'missed'})
          .catchError((e) => print("Error marking call as missed: $e"));
    }

    if (_engine != null) {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
    }

    _isJoined = false;
    _remoteUid = null;

    if (mounted) {
      setState(() {
        _callStatus = "Call Ended";
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }


  // In /lib/ui/call/companion_call_page.dart

  @override
  Widget build(BuildContext context) {
    // If we are joining, get info from`incomingCall`.
    // If we are creating a new call, get it from `callDetails`.
    final String title = widget.incomingCall?.title ?? widget.callDetails.title;
    final int moodId = widget.incomingCall?.moodId ?? widget.callDetails.moodId;
    final String locationData = widget.incomingCall?.locationData ?? widget.callDetails.locationData;

    final moodIcon = Constant.USER_SESSION_MOODS[moodId];
    final hasLocation = locationData.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorSecondary.withValues(alpha: 0.5), Colors.black],
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
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  title, // Use the corrected title variable
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
                          locationData, // Use the corrected location variable
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
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

