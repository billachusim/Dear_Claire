import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/firebase_services.dart'; // Assuming this exists and works
import '../../ui/create_session/session_model.dart';
import '../../utils/color.dart';

class AutoDiaryRecorderPage extends StatefulWidget {
  const AutoDiaryRecorderPage({Key? key}) : super(key: key);

  @override
  _AutoDiaryRecorderPageState createState() => _AutoDiaryRecorderPageState();
}

class _AutoDiaryRecorderPageState extends State<AutoDiaryRecorderPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _statusText = 'Initializing...';
  Timer? _recordingTimer;
  File? _recordedFile;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!(await Permission.microphone.request().isGranted)) {
      setState(() => _statusText = 'Microphone permission denied.');
      return;
    }

    try {
      await _recorder.openRecorder();
      Directory tempDir = await getTemporaryDirectory();
      String path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      _recordedFile = File(path);

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _statusText = "Recording... don't worry, I'm listening.";
      });

      // Set a timer for 5 minutes (300 seconds)
      _recordingTimer = Timer(const Duration(seconds: 300), () {
        if (_isRecording) {
          _stopAndSave();
        }
      });
    } catch (e) {
      setState(() => _statusText = 'Failed to start recording: $e');
    }
  }

  Future<void> _stopAndSave() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();

    try {
      final path = await _recorder.stopRecorder();
      await _recorder.closeRecorder();

      setState(() {
        _isRecording = false;
        _statusText = 'Saving your thoughts...';
      });

      if (path != null && _recordedFile != null) {
        // Here you would call your upload and session creation logic
        // For now, let's simulate it and pop the screen
        print('Recording stopped. File at: $path');
        await _createAutoDiarySession(_recordedFile!);
        _statusText = 'Saved successfully!';

        // Show success and close the screen
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-diary entry saved!')));
        Navigator.of(context).pop();

      } else {
        throw Exception("Recorder did not return a file path.");
      }
    } catch (e) {
      setState(() => _statusText = 'Error saving: $e');
    }
  }

  Future<void> _createAutoDiarySession(File audioFile) async {
    // This logic is adapted from your original `saveAndSendAutoDiary`
    // but now it correctly handles the audio file.
    final FirebaseServices firebaseServices = FirebaseServices();
    try {
      final userModel = await firebaseServices.getUserInfo();
      String? audioUrl = await firebaseServices.uploadAudioFile(audioFile, userModel.userId!);      if (audioUrl == null) throw Exception("Audio upload failed.");
      if (audioUrl == null) throw Exception("Audio upload failed.");
      CreateSessionModel sessionObject = CreateSessionModel(
        userAvatarUrl: userModel.avatarUrl,
        userNickname: userModel.nickname,
        title: "Auto Diary Entry",
        private: false,
        repliesEnabled: true,
        message: "Here's one of my thoughts from today.",
        audioUrl: audioUrl, // CRITICAL: Use the uploaded audio URL
        colorHex: "#6200EA",
        userId: userModel.userId,
        moodId: 0,
        location: '#AutoDiary',
        timeLastActivity: Timestamp.now(),
      );

      // --- FIX IS HERE ---
      bool sessionId = await firebaseServices.createSession(session: sessionObject);
      if (sessionId == null) {
        throw Exception("Session creation failed to return an ID.");
      }

      // Pass the session object back into subscribeToYourSession, which needs it for its ID
      sessionObject.sessionId = sessionId as String?;

      // FIX 3 (provide the two arguments it expects)
      await firebaseServices.subscribeToYourSession(userModel.nickname.toString(), sessionObject);


    } catch (e) {
      print("Failed to create auto diary session: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorPrimary.withOpacity(0.9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording)
              Icon(Icons.mic, color: Colors.white, size: 80),
            SizedBox(height: 20),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            SizedBox(height: 60),
            if (_isRecording)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(24),
                ),
                onPressed: _stopAndSave,
                child: Icon(Icons.stop, size: 40),
              ),
          ],
        ),
      ),
    );
  }
}
