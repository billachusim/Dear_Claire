import 'package:clairediary/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;
  // --- 1. ADD THE NEW CALLBACKS ---
  final VoidCallback? onStart;
  final VoidCallback? onCancel;

  const AudioRecorder({
    Key? key,
    required this.onStop,
    // --- 2. INITIALIZE THEM IN THE CONSTRUCTOR ---
    this.onStart,
    this.onCancel,
  }) : super(key: key);

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
    try {
      await _audioRecorder!.openRecorder();
      if (mounted) {
        setState(() {
        _isRecorderInitialized = true;
      });
      }
    } catch (e) {
      print('Failed to start audio recorder: $e');
    }
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

      // --- 3. CALL onStart() WHEN RECORDING BEGINS ---
      widget.onStart?.call();

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

  // --- 4. ADD THE NEW _cancel() METHOD ---
  Future<void> _cancel() async {
    if (!_isRecorderInitialized) return;
    try {
      await _audioRecorder!.stopRecorder(); // Stop without returning the path
      // Call the onCancel callback to reset the UI in the parent
      widget.onCancel?.call();
    } catch (e) {
      print('Error cancelling recorder: $e');
    }
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 5. UPDATE THE UI TO BE MORE INTUITIVE ---
    if (_isRecording) {
      // Show Stop and Cancel buttons when recording
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _stop,
            color: Colors.red.shade400,
            iconSize: 30,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
            color: Pallet.colorWhite,
            iconSize: 22,
          ),
        ],
      );
    } else {
      // Show the initial mic button
      return GestureDetector(
        onTap: () {
          if (!_isRecorderInitialized) return;
          _start();
        },
        child: Container(
          height: 40,
          width: 40,
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Pallet.colorWhite,
              borderRadius: BorderRadius.circular(100)),
          child: Icon(
            Icons.mic,
            color: Pallet.colorPrimary,
            size: 20,
          ),
        ),
      );
    }
  }
}
