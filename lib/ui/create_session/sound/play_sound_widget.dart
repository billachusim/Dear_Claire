import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wave/config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wave/wave.dart';
import 'package:dear_claire/utils/color.dart';

class PlaySoundWidget extends StatefulWidget {
  final String? filePath;
  ValueChanged<String>? onRecordComplete;
  PlaySoundWidget({Key? key, this.filePath, this.onRecordComplete})
      : super(key: key);

  @override
  _PlaySoundWidgetState createState() => _PlaySoundWidgetState();
}

class _PlaySoundWidgetState extends State<PlaySoundWidget> {
  late bool _isPlaying;
  late bool _isUploading;
  late bool _isRecorded;
  late bool _isRecording;

  late AudioPlayer _audioPlayer;

  late FlutterAudioRecorder2 _audioRecorder;

  var _time = 0;
  var _duration = 0;
  @override
  void initState() {
    super.initState();
    _isPlaying = false;
    _isUploading = false;
    _isRecorded = false;
    _isRecording = false;

    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 70,
        child: Column(children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                child: Icon(Icons.close, size: 18.r, color: Colors.white,),
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.red),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.red,
                  size: 35.r,
                ),
                onPressed: _onPlayButtonPressed,
              ),
              SizedBox(width: 5.w),
              Slider(
                min: 0,
                max: _time.toDouble(),
                value: _duration.toDouble(),
                onChanged: (value) {
                  setState(() {
                    print("on change value is $value");
                    _audioPlayer.pause();
                    _duration = value.toInt();
                    _audioPlayer.seek(Duration(seconds: _duration));
                    _audioPlayer.resume();
                    // _audioPlayer.seek(Duration(milliseconds: _duration));
                  });
                },
              ),
            ],
          )
        ]));
  }

  void _onPlayButtonPressed() {
    if (!_isPlaying) {
      _isPlaying = true;

      print("selected file path is: ${widget.filePath!}");
      _audioPlayer.play(
        widget.filePath!,
        isLocal: true,
      );
      _audioPlayer.onDurationChanged.listen((Duration d) {
        print('Max duration: $d');
        setState(() => _time = d.inSeconds);
      });
      _audioPlayer.onAudioPositionChanged.listen((Duration p) {
        print('Current position: $p');
        setState(() => _duration = p.inSeconds);
      });
      _audioPlayer.onPlayerCompletion.listen((duration) {
        setState(() {
          _isPlaying = false;
        });
      });
    } else {
      _audioPlayer.pause();
      _isPlaying = false;
    }
    setState(() {});
  }

  Future<void> _startRecording() async {
    final bool? hasRecordingPermission =
        await FlutterAudioRecorder2.hasPermissions;

    if (hasRecordingPermission ?? false) {
      Directory directory = await getApplicationDocumentsDirectory();
      String filepath = directory.path +
          '/' +
          DateTime.now().millisecondsSinceEpoch.toString() +
          '.aac';
      _audioRecorder =
          FlutterAudioRecorder2(filepath, audioFormat: AudioFormat.AAC);
      await _audioRecorder.initialized;
      _audioRecorder.start();
      widget.onRecordComplete!(filepath);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Center(child: Text('Please enable recording permission'))));
    }
  }
}
