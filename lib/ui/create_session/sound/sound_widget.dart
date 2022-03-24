import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wave/config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wave/wave.dart';
import 'package:dear_claire/utils/color.dart';

class SoundRecorderWidget extends StatefulWidget {
final ValueChanged<File> onRecordComplete;
  const SoundRecorderWidget({
    Key? key,required this.onRecordComplete

  }) : super(key: key);
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

  late FlutterAudioRecorder2 _audioRecorder;

  //await firebaseStorage
  //         .ref('upload-voice-firebase')
  //         .child(
  //         _filePath.substring(_filePath.lastIndexOf('/'), _filePath.length))
  //         .putFile(File(_filePath));

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
void dispose(){
super.dispose();
_audioPlayer.dispose();
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
    Size size=MediaQuery.of(context).size;
    return SafeArea(
      child: Material(
        child: Container(
          height: size.height,
          color: Pallet.colorPrimary,
          alignment: Alignment.bottomCenter,
          child:Column(
            mainAxisSize:MainAxisSize.max,
            crossAxisAlignment:CrossAxisAlignment.stretch,
            children: [
              Container(
                margin:EdgeInsets.all(20),
                padding:EdgeInsets.only(top:10.h),
                child: Row(
                  mainAxisAlignment:MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon:Icon(Icons.close, color:Colors.white, size:30.r), onPressed:(){
                      Navigator.pop(context);
                    }),

                    IconButton(icon:Icon(Icons.done, color:Colors.white,size:30.r), onPressed:(){
                      _audioPlayer.stop();
                      print("filepath is : $_filePath");
                    Navigator.pop(context,File(_filePath));
                    }),
                  ],
                ),
              ),

             Expanded(
               child: Align(
                 alignment: Alignment.bottomCenter,
                 child: Column(
                   mainAxisSize:MainAxisSize.min,
                   children: [
                     Center(
                       child:
                       // _isUploading
                       //     ? Column(
                       //   mainAxisAlignment: MainAxisAlignment.center,
                       //   crossAxisAlignment: CrossAxisAlignment.center,
                       //   children: [
                       //     Padding(
                       //         padding: const EdgeInsets.symmetric(horizontal: 20),
                       //         child: LinearProgressIndicator()),
                       //     Text('Uplaoding to Firebase'),
                       //   ],
                       // )
                       //     :
                       // Column(
                       //   children: [
                       //
                       //   ],
                       // )
                       _isRecorded
                           ? Row(
                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           IconButton(
                             icon: Icon(Icons.replay, color:Colors.white,size: 50.r,),
                             onPressed: _onRecordAgainButtonPressed,
                           ),
                           IconButton(
                             icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color:Colors.white,size: 50.r,),
                             onPressed: _onPlayButtonPressed,
                           ),
                           IconButton(icon:Icon(Icons.done, color:Colors.white,size:50.r), onPressed:(){
                             
                             Navigator.pop(context,File(_filePath));
                           }),
                         ],
                       )
                           : IconButton(
                         icon: _isRecording
                             ? Icon(Icons.pause, color:Colors.white)
                             : Icon(Icons.fiber_manual_record, color:Colors.white, size: 50.r,),
                         onPressed: _onRecordButtonPressed,
                       ),
                     ),
                     SizedBox(height: 20.h,),
                     _buildCard(
                       height: size.height/3,
                       backgroundColor: Pallet.colorPrimary,
                       config: CustomConfig(
                         gradients: [
                           [Colors.red, Color(0xEEF44336)],
                           [Colors.red[800]!, Color(0x77E57373)],
                           [Color(0xFFFF5252), Color(0x66FF9800)],
                           [Color(0xFFFF5252), Color(0x55FFEB3B)]
                         ],
                         durations: [35000, 19440, 10800, 6000],
                         heightPercentages: [0.10, 0.23, 0.25, 0.30],
                         gradientBegin: Alignment.bottomLeft,
                         gradientEnd: Alignment.topRight,
                       ),
                     ),
                   ],
                 )
               )
             )

            ],
          )
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
      _audioRecorder.stop();
      _isRecording = false;
      _isRecorded = true;
    } else {
      _isRecorded = false;
      _isRecording = true;

      await _startRecording();
    }
    setState(() {});
  }

  void _onPlayButtonPressed() {
    if (!_isPlaying) {
      _isPlaying = true;

      _audioPlayer.play(_filePath, isLocal: true);
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
      _filePath = filepath;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Center(child: Text('Please enable recording permission'))));
    }
  }
}