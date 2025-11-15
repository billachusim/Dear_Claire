import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:dear_claire/utils/color.dart';

class SoundRecorderWidget extends StatefulWidget {
  final ValueChanged<File> onRecordComplete;

  const SoundRecorderWidget({super.key, required this.onRecordComplete});

  @override
  _SoundRecorderWidgetState createState() => _SoundRecorderWidgetState();
}

class _SoundRecorderWidgetState extends State<SoundRecorderWidget> {
  bool _isRecording = false;
  bool _isPaused = false;
  String? _filePath;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      setState(() {
        _isRecording = true;
        _filePath = filePath;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _filePath = path;
    });
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    setState(() => _isPaused = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Material(
        child: Container(
          height: size.height,
          color: Pallet.colorPrimary,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.done, color: Colors.white, size: 30),
                      onPressed: () {
                        if (_filePath != null) {
                          Navigator.pop(context, File(_filePath!));
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRecording)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(_isPaused ? Icons.mic : Icons.pause, color: Colors.white, size: 50),
                              onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                            ),
                            IconButton(
                              icon: const Icon(Icons.stop, color: Colors.white, size: 50),
                              onPressed: _stopRecording,
                            ),
                          ],
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.white, size: 50),
                          onPressed: _startRecording,
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
