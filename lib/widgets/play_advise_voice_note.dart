
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dear_claire/utils/color.dart';

class PlayAdviseVoiceNote extends StatefulWidget {
  final String? filePath;
  PlayAdviseVoiceNote({Key? key, this.filePath})
      : super(key: key);

  @override
  _PlayAdviseVoiceNoteState createState() => _PlayAdviseVoiceNoteState();
}

class _PlayAdviseVoiceNoteState extends State<PlayAdviseVoiceNote> {
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
                  color: Pallet.colorSecondary,
                  size: 40.r,
                ),
                onPressed: _onPlayButtonPressed,
              ),
              Slider(
                thumbColor: Pallet.colorSecondary,
                inactiveColor: Pallet.colorPrimary,
                activeColor: Pallet.colorSecondary,
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
                  });
                },
              ),
            ],
          )
        ]));
  }

  void _onPlayButtonPressed() async {
    if (!_isPlaying) {
      _isPlaying = true;

      print("selected file path is: ${widget.filePath!}");

      // Set the source of the audio based on the file path (local or remote)
      await _audioPlayer.setSourceUrl(widget.filePath!);

      // Start playing the audio
      await _audioPlayer.resume();

      // Update duration and position listeners
      _audioPlayer.onDurationChanged.listen((Duration d) {
        print('Max duration: $d');
        setState(() => _time = d.inSeconds);
      });

      _audioPlayer.onPositionChanged.listen((Duration p) {
        print('Current position: $p');
        setState(() => _duration = p.inSeconds);
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });
    } else {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
    setState(() {});
  }

}
