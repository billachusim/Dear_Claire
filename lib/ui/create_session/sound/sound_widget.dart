import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
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

class _SoundRecorderWidgetState extends State<SoundRecorderWidget> {
  late bool _isPlaying;
  late bool _isUploading;
  late bool _isRecorded;
  late bool _isRecording;

  late AudioPlayer _audioPlayer;
  late String _filePath;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  @override
  void initState() {
    super.initState();
    _isPlaying = false;
    _isUploading = false;
    _isRecorded = false;
    _isRecording = false;

    _audioPlayer = AudioPlayer();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  _buildCard({
    Config? config,
    Color backgroundColor = Colors.transparent,
    DecorationImage? backgroundImage,
    double height = 152.0,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      child: WaveWidget(
        config: config!,
        backgroundColor: backgroundColor,
        backgroundImage: backgroundImage,
        size: Size(double.infinity, double.infinity),
        waveAmplitude: 0,
      ),
    );
  }

  late MaskFilter _blur;
  final List<MaskFilter> _blurs = [
    MaskFilter.blur(BlurStyle.normal, 10.0),
    MaskFilter.blur(BlurStyle.inner, 10.0),
    MaskFilter.blur(BlurStyle.outer, 10.0),
    MaskFilter.blur(BlurStyle.solid, 16.0),
  ];
  int _blurIndex = 0;
  MaskFilter _nextBlur() {
    if (_blurIndex == _blurs.length - 1) {
      _blurIndex = 0;
    } else {
      _blurIndex = _blurIndex + 1;
    }
    _blur = _blurs[_blurIndex];
    return _blurs[_blurIndex];
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

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
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.only(top: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 35.r),
                      onPressed: () => Navigator.pop(context),
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
                      Center(
                        child: _isRecorded
                            ? Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.cancel,
                                  color: Colors.white, size: 60.r),
                              onPressed: _onRecordAgainButtonPressed,
                            ),
                            IconButton(
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause
                                    : Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 60.r,
                              ),
                              onPressed: _onPlayButtonPressed,
                            ),
                            IconButton(
                              icon: Icon(Icons.done,
                                  color: Colors.white, size: 60.r),
                              onPressed: () {
                                Navigator.pop(context, File(_filePath));
                              },
                            ),
                          ],
                        )
                            : IconButton(
                          icon: _isRecording
                              ? Icon(Icons.pause,
                              color: Colors.white, size: 60)
                              : Icon(Icons.mic,
                              color: Colors.white, size: 60.r),
                          onPressed: _onRecordButtonPressed,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildCard(
                        height: size.height / 3,
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
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onRecordAgainButtonPressed() {
    setState(() {
      _isRecorded = false;
    });
  }

  Future<void> _onRecordButtonPressed() async {
    if (_isRecording) {
      String? path = await _recorder.stopRecorder();
      _filePath = path!;
      _isRecording = false;
      _isRecorded = true;
    } else {
      _isRecorded = false;
      _isRecording = true;
      await _startRecording();
    }
    setState(() {});
  }

  void _onPlayButtonPressed() async {
    if (!_isPlaying) {
      _isPlaying = true;

      await _audioPlayer.setSourceDeviceFile(_filePath);
      await _audioPlayer.resume();

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => _isPlaying = false);
      });
    } else {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
    setState(() {});
  }

  Future<void> _startRecording() async {
    PermissionStatus status = await Permission.microphone.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Microphone permission required")),
      );
      return;
    }

    Directory dir = await getApplicationDocumentsDirectory();
    String path =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac";

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );

    _filePath = path;
    setState(() {});
  }
}
