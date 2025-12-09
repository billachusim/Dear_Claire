import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/create_session/session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class LiveCallPage extends StatefulWidget {
  final User user; // Accept the user object

  const LiveCallPage({Key? key, required this.user}) : super(key: key);

  @override
  State<LiveCallPage> createState() => _LiveCallPageState();
}

class _LiveCallPageState extends State<LiveCallPage> {
  String _callStatus = "Calling Claire for a Live Session...";
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

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
      _channelName = 'live_session_$callId';

      final adminId = "claire_admin";

      await FirebaseFirestore.instance.collection('live_sessions').doc(_callDocId).set({
        'callerId': callerId,
        'receiverId': adminId,
        'channelName': _channelName,
        'status': 'dialing',
        'type': 'video',
        'createdAt': FieldValue.serverTimestamp(),
        'recordingUrl': null, // Initialize field
      });

      // Start listening for the recording
      _listenForRecording();

      await _setupVideoSDKEngine();
    } catch (e) {
      print("Error initiating live call: $e");
      setState(() {
        _callStatus = "Failed to start live session.";
      });
      // Pop the page if initiation fails
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _listenForRecording() {
    if (_callDocId == null) return;
    _callDocSubscription = FirebaseFirestore.instance
        .collection('live_sessions')
        .doc(_callDocId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || _diaryCreationInProgress) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final recordingUrl = data['recordingUrl'] as String?;
      final status = data['status'] as String?;

      if (recordingUrl != null && recordingUrl.isNotEmpty && status == 'ended') {
        _diaryCreationInProgress = true;
        await _createDiarySessionFromCall(recordingUrl);
        _callDocSubscription?.cancel();
      }
    });
  }

  Future<void> _createDiarySessionFromCall(String audioUrl) async {
    print('LIVE_CALL: Creating diary session from URL: $audioUrl');

    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();

    final currentUserInfo = await _firebaseServices.getUserWithId(id: widget.user.uid);
    if (currentUserInfo == null) {
      print('LIVE_CALL: Failed to get user model for diary creation.');
      return;
    }

    CreateSessionModel sessionObject = CreateSessionModel();
    final randomColor = Constant.DIARY_COLORS_HEXCODE[Random().nextInt(Constant.DIARY_COLORS_HEXCODE.length)];

    sessionObject.audioUrl = audioUrl;
    sessionObject.containsAudio = true;
    sessionObject.userAvatarUrl = currentUserInfo.avatarUrl;
    sessionObject.userNickname = currentUserInfo.nickname;
    sessionObject.title = "Live Session with Claire";
    sessionObject.private = true;
    sessionObject.repliesEnabled = false;
    sessionObject.message =
    "This diary session contains audio recorded during a Live Session with Claire. #LiveSession";
    sessionObject.colorHex = randomColor;
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = currentUserInfo.userId;
    sessionObject.moodId = 17; // Claire mood 🌺
    sessionObject.location = '#ClaireLive';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessful = await _firebaseServices.createSession(session: sessionObject);

    if (isSuccessful) {
      print('LIVE_CALL: Firestore session created successfully.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your Live Session has been saved to your diary.")));
      }
    } else {
      print('LIVE_CALL: Failed to create Firestore session.');
    }
  }


  Future<void> _setupVideoSDKEngine() async {
    if (_channelName == null) return;

    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: "b476113d691f42dcb7bc6882021afc9c",
    ));

    await _engine!.enableVideo();

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
            _callStatus = "Ringing...";
          });
          FirebaseFirestore.instance
              .collection('live_sessions')
              .doc(_callDocId)
              .update({'status': 'ringing'});
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _callStatus = "Connected";
          });
          FirebaseFirestore.instance
              .collection('live_sessions')
              .doc(_callDocId)
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
  }

  Future<void> _join() async {
    if (_channelName == null) return;
    String token;
    try {
      await widget.user.getIdToken(true);
      // The user's auth state is now guaranteed by the navigation logic.
      final callable =
      FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': _channelName,
      });
      token = result.data['token'];
      print("Successfully fetched Agora token for Live Session.");
    } catch (e) {
      print("Error fetching Agora token for Live Session: $e");
      setState(() {
        _callStatus = "Error: Could not get token.";
      });
      _endCall();
      return; // Stop execution
    }

    await _engine?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.startPreview();
    await _engine?.joinChannel(
      token: token, // Use the fetched token
      channelId: _channelName!,
      options: const ChannelMediaOptions(),
      uid: 0,
    );
  }

  Future<void> _endCall() async {
    if (_engine == null) return;

    if (_callDocId != null) {
      await FirebaseFirestore.instance
          .collection('live_sessions')
          .doc(_callDocId)
          .update({'status': 'ended'}).catchError((e) {
        print("Error updating Firestore on leave: $e");
      });
    }

    await _engine?.stopPreview();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;

    if (mounted) {
      Future.delayed(const Duration(seconds: 3), () {
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
      body: Center(
        child: Stack(
          children: <Widget>[
            _remoteVideo(),
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 120,
                height: 160,
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
                    : const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            _toolbar(),
          ],
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
          connection: RtcConnection(channelId: _channelName!),
        ),
      );
    } else {
      return Container(
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
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.videocam,
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
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          )
        ],
      ),
    );
  }
}
