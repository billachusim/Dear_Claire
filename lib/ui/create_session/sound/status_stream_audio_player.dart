
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusSoundPlayWidget extends StatefulWidget {
  final String? filePath;
  StatusSoundPlayWidget({Key? key, this.filePath})
      : super(key: key);

  @override
  _StatusSoundPlayWidgetState createState() => _StatusSoundPlayWidgetState();
}

class _StatusSoundPlayWidgetState extends State<StatusSoundPlayWidget> {
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
    return IconButton(
      icon: Icon(
        _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
        color: Colors.white,
        size: 37.r,
      ),
      onPressed: _onPlayButtonPressed,
    );
  }

  void _onPlayButtonPressed() {
    if (!_isPlaying) {
      _isPlaying = true;

      print("selected file path is: ${widget.filePath!}");
      _audioPlayer.play(
        widget.filePath!,
        isLocal: false,
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
