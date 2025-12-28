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

import '../../widgets/pre_call_dialog.dart';
import '../alter_ego/alter_ego_calls_page.dart';

class LiveCallPage extends StatefulWidget {
  final User user;
  final CallSetupDetails callDetails;
  final IncomingCall? incomingCall;
  const LiveCallPage({
    Key? key,
    required this.user,
    required this.callDetails,
    this.incomingCall,
  }) : assert(callDetails != null || incomingCall != null, "Either callDetails or incomingCall must be provided"),
        super(key: key);
  @override
  State<LiveCallPage> createState() => _LiveCallPageState();
}


class _LiveCallPageState extends State<LiveCallPage> {
  String _callStatus = "Calling Claire for a Live Session...";
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isEnding = false;
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
      _setupVideoSDKEngine();
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
    if (!_isEnding) {
      _endCall(manual: false);
    }
    super.dispose();
  }

  // In /lib/ui/call/live_call_page.dart
  Future<void> _initiateCall() async {
    try {
      final callerId = widget.user.uid;
      final callId = const Uuid().v4();
      _callDocId = callId;
      _channelName = 'live_session_$callId';
      final adminId = "claire_admin";

      // --- ADD NEW FIELDS TO THE DOCUMENT ---
      await FirebaseFirestore.instance.collection('live_sessions').doc(_callDocId).set({
        'callerId': callerId,
        'receiverId': adminId,
        'channelName': _channelName,
        'status': 'dialing',
        'type': 'video', // Specific to live call
        'createdAt': FieldValue.serverTimestamp(),
        'recordingUrl': null,
        // --- Details from the dialog ---
        'title': widget.callDetails.title,
        'moodId': widget.callDetails.moodId,
        'isPrivate': widget.callDetails.isPrivate,
        'repliesEnabled': widget.callDetails.repliesEnabled,
        'locationEnabled': widget.callDetails.locationEnabled,
        'locationData': widget.callDetails.locationData,
      });

      _listenForRecording();
      await _setupVideoSDKEngine();

    } catch (e) {
      print("Error initiating live call: $e");
      setState(() {
        _callStatus = "Failed to start live session.";
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }


  void _listenForRecording() {
    // Inside _listenForRecording()
    _callDocSubscription = FirebaseFirestore.instance
        .collection('live_sessions')
        .doc(_callDocId)
        .snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final recordingUrl = data['recordingUrl'] as String?;
      final status = data['status'] as String?;

      // 1. If Claire ended the call, the status becomes 'ended'
      if (status == 'ended' || status == 'rejected') {
        // 2. If there is a recording, wait for it to create the diary
        if (recordingUrl != null && recordingUrl.isNotEmpty && !_diaryCreationInProgress) {
          _diaryCreationInProgress = true;
          await _createDiarySessionFromCall(recordingUrl);
          _endCall(manual: false); // Now safely pop
        }
        // 3. If no recording is expected or it's been a few seconds, just pop
        else if (!_diaryCreationInProgress) {
          _endCall(manual: false);
        }
      }
    });

  }

  Future<void> _createDiarySessionFromCall(String audioUrl) async {
    // This method remains unchanged
    print('LIVE_CALL: Creating diary session from URL: $audioUrl');

    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();

    final currentUserInfo = await _firebaseServices.getUserWithId(id: widget.user.uid);
    if (currentUserInfo == null) {
      print('LIVE_CALL: Failed to get user model for diary creation.');
      return;
    }

    final callDoc = await FirebaseFirestore.instance.collection('live_sessions').doc(_callDocId).get();
    if (!callDoc.exists) {
      print('LIVE_CALL: Original call document not found. Cannot create session.');
      return;
    }
    final callData = callDoc.data() as Map<String, dynamic>;

    CreateSessionModel sessionObject = CreateSessionModel();
    final randomColor = Constant.DIARY_COLORS_HEXCODE[Random().nextInt(Constant.DIARY_COLORS_HEXCODE.length)];
    String finalLocationString = '#LiveSession';
    if (callData['locationEnabled'] == true && (callData['locationData'] as String).isNotEmpty) {
      finalLocationString = callData['locationData'];
    }

    sessionObject.audioUrl = audioUrl;
    sessionObject.containsAudio = true;
    sessionObject.userAvatarUrl = currentUserInfo.avatarUrl;
    sessionObject.userNickname = currentUserInfo.nickname;
    sessionObject.title = callData['title'] ?? "Live Session with Claire";
    sessionObject.private = callData['isPrivate'] ?? true;
    sessionObject.repliesEnabled = callData['repliesEnabled'] ?? false;
    sessionObject.message =
    "This diary session contains audio recorded during a Live Session with Claire. #LiveSession";
    sessionObject.colorHex = randomColor;
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = currentUserInfo.userId;
    sessionObject.moodId = callData['moodId'] ?? 17;
    sessionObject.location = finalLocationString;
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
    // This method remains unchanged
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
          // --- NEW: Start the timer when admin joins ---
          _startCallTimer();
          // --- END NEW ---
          FirebaseFirestore.instance
              .collection('live_sessions')
              .doc(_callDocId)
              .update({'status': 'active'});
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _endCall(manual: false);
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
      print("Successfully fetched Agora token for Live Session.");
    } catch (e) {
      print("Error fetching Agora token for Live Session: $e");
      setState(() {
        _callStatus = "Error: Could not get token.";
      });
      _endCall();
      return;
    }

    await _engine?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.startPreview();
    await _engine?.joinChannel(
      token: token,
      channelId: _channelName!,
      options: const ChannelMediaOptions(),
      uid: 0,
    );
  }


  Future<void> _endCall({bool manual = false}) async {
    if (_isEnding) return; // Prevent re-entry

    // 1. Gatekeeper: Only show popup if USER manually hangs up an active call
    if (manual && (_remoteUid != null || _callStatus == "Connected")) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("End Session?"),
          content: const Text("Please ask Claire to end the call so she can save this as a diary session for you."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    _isEnding = true; // Mark as terminating immediately

    // 2. Stop logic first
    _timer?.cancel();
    await _callDocSubscription?.cancel();

    // 3. Update Firestore status ONLY if it's not already ended/rejected
    if (_callDocId != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('live_sessions').doc(_callDocId);
        final snapshot = await docRef.get();
        if (snapshot.exists) {
          String currentStatus = snapshot.data()?['status'] ?? '';

          if (currentStatus != 'ended' && currentStatus != 'rejected') {
            await docRef.update({
              'status': 'ended',
              'endedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (e) {
        print("Error updating status: $e");
      }
    }

    // 4. POP FIRST - This removes the video renderer from the widget tree
    if (mounted) {
      Navigator.of(context).pop();
    }

    // 5. CLEANUP AFTER POP - Prevents the black screen/renderer crash
    if (_engine != null) {
      await _engine?.stopPreview();
      await _engine?.leaveChannel();
      // Delay release slightly so the route transition can complete
      Future.delayed(const Duration(milliseconds: 200), () {
        _engine?.release();
        _engine = null;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    // This method remains unchanged
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _remoteVideo(),
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
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
            ),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    // This method remains unchanged, but the 'else' block will now show a timer.
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _channelName!),
        ),
      );
    } else {
      final moodIcon = Constant.USER_SESSION_MOODS[widget.callDetails.moodId];
      final hasLocation = widget.callDetails.locationData.isNotEmpty;

      return Container(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  widget.callDetails.title,
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
              // --- MODIFIED: Show timer when connected ---
              Text(
                _callStatus == "Connected" ? _durationString : _callStatus,
                style: GoogleFonts.lato(fontSize: 18, color: Colors.white70),
              ),
              // --- END MODIFIED ---
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
                          widget.callDetails.locationData,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _toolbar() {
    // This method remains unchanged
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: () => _endCall(manual: true),
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

