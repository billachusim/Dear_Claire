import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:dear_claire/utils/color.dart';

class PlaySoundWidget extends StatefulWidget {
  final String? filePath;
  final ValueChanged<String>? onRecordComplete;

  const PlaySoundWidget({super.key, this.filePath, this.onRecordComplete});

  @override
  _PlaySoundWidgetState createState() => _PlaySoundWidgetState();
}

class _PlaySoundWidgetState extends State<PlaySoundWidget> {
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onPlayButtonPressed() {
    if (widget.filePath != null) {
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play(DeviceFileSource(widget.filePath!));
      }
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Pallet.colorWhite,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.red,
                  size: 30,
                ),
                onPressed: _onPlayButtonPressed,
              ),
              const SizedBox(width: 5),
              Slider(
                min: 0,
                max: _duration.inSeconds.toDouble(),
                value: _position.inSeconds.toDouble(),
                onChanged: (value) async {
                  final position = Duration(seconds: value.toInt());
                  await _audioPlayer.seek(position);
                  await _audioPlayer.resume();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
