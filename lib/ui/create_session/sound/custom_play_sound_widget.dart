import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wave/config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wave/wave.dart';
import 'package:dear_claire/utils/color.dart';

class CustomPlaySoundWidget extends StatefulWidget {
  final String? filePath;
  CustomPlaySoundWidget({Key? key, this.filePath})
      : super(key: key);

  @override
  _CustomPlaySoundWidgetState createState() => _CustomPlaySoundWidgetState();
}

class _CustomPlaySoundWidgetState extends State<CustomPlaySoundWidget> {
  late bool _isPlaying;

  late AudioPlayer _audioPlayer;


  var _time = 0;
  var _duration = 0;
  @override
  void initState() {
    super.initState();
    _isPlaying = false;
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
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 40.r,
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

}
