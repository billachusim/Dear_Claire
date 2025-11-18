import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:clairediary/widgets/follow_button.dart';
import 'package:clairediary/widgets/metoo_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/firebase_services.dart';
import '../../../services/native_gallery_saver.dart';
import '../../../services/user_model.dart';
import '../../../utils/strings.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/toast.dart';
import '../../create_session/sound/custom_play_sound_widget.dart';
import '../../routes/page_router_animation.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class PostDetailsWidget extends StatefulWidget {
  PostDetailsWidget({Key? key, required this.sessionId}) : super(key: key);
  String? sessionId;

  @override
  _PostDetailsWidgetState createState() => _PostDetailsWidgetState();
}

class _PostDetailsWidgetState extends State<PostDetailsWidget> {
  final screenshotController = ScreenshotController();
  TextEditingController editSessionController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;

  bool? isFeatured;
  bool? isArchived;

  late String visitedUsersID;
  late String visitedEgoName;

  //initialize the audio record file that stores user audio record. null by default
  String? recordFile;
  Session? theSession;

  bool? isFlagged;

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Screenshot(
      controller: screenshotController,
      child: Material(
        child: SafeArea(
          child: StreamBuilder(
              stream: firebaseServices.getSingleDocument(id: widget.sessionId),
              builder: (context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
                if (snaps.hasData) {
                  final _session = Session.fromJson(snaps.data!.data()!);
                  theSession = _session;
                  final Color backgroundColor = HexColor.fromHex(_session.colorHex!);
                  final Color textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                  final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 7),
                    decoration: BoxDecoration(
                        color: backgroundColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                visitedUsersID = _session.userId!;
                                visitedEgoName = _session.userNickname!;
                                String thisEgoName =
                                    _session.userNickname.toString();
                                String thisUser = _session.userId.toString();
                                UserModel user = await firebaseServices.getUserInfo();
                                if (user.userType != "REGULAR") {
                                  PageRouter.gotoWidget(
                                      VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                                      context);
                                }
                                else if (user.currentLoveCount > 500) {
                                  PageRouter.gotoWidget(
                                      VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                                      context);
                                }
                                else {
                                  showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                                }
                                print("Visited User ID::: $visitedUsersID");
                              },
                              child: CachedNetworkImage(
                                  width: 60,
                                  height: 60,
                                  imageUrl: _session.userAvatarUrl!,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                  placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                        "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                        width: 50,
                                        height: 50,
                                      ) //Icon(Icons.error),
                                  ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      visitedUsersID = _session.userId!;
                                      visitedEgoName = _session.userNickname!;
                                      String thisEgoName =
                                          _session.userNickname.toString();
                                      String thisUser =
                                          _session.userId.toString();
                                      UserModel user = await firebaseServices.getUserInfo();
                                      if (user.userType != "REGULAR") {
                                        PageRouter.gotoWidget(
                                            VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                                            context);
                                      }
                                      else if (user.currentLoveCount > 500) {
                                        PageRouter.gotoWidget(
                                            VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                                            context);
                                      }
                                      else {
                                        showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                                      }
                                      print("Visited User ID::: $visitedUsersID");
                                    },
                                    child: Text(_session.userNickname!,
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: GoogleFonts.lato(
                                            fontSize: 22.0,
                                            color: textColor,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(timeConverter(_session.timeCreated!),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: GoogleFonts.lato(
                                          fontSize: 14.0,
                                          color: textColor,
                                          fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(Mood.getMood(_session.moodId).toString(),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: GoogleFonts.lato(
                                          fontSize: 14.0,
                                          color: textColor,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(_session.location ?? '',
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: GoogleFonts.lato(
                                          fontSize: 13.0,
                                          color: secondaryTextColor,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 13,
                        ),
                        Center(
                          child: Text(_session.title!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              style: GoogleFonts.lato(
                                  fontSize: 28.0,
                                  color: textColor,
                                  fontWeight: FontWeight.w800)),
                        ),
                        SizedBox(
                          height: 13,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableLinkify(
                                onOpen: (link) async {
                                  final Uri url = Uri.parse("${link.url}");
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    throw 'Could not launch $link';
                                  }
                                },
                                linkStyle: TextStyle(color: Colors.blue),
                                text: _session.message!,
                                textAlign: TextAlign.justify,
                                style: GoogleFonts.lato(
                                    fontSize: 22.0,
                                    color: textColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 7,),

                        Container(
                          alignment: Alignment.centerLeft,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                _session.audioUrl!.isNotEmpty
                                    ? CustomPlaySoundWidget(
                                        filePath: _session.audioUrl)
                                    : SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),

                        Visibility(
                          visible: _session.imageUrls!.isNotEmpty,
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 5,
                            children: List.generate(_session.imageUrls!.length, (index) {
                              String image = _session.imageUrls![index].toString();
                              return Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      PageRouter.gotoWidget(CustomImageWidget(imageUrl: image), context);
                                    },
                                    child: Container(
                                      child: CachedNetworkImage(
                                          height: 200,
                                          width: 200,
                                          imageUrl: image,
                                          imageBuilder: (context, imageProvider) => Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(25),
                                              image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover
                                              ),
                                            ),
                                          ),
                                          placeholder: (context, url) =>
                                              Center(child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) => Image.asset(
                                            "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                            width: 48,
                                            height: 48,
                                          ) //Icon(Icons.error),
                                      ),
                                      margin: EdgeInsets.all(3),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),

                        SizedBox(
                          height: 12,
                        ),
                        Row(
                          children: [
                            MetooButton(
                              cheers: _session.meToos!.length,
                              thanks: _session.meLove!.length,
                              sorry: _session.meHiFive!.length,
                              me2: _session.meFlower!.length,
                              onReactionChanged: (reaction, index) async {
                                if (await firebaseServices
                                    .isUserSignIn(context)) {
                                  final _userModel =
                                      await firebaseServices.getUserInfo();

                                  firebaseServices.addUsersReactionToASession(
                                      context, index,
                                      session: _session,
                                    sender: _userModel.userType == 'ADMIN'? 'Claire' :
                                    _userModel.userType == 'SUPER_ADMIN'? 'Claire' :
                                    _userModel.nickname.toString(),
                                  );

                                  saveUserMe2Activity();
                                  await firebaseServices.updateSessionLastTimeActivity(_session.sessionId.toString());

                                }
                              },
                              color: textColor,
                              session: _session,
                            ),
                            new SizedBox(
                              width: 10,
                            ),
                            _session.userId == currentUser?.uid
                                ? TextButton(
                                    onPressed: () async {
                                      firebaseServices.followYourSession(
                                          context,
                                          session: _session);
                                    },
                                    child: Row(
                                      children: [
                                        Text(_session.followers!.length.toString(),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                        ),
                                        ),

                                        Icon(
                                          _session.followers!
                                                  .contains(currentUser?.uid)
                                              ? Icons.notifications_active_rounded
                                              : Icons.notifications_off_outlined,
                                          color: textColor,
                                          size: 26,
                                        ),
                                      ],
                                    ),
                                  )
                                : FollowButton(
                                    text: _session.followers!
                                            .contains(currentUser?.uid)
                                        ? 'Unfollow'
                                        : 'Follow',
                                    onPressed: () async {
                                      if (await firebaseServices.isUserSignIn(context)) {
                                        firebaseServices.followThisSession(
                                            context,
                                            session: _session);

                                        saveUserFollowActivity();
                                        await firebaseServices.updateSessionLastTimeActivity(_session.sessionId.toString());
                                      }
                                    },
                                    count: _session.followers!.length,
                                  ),

                            new Spacer(),

                            FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              future: FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(currentUser?.uid)
                                  .get(),
                              builder: (_, snapshot) {
                                if (snapshot.hasData) {
                                  var data = snapshot.data!.data();
                                  var userType = data?["userType"] ?? "0";

                                  return
                                    Visibility(
                                      visible: userType == "SUPER_ADMIN",
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_session.featured == false)
                                            modFeatureAlertDialog(context);
                                          else unfeatureAlertDialog(context);
                                        },
                                        child: Container(
                                          child: Visibility(
                                            visible: _session.repliesEnabled == true,
                                            child: Icon(
                                              _session.featured == true ? Icons.lightbulb : Icons.lightbulb_outline,
                                              color: Pallet.colorSecondary,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                }

                                return Container();
                              },
                            ),

                            new Spacer(),

                            if (_session.userId == currentUser?.uid)
                              CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 17,
                                        color: textColor,
                                      ),
                                      SizedBox(
                                        width: 2,
                                      ),
                                      Text(
                                        'EDIT',
                                        style: GoogleFonts.lato(
                                            fontSize: 14.0,
                                            color: textColor,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  onPressed: _showCardDialog),
                            new Spacer(),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_session.repliesEnabled == true)
                                  GestureDetector(
                                    onTap: () {
                                      if (_session.flagged == false)
                                        showCustomDialog(context,
                                          message: _session.flagged == true
                                              ? AppString.unflag_alert_note
                                              : AppString.flag_alert_note,
                                          onPressed: () {
                                            PageRouter.goBack(context);
                                            sendToFlagged();
                                          });
                                      else
                                        showCustomDialog(context,
                                            message: _session.flagged == false
                                                ? AppString.flag_alert_note
                                                : AppString.unflag_alert_note,
                                            onPressed: () {
                                              PageRouter.goBack(context);
                                              removeFromFlagged();
                                            });
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          _session.flagged == true
                                              ? Icons.flag
                                              : Icons.flag_outlined,
                                          color: textColor,
                                          size: 22,
                                        ),
                                        Text(
                                          'Flag',
                                          style: GoogleFonts.lato(
                                              fontSize: 15.0,
                                              color: textColor,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                new SizedBox(
                                  width: 10,
                                ),

                                FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(currentUser?.uid)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var userType = data?["userType"] ?? "0";

                                      return

                                        Visibility(
                                          visible: userType == "SUPER_ADMIN",
                                          child: Visibility(
                                            visible: _session.flagged == true,
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    if (_session.archived == false)
                                                      showCustomDialog(context,
                                                          message: _session.archived == true
                                                              ? AppString.unarchive_alert_note
                                                              : AppString.archive_alert_note,
                                                          onPressed: () {
                                                            sendToArchive();
                                                            Navigator.of(context).pop();
                                                            setState(() {});
                                                          });
                                                    else
                                                      showCustomDialog(context,
                                                          message: _session.archived == false
                                                              ? AppString.archive_alert_note
                                                              : AppString.unarchive_alert_note,
                                                          onPressed: () {
                                                            removeFromArchive();
                                                            Navigator.of(context).pop();
                                                            setState(() {});
                                                          });
                                                  },

                                                  child: Container(
                                                    child: Icon(
                                                      _session.archived == true ? Icons.archive_rounded : Icons.archive_outlined,
                                                      color: Pallet.colorSecondary,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),

                                                SizedBox(
                                                  width: 4,
                                                ),

                                                  CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.edit,
                                                            size: 17,
                                                            color: Pallet.colorSecondary,
                                                          ),
                                                          SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            'MOD',
                                                            style: GoogleFonts.lato(
                                                                fontSize: 14.0,
                                                                color: Pallet.colorSecondary,
                                                                fontWeight: FontWeight.w800),
                                                          ),
                                                        ],
                                                      ),
                                                      onPressed: _showCardDialog),
                                              ],
                                            ),
                                          ),
                                        );
                                    }

                                    return Container();
                                  },
                                ),

                                new SizedBox(
                                  width: 10,
                                ),

                                CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.share_rounded,
                                          size: 17,
                                          color: textColor,
                                        ),
                                        Text(
                                          'Share',
                                          style: GoogleFonts.lato(
                                              fontSize: 15.0,
                                              color: textColor,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                    onPressed: () async {
                                      final image =
                                          await screenshotController.capture();
                                      if (image == null) return;
                                      await saveImage(image);
                                      saveAndShare(image);
                                    }),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }
                return Container();
              }),
        ),
      ),
    );
  }

  /// Edit feature

  Future<bool?> setToFeatured() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({
      "featured": value,
    },
    );
    logger.d('Successfully changed feature');
    print('Is Featured?: $value');
    isFeatured = value;
    return value;
  }


  modFeatureAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Feature!"),
      onPressed:  () {
        setToFeatured();
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Feature This Session?"),
      content: Text(AppString.feature_alert_note),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool?> removeFromFeatured() async {
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({
      "featured": value,
    },
    );
    logger.d('Successfully changed feature');
    print('Is Featured?: $value');
    isFeatured = value;
    return value;
  }


  unfeatureAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed:  () {
        Navigator.of(context).pop();      },
    );
    Widget continueButton = TextButton(
      child: Text("Unfeature"),
      onPressed:  () {
        removeFromFeatured();
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Unfeature This Session?"),
      content: Text(AppString.unfeature_alert_note),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }



// Edit session function
  Future<void> editSession() async {
    final sessionId = widget.sessionId;
    final message = editSessionController.text;
    FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .doc(sessionId)
        .update(
      {
        "message": message,
      },
    );
    logger.d('Successfully saved edited session');
    print('Edited Session: $message');
  }

  //show up when user clicks on the FAB to edit an advise
  Future<void> _showCardDialog() async {
    editSessionController.text = theSession!.message.toString();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            backgroundColor: isDarkMode ? Pallet.colorSecondary : Pallet.colorWhite,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            title: Container(
              child: Text(AppString.edit_session_dialog_header,
                  textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack),
              ),
            ),
            content: SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: editSessionController,
                        minLines: 8,
                        maxLines: 2000,
                        style: TextStyle(color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack),
                        decoration: InputDecoration(
                          //border: InputBorder,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  editSession();
                  Navigator.of(context).pop();
                  setState(() {
                    editSessionController.text = "";
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> saveImage(Uint8List bytes) async {
    // Request storage permission
    await [Permission.storage].request();

    // Create a temporary file from bytes
    final tempDir = await getTemporaryDirectory();
    final time = DateTime.now()
        .toIso8601String()
        .replaceAll('.', '-')
        .replaceAll(':', '-');
    final file = File('${tempDir.path}/ClaireShot_$time.png');
    await file.writeAsBytes(bytes);

    // Save using NativeGallerySaver
    final success = await NativeGallerySaver.saveImage(file);
    if (success) {
      return file.path; // return saved file path
    } else {
      return null; // saving failed
    }
  }

  Future saveAndShare(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final image = File('${directory.path}/diary_session.png');
    image.writeAsBytesSync(bytes);
    final xFile = XFile(image.path);
    final text = '${AppString.shareHeader}\n\n${AppString.shareLink}';
    await Share.shareXFiles([xFile], text: text);
  }



  /// Archive a session

  Future<bool?> sendToArchive() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(theSession?.sessionId)
        .update({
      "archived": value,
    },
    );
    logger.d('Successfully changed archive');
    print('Is Archived?: $value');
    isArchived = value;
    return value;
  }


  Future<bool?> removeFromArchive() async {
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(theSession?.sessionId)
        .update({
      "archived": value,
    },
    );
    logger.d('Successfully changed archive');
    print('Is Archived?: $value');
    isArchived = value;
    return value;
  }


  /// Flag a session

  Future<bool?> sendToFlagged() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(theSession?.sessionId)
        .update(
      {
        "flagged": value,
      },
    );
    logger.d('Successfully flagged a session');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }


  Future<bool?> removeFromFlagged() async {
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(theSession?.sessionId)
        .update(
      {
        "flagged": value,
      },
    );
    logger.d('Successfully changed archive');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }

  /// Save user follow activity

  Future<void> saveUserFollowActivity() async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = _user.nickname.toString();
    final sessionVisitorAvatar = _user.userType != "REGULAR"
        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
        : _user.avatarUrl.toString();
    final activityMessage =
        "$sessionVisitorNickname followed $sessionOwnerNickname's session.";
    final activityType = "follow";
    final userActivityId = "";
    FirebaseFirestore.instance.collection('user_activity').add(
      {
        "activityMessage": activityMessage,
        "activityType": activityType,
        "clientAvatarUrl": sessionVisitorAvatar,
        "clientId": sessionVisitorId,
        "clientNickname": sessionVisitorNickname,
        "dateCreated": dateCreated,
        "sessionId": sessionId,
        "userActivityId": userActivityId,
        "userId": sessionOwnerId,
        "userNickname": sessionOwnerNickname,
        "userAvatarUrl": sessionOwnerAvatar,
      },
    );
    logger.d('Successfully saved your follow activity');
    print('Activity Message: $activityMessage');
  }

  /// Save user reaction activity

  Future<void> saveUserMe2Activity() async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = _user.nickname.toString();
    final sessionVisitorAvatar = _user.userType != "REGULAR"
        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
        : _user.avatarUrl.toString();
    final activityMessage =
        "$sessionVisitorNickname reacted to $sessionOwnerNickname's session.";
    final activityType = "react";
    final userActivityId = "";
    FirebaseFirestore.instance.collection('user_activity').add(
      {
        "activityMessage": activityMessage,
        "activityType": activityType,
        "clientAvatarUrl": sessionVisitorAvatar,
        "clientId": sessionVisitorId,
        "clientNickname": sessionVisitorNickname,
        "dateCreated": dateCreated,
        "sessionId": sessionId,
        "userActivityId": userActivityId,
        "userId": sessionOwnerId,
        "userNickname": sessionOwnerNickname,
        "userAvatarUrl": sessionOwnerAvatar,
      },
    );
    logger.d('Successfully saved your reaction activity');
    print('Activity Message: $activityMessage');
  }
}
