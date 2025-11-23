import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;import 'package:path_provider/path_provider.dart';
import 'package:wave/config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wave/wave.dart';
import 'package:clairediary/utils/color.dart';
import 'package:permission_handler/permission_handler.dart';

class SoundRecorderWidget extends StatefulWidget {
  final ValueChanged<File> onRecordComplete;
  const SoundRecorderWidget({Key? key, required this.onRecordComplete})
      : super(key: key);

  @override
  _SoundRecorderWidgetState createState() => _SoundRecorderWidgetState();
}

class _SoundRecorderWidgetState extends State<SoundRecorderWidget> with SingleTickerProviderStateMixin {
  late bool _isPlaying;
  late bool _isRecorded;
  late bool _isRecording;

  late AudioPlayer _audioPlayer;
  late String _filePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  Timer? _timer;
  int _recordDuration = 0;

  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isPlaying = false;
    _isRecorded = false;
    _isRecording = false;
    _audioPlayer = AudioPlayer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeRecorder();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _playbackDuration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _playbackPosition = newPosition);
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _playbackPosition = Duration.zero);
    });

    _startRecording();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _formatPlaybackDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [minutes, seconds].map(twoDigits).join(':');
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Material(
        color: Pallet.colorPrimary,
        child: Stack( // *** THE FIX IS HERE: Use a Stack for layering ***
          children: [
            // Layer 1: The animated wave at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer( // Keep IgnorePointer as a safeguard
                child: WaveWidget(
                  size: Size(double.infinity, size.height / 3.5),
                  waveAmplitude: _isRecording || _isPlaying ? 15 : 0,
                  backgroundColor: Pallet.colorPrimary,
                  config: CustomConfig(
                    gradients: [
                      [Colors.red, Color(0xEE6EBF1D)],
                      [Colors.red[800]!, Color(0x77330CBF)],
                      [Color(0xFFFF5252), Color(0x66500D8B)],
                      [Color(0xFFB82727), Color(0x559A0C55)]
                    ],
                    durations: [35000, 19440, 10800, 6000],
                    heightPercentages: [0.10, 0.23, 0.25, 0.30],
                    gradientBegin: Alignment.bottomLeft,
                    gradientEnd: Alignment.topRight,
                  ),
                ),
              ),
            ),

            // Layer 2: All the UI controls on top of the wave
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 35.r),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRecording)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            "Recording...",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 24.sp),
                          ),
                        ),
                      SizedBox(height: 10.h),
                      Text(
                        _isRecorded
                            ? _formatPlaybackDuration(_playbackPosition)
                            : _formatDuration(_recordDuration),
                        style: TextStyle(color: Colors.white, fontSize: 60.sp, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 60.h), // Adjust bottom padding
                  child: Column(
                    children: [
                      if (_isRecorded) _buildPlaybackControls(),
                      if (_isRecorded) SizedBox(height: 20.h),
                      _isRecorded
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _controlButton(icon: Icons.replay, onPressed: _onRecordAgainButtonPressed),
                          _controlButton(
                              icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill_rounded,
                              onPressed: _onPlayButtonPressed,
                              size: 70.r
                          ),
                          _controlButton(icon: Icons.done, onPressed: () => Navigator.pop(context, File(_filePath))),
                        ],
                      )
                          : _controlButton(
                          icon: Icons.stop,
                          onPressed: _onRecordButtonPressed,
                          size: 70.r,
                          color: Colors.red.shade400
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({required IconData icon, required VoidCallback onPressed, double? size, Color? color}) {
    return IconButton(
      icon: Icon(icon, color: color ?? Colors.white, size: size ?? 60.r),
      onPressed: onPressed,
    );
  }

  Widget _buildPlaybackControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Slider(
            min: 0,
            max: _playbackDuration.inSeconds.toDouble(),
            value: _playbackPosition.inSeconds.toDouble().clamp(0.0, _playbackDuration.inSeconds.toDouble()),
            onChanged: (value) async {
              await _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatPlaybackDuration(_playbackPosition), style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              Text(_formatPlaybackDuration(_playbackDuration), style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
            ],
          ),
        ],
      ),
    );
  }

  void _onRecordAgainButtonPressed() {
    setState(() {
      _isRecorded = false;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
    });
    _startRecording();
  }

  Future<void> _onRecordButtonPressed() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      _stopTimer();
      _animationController.stop();
      if (path != null) {
        _filePath = path;
        await _audioPlayer.setSourceDeviceFile(_filePath);
        setState(() {
          _isRecording = false;
          _isRecorded = true;
        });
      }
    }
  }

  void _onPlayButtonPressed() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else if (_audioPlayer.state == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.play(DeviceFileSource(_filePath));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Microphone permission required")),
      );
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }

    if (mounted) {
      setState(() {
        _isRecorded = false;
        _isRecording = true;
      });
    }

    _startTimer();
    _animationController.repeat(reverse: true);

    Directory dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac";

    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
    _filePath = path;
  }
}
