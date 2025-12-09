import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AdminLiveCallPage extends StatefulWidget {
  final User user; // Accept the user object
  final String channelName;
  final String callDocId;

  const AdminLiveCallPage({
    Key? key,
    required this.user,
    required this.channelName,
    required this.callDocId,
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
  String? _recordingPath; // To store the path of the recorded file

  @override
  void initState() {
    super.initState();
    _setupAndJoin(); // Directly initiate the call
  }

  @override
  void dispose() {
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
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _localUserJoined = true;
              _isJoined = true;
              _callStatus = "Waiting for user...";
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
              _callStatus = "Connected";
            });
            FirebaseFirestore.instance
                .collection('live_sessions')
                .doc(widget.callDocId)
                .update({'status': 'active'});
            // --- START RECORDING ---
            _startRecording();
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
      setState(() {
        _callStatus = "Failed to connect.";
      });
    }
  }

  Future<void> _join() async {
    String token;
    try {
      // --- CRITICAL FIX: Force a refresh of the admin's auth token ---
      await widget.user.getIdToken(true);
      // ----------------------------------------------------------------

      // The admin's auth state is now guaranteed by the navigation logic.
      final callable =
      FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': widget.channelName,
        'uid': 1, // The admin will have a static UID of 1
      });
      token = result.data['token'];
      print("Successfully fetched Admin Agora token for Live Session.");
    } catch (e) {
      print("Error fetching Admin Agora token for Live Session: $e");
      setState(() {
        _callStatus = "Error: Could not get admin token.";
      });
      _endCall();
      return; // Stop execution
    }

    await _engine?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.startPreview();
    await _engine?.joinChannel(
      token: token, // Use the fetched token
      channelId: widget.channelName,
      options: const ChannelMediaOptions(),
      uid: 1, // Admin user uid, must be non-zero
    );
  }


  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _recordingPath = '${directory.path}/rec_${widget.callDocId}.m4a';

    await _engine?.startAudioRecording(AudioRecordingConfiguration(
      filePath: _recordingPath!,
      fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
      quality: AudioRecordingQualityType.audioRecordingQualityMedium,
    ));

    print("Live Session audio recording started at: $_recordingPath");
  }

  Future<void> _stopRecordingAndUpload() async {
    if (_recordingPath == null) return;

    await _engine?.stopAudioRecording();
    print("Live Session audio recording stopped.");

    File file = File(_recordingPath!);
    if (await file.exists()) {
      try {
        // Upload to Firebase Storage in a new folder
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('live_session_recordings/${widget.callDocId}.m4a');
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        // Update Firestore with the recording URL
        await FirebaseFirestore.instance
            .collection('live_sessions')
            .doc(widget.callDocId)
            .update({'recordingUrl': downloadUrl, 'status': 'ended'});
        print("Live Session recording uploaded to: $downloadUrl");

        await file.delete();
      } catch (e) {
        print("Error uploading live session recording: $e");
        await FirebaseFirestore.instance
            .collection('live_sessions')
            .doc(widget.callDocId)
            .update({'status': 'ended'});
      }
    } else {
      // If file doesn't exist, still mark the call as ended
      await FirebaseFirestore.instance
          .collection('live_sessions')
          .doc(widget.callDocId)
          .update({'status': 'ended'});
    }
    _recordingPath = null;
  }

  Future<void> _endCall() async {
    // Stop recording and handle upload first
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
              child: SizedBox(
                width: 120,
                height: 160,
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 1), // Use admin UID
                  ),
                )
                    : const Center(child: CircularProgressIndicator()),
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
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorPrimary.withOpacity(0.5), Colors.black],
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
                child: Icon(Icons.support_agent, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "Live Session",
                style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
            child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
          )
        ],
      ),
    );
  }
}
