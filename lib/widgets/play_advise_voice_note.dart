import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlayAdviseVoiceNote extends StatefulWidget {
  final String? filePath;
  PlayAdviseVoiceNote({Key? key, this.filePath})
      : super(key: key);

  @override
  _PlayAdviseVoiceNoteState createState() => _PlayAdviseVoiceNoteState();
}

class _PlayAdviseVoiceNoteState extends State<PlayAdviseVoiceNote> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    // Reset position when playback completes
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              if (widget.filePath != null && widget.filePath!.isNotEmpty) {
                if (_isPlaying) {
                  _audioPlayer.pause();
                } else if (_isPaused) {
                  _audioPlayer.resume();
                } else {
                  _audioPlayer.play(UrlSource(widget.filePath!));
                }
              }
            },
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_arrow_rounded,
              size: 40.r,
              color: Colors.pink,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                  activeColor: Colors.pink,
                  inactiveColor: Colors.white70,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(color: Colors.pink, fontSize: 12.sp),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [minutes, seconds].map(twoDigits).join(':');
  }
}
