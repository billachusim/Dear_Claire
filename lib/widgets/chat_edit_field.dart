import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:full_screen_image/full_screen_image.dart';
import 'package:intl/intl.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import '../services/firebase_services.dart';
import '../ui/create_session/sound/custom_play_sound_widget.dart';
import '../ui/create_session/sound/play_sound_widget.dart';
import '../ui/create_session/sound/sound_widget.dart';
import '../ui/featured/model/comment_session_model.dart';
import '../ui/featured/model/session.dart';
import '../utils/constant.dart';

class ChatEditField extends StatefulWidget {
  final Function(String value, String voiceNote) onTap;

  ChatEditField({Key? key, required this.onTap}) : super(key: key);

  @override
  _ChatEditFieldState createState() => _ChatEditFieldState();
}

class _ChatEditFieldState extends State<ChatEditField> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();

  bool isTyping = false;
  User? currentUser = FirebaseAuth.instance.currentUser;

  //initialize the audio record file that stores user audio record. null by default
  File? _recordFile;

  //initialize the image list stores user selected images.
  List<Asset> imageList = <Asset>[];

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

  Future<void> loadAssets() async {
    String error = 'No Error Detected';
    try {
      imageList = await MultiImagePicker.pickImages(
        maxImages: 2,
        enableCamera: true,
        selectedAssets: imageList,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "To Dear Claire",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() {
      imageList;
    });
  }

  void _sendComment(Session session) async {
    if (!await firebaseServices.isUserSignIn(context)) return;

    final _userModel = await firebaseServices.getUserInfo();

    List<String> imageDownloadUrls = <String>[];
    for (var image in imageList) {
      imageDownloadUrls.add(await _firebaseServices.uploadImage(image));
    }
    final _commentModel = CommentSessionModel(
        alterEgoId: _userModel.alterEgoId,
        audioUrl: _recordFile.toString(),
        commentId: '',
        flagged: false,
        imageUrls: imageDownloadUrls,
        isUserAdmin: false,
        message: _controller.text,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname:  _userModel.nickname);

    firebaseServices.addComment(
        title: session.title ?? '',
        docId: session.sessionId!,
        sender: _userModel.userType == 'ADMIN' ? 'Claire' :
        _userModel.userType == 'SUPER_ADMIN' ? 'Claire' :
        _userModel.nickname!,
        map: _commentModel.toJson());
    updateSessionTimeLastActivity(session);
    incrementAdviseCount();
    incrementTotalLoveCount();
  }


  /// Increase advise counter when user creates new comment.

  Future<void> incrementAdviseCount() async {
    FirebaseFirestore.instance
        .collection("user_comment_counters")
        .doc(currentUser?.uid)
        .set({
      "numberOfComments": FieldValue.increment(1),
    },
      SetOptions(merge: true),

    );
    logger.d('Successfully increased advise count');
    print('Advise Count is: $FieldValue');

  }

  /// Increase total love count when user creates new session or comment.

  Future<void> incrementTotalLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'totalLoveCount': FieldValue.increment(10),
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully increased total love count');
    print('Session Count is: $FieldValue');
  }


  /// Update a session's timeLastActivity when new comment is made.

  Future<void> updateSessionTimeLastActivity(Session session) async {
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId)
        .update({
      'timeLastActivity': FieldValue.serverTimestamp(),
    },
    );
    logger.d('Successfully increased advise count');
    print('Session Count is: $FieldValue');

  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

            Visibility(
              visible: imageList.isNotEmpty,
              child: Container(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    children: [
                      Visibility(
                          visible: imageList.isNotEmpty,
                          child: FullScreenWidget(
                            child: CachedNetworkImage(
                                height: 75,
                                width: 75,
                                imageUrl: imageList.isNotEmpty
                                    ? imageList.first.toString()
                                    : '',
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/brown_boy_mask.png",
                                  width: 48,
                                  height: 48,
                                ) //Icon(Icons.error),
                            ),
                          )),

                      SizedBox(width: 5,),

                      Visibility(
                          visible: imageList.isNotEmpty,
                          child: FullScreenWidget(
                            child: CachedNetworkImage(
                                height: 75,
                                width: 75,
                                imageUrl: imageList.isNotEmpty
                                    ? imageList.last.toString()
                                    : '',
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/brown_boy_mask.png",
                                  width: 48,
                                  height: 48,
                                ) //Icon(Icons.error),
                            ),
                          )),
                      IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 24.r,
                          ),
                          onPressed: () => setState(() {
                            imageList = [];
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
                  onPressed: loadAssets,
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
                            if (text.length >= 2) {
                              setState(() {
                                isTyping = true;
                              });
                            } else {
                              isTyping = false;
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
                  heroTag: "Write",
                        onPressed: () {
                          if (_controller.text.isNotEmpty)
                            widget.onTap(_controller.text, _recordFile.toString());
                          _controller.text = '';
                          setState(() {
                            _recordFile = null;
                            imageList = [];
                          });
                        },
                        mini: true,
                        backgroundColor: Pallet.colorSplashScreen,
                        child: SvgPicture.asset(
                          AppImages.appSend,
                          height: 25,
                        ))
                    : FloatingActionButton(
                  heroTag: "Record",
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
    );
  }
}
