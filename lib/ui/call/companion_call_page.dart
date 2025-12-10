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

class CompanionCallPage extends StatefulWidget {
  final User user; // Accept the user object

  const CompanionCallPage({Key? key, required this.user}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _initiateCall(); // Directly initiate the call
  }

  @override
  void dispose() {
    _callDocSubscription?.cancel();
    _endCall();
    super.dispose();
  }

  Future<void> _initiateCall() async {
    try {
      // Use the user object passed to the widget
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
      });

      // Start listening to the document for the recording URL
      _listenForRecording();

      await _setupVoiceSDKEngine();

    } catch (e) {
      print("Error initiating call: $e");
      setState(() {
        _callStatus = "Failed to start call. Authentication might have failed.";
      });
      // Pop the page if initiation fails
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  /// Listens for the recordingUrl to appear in the Firestore document.
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

  /// Creates a new diary session using the logic from auto_diary.dart.
  Future<void> _createDiarySessionFromCall(String audioUrl) async {
    print('COMPANION_CALL: Creating diary session from URL: $audioUrl');

    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();

    final currentUserInfo = await _firebaseServices.getUserWithId(id: widget.user.uid);
    if (currentUserInfo == null) {
      print('COMPANION_CALL: Failed to get user model for diary creation.');
      return;
    }

    CreateSessionModel sessionObject = CreateSessionModel();

    final randomColor = Constant.DIARY_COLORS_HEXCODE[Random().nextInt(Constant.DIARY_COLORS_HEXCODE.length)];

    // Populate the session object
    sessionObject.audioUrl = audioUrl;
    sessionObject.containsAudio = true;
    sessionObject.userAvatarUrl = currentUserInfo.avatarUrl;
    sessionObject.userNickname = currentUserInfo.nickname;
    sessionObject.title = "Companion Call Session";
    sessionObject.private = true;
    sessionObject.repliesEnabled = false;
    sessionObject.message =
    "This diary session was recorded during a Companion Mode call with Claire. #CompanionCall";
    sessionObject.colorHex = randomColor;
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = currentUserInfo.userId;
    sessionObject.moodId = 17; // Claire mood 🌺
    sessionObject.location = '#Claire';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessful =
    await _firebaseServices.createSession(session: sessionObject);

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

    await _callDocSubscription?.cancel();

    // The user's primary responsibility is to leave the Agora channel.
    // The admin is responsible for updating the final document status.
    // This prevents race conditions where the user sets 'status' to 'ended' too early.
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
      // Delay to show the "Call Ended" message before popping the screen.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorSecondary.withOpacity(0.5), Colors.black],
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
              Text(
                "Claire",
                style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                _callStatus,
                style: GoogleFonts.lato(fontSize: 18, color: Colors.white70),
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
