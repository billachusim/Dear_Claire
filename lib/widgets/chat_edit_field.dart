import 'dart:io';

import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';

import '../ui/create_session/sound/custom_play_sound_widget.dart';
import '../ui/create_session/sound/play_sound_widget.dart';
import '../ui/create_session/sound/sound_widget.dart';

class ChatEditField extends StatefulWidget {
  final Function(String value, String voiceNote) onTap;

  ChatEditField({Key? key, required this.onTap}) : super(key: key);

  @override
  _ChatEditFieldState createState() => _ChatEditFieldState();
}

class _ChatEditFieldState extends State<ChatEditField> {
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;
  User? currentUser = FirebaseAuth.instance.currentUser;

  //initialize the audio record file that stores user audio record. null by default
  File? _recordFile;

  Future<String> uploadCommentAudio(File file) async {
    firebase_storage.UploadTask uploadTask;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String timeStamp = dateFormat.format(DateTime.now());
    String filename = currentUser!.uid.toString();
    // Create a Reference to the file
    firebase_storage.Reference ref =
    firebase_storage.FirebaseStorage.instance.ref().child("audio/" + filename + timeStamp);

    // final metadata = firebase_storage.SettableMetadata(
    //    contentType: 'audio/wav',
    //     customMetadata: {'picked-file-path': file.path});
    uploadTask = ref.putFile(File(file.path));
    var audioUrl = await (await uploadTask).ref.getDownloadURL();
    print("The audio url is $audioUrl");
    return audioUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: _recordFile != null,
                child: Container(
                  alignment: Alignment.topLeft,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        CustomPlaySoundWidget(
                          filePath: _recordFile?.path,
                        ),
                        IconButton(
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 24.r,
                            ),
                            onPressed: () => setState(() {
                                  _recordFile = null;
                                }))
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child: SvgPicture.asset(
                        AppImages.appEmoji,
                        color: Colors.pink,
                        height: 24,
                      )),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: Icon(
                      Icons.linked_camera_rounded,
                      size: 30,
                      color: Colors.pink,
                    ),
                  ),
                  Flexible(
                    child: new ConstrainedBox(
                      constraints: new BoxConstraints(
                        minWidth: getDeviceWidth(context),
                        maxWidth: getDeviceWidth(context),
                        minHeight: 20.0,
                        maxHeight: 135.0,
                      ),
                      child: new Scrollbar(
                        child: Container(
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Pallet.colorWhite,
                          ),
                          child: new TextField(
                            cursorColor: Pallet.colorSplashScreen,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            controller: _controller,
                            onChanged: (text) {
                              if (text.length >= 1) {
                                setState(() {
                                  isTyping = true;
                                });
                              } else {
                                setState(() {
                                  isTyping = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.only(left: 13.0, right: 13.0),
                              hintText: "Positive vibes only...",
                              hintStyle: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  isTyping == true
                      ? FloatingActionButton(
                          onPressed: () {
                            if (_controller.text.isNotEmpty)
                              widget.onTap(_controller.text, _recordFile.toString());
                            _controller.text = '';
                          },
                          mini: true,
                          backgroundColor: Pallet.colorSplashScreen,
                          child: SvgPicture.asset(
                            AppImages.appSend,
                            height: 25,
                          ))
                      : FloatingActionButton(
                          onPressed: () async {
                            var data = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SoundRecorderWidget(
                                          onRecordComplete: (recordFile) {},
                                        )));
                            if (data != null) {
                              _recordFile = data;
                              setState(() {});
                            }
                          },
                          mini: true,
                          backgroundColor: Pallet.colorPrimary,
                          child: Icon(
                            Icons.mic_rounded,
                            size: 35,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recordFileWidget() {
    return Container(
      height: 60.h,
      width: 60.w,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
              child: IconButton(
                  icon: Icon(Icons.play_circle_fill_outlined,
                      color: Colors.white, size: 40.r),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: PlaySoundWidget(
                            filePath: _recordFile?.path,
                          ),
                        );
                      },
                    );
                  })),
          Positioned(
              right: -5,
              top: -9,
              child: IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 24.r,
                  ),
                  onPressed: () => setState(() {
                        _recordFile = null;
                      })))
        ],
      ),
    );
  }
}
