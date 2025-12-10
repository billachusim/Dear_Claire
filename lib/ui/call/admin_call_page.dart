import 'package:agora_rtc_engine/agora_rtc_engine.dart';
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

import '../../services/firebase_services.dart';

class AdminCallPage extends StatefulWidget {
  final User user;
  final String channelName;
  final String callDocId;

  const AdminCallPage({
    Key? key,
    required this.user,
    required this.channelName,
    required this.callDocId,
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

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async { // Make async
            setState(() {
              _isJoined = true;
              _callStatus = "Waiting for user...";
            });

            // --- FIX: Fetch admin's alterEgoId and update the document ---
            try {
              final FirebaseServices firebaseServices = FirebaseServices();
              final adminUserModel = await firebaseServices.getUserWithId(id: widget.user.uid);

              await FirebaseFirestore.instance
                  .collection('companion_calls')
                  .doc(widget.callDocId)
                  .update({
                'receiverId': adminUserModel.alterEgoId, // Update receiverId with alterEgoId
              });
              print("Updated call document with admin alterEgoId: ${adminUserModel.alterEgoId}");
            } catch (e) {
              print("Error updating call document with alterEgoId: $e");
            }
            // -------------------------------------------------------------

            print("Admin (local user) has joined the channel. Starting recording...");
            _startRecording();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
              _callStatus = "Connected";
            });
            FirebaseFirestore.instance
                .collection('companion_calls')
                .doc(widget.callDocId)
                .update({'status': 'active'});
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

      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call<Map<String, dynamic>>({
        'channelName': widget.channelName,
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

    await _engine?.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine?.joinChannel(
      token: token,
      channelId: widget.channelName,
      options: const ChannelMediaOptions(),
      uid: 1, // Admin user uid, must be non-zero
    );
  }


  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    // --- FIX: Change file extension to .aac for better compatibility ---
    _recordingPath = '${directory.path}/rec_${widget.callDocId}.aac';
    // -----------------------------------------------------------------

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

  Future<void> _stopRecordingAndUpload() async {
    if (_recordingPath == null) {
      print("No recording path, likely because starting the recording failed.");
      // Ensure the call status is updated even if recording failed
      await FirebaseFirestore.instance
          .collection('companion_calls')
          .doc(widget.callDocId)
          .update({'status': 'ended'}).catchError((e) => print("Error updating status: $e"));
      return;
    }

    await _engine?.stopAudioRecording();
    print("Recording stopped.");

    File file = File(_recordingPath!);
    if (await file.exists()) {
      try {
        // --- FIX: Update storage path to use .aac ---
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('companion_recordings/${widget.callDocId}.aac');
        // ---------------------------------------------
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('companion_calls')
            .doc(widget.callDocId)
            .update({'recordingUrl': downloadUrl, 'status': 'ended'});
        print("Recording uploaded to: $downloadUrl");

        await file.delete();
      } catch (e) {
        print("Error uploading recording: $e");
        await FirebaseFirestore.instance
            .collection('companion_calls')
            .doc(widget.callDocId)
            .update({'status': 'ended'});
      }
    } else {
      print("Recording file was expected but not found at: $_recordingPath");
      await FirebaseFirestore.instance
          .collection('companion_calls')
          .doc(widget.callDocId)
          .update({'status': 'ended'});
    }
    _recordingPath = null;
  }


  Future<void> _endCall() async {
    // Stop recording and handle upload first
    await _stopRecordingAndUpload();

    // Leave Agora channel and release engine
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
      Future.delayed(const Duration(seconds: 1), () {
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
            colors: [Pallet.colorPrimary.withOpacity(0.5), Colors.black],
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
              Text(
                "Companion Call",
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
