
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop}) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  bool _isRecorderInitialized = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print("Microphone permission not granted");
      return;
    }
    await _audioRecorder!.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  @override
  void dispose() {
    if (_audioRecorder != null) {
      _audioRecorder!.closeRecorder();
      _audioRecorder = null;
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (!_isRecorderInitialized) return;
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      final path = '$appDocPath/${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder!.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recorder: $e');
    }
  }

  Future<void> _stop() async {
    if (!_isRecorderInitialized) return;
    try {
      final path = await _audioRecorder!.stopRecorder();
      if (path != null) {
        final file = File(path);
        widget.onStop(file.path);
      }
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping recorder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isRecorderInitialized) return;
        if (_isRecording) {
          _stop();
        } else {
          _start();
        }
      },
      child: Icon(
        _isRecording ? Icons.stop : Icons.mic,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
