import 'package:audioplayers/audioplayers.dart';
import 'package:clairediary/ui/featured/widget/audio_status_playing_widget.dart';
import 'package:clairediary/ui/featured/widget/status_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../featured/model/session.dart';

class StatusSoundPlayWidget extends StatefulWidget {
  final Session element;
  StatusSoundPlayWidget({Key? key, required this.element}) : super(key: key);

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
    return Container(
      width: 60,
      height: 60,
      margin: EdgeInsets.all(2),
      child: Stack(children: [
        _isPlaying
            ? AudioStatusPlaying(element: widget.element)
            : StatusStreamWidget(element: widget.element),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () async {
              if (!_isPlaying) {
                _isPlaying = true;

                print("selected file path is: ${widget.element.audioUrl!}");

                // Set the source to a remote URL (for non-local files)
                await _audioPlayer.setSourceUrl(widget.element.audioUrl!);

                // Start playing the audio
                await _audioPlayer.resume();

                // Listen for duration changes
                _audioPlayer.onDurationChanged.listen((Duration d) {
                  print('Max duration: $d');
                  setState(() => _time = d.inSeconds);
                });

                // Listen for position changes (replaces onAudioPositionChanged)
                _audioPlayer.onPositionChanged.listen((Duration p) {
                  print('Current position: $p');
                  setState(() => _duration = p.inSeconds);
                });

                // Listen for audio completion (replaces onPlayerCompletion)
                _audioPlayer.onPlayerComplete.listen((event) {
                  setState(() {
                    _isPlaying = false;
                  });
                });
              } else {
                // Pause if already playing
                await _audioPlayer.pause();
                _isPlaying = false;
              }
              setState(() {});
            },
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
              color: Colors.grey,
              size: 26.r,
            ),
          ),
        )
      ]),
    );
  }
}
