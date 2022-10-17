import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/featured/ego_mode_session_detail.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/widgets/comments_button.dart';
import 'package:dear_claire/widgets/custom_image_widget.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firebase_services.dart';
import '../services/user_model.dart';
import '../ui/create_session/sound/custom_play_sound_widget.dart';
import '../utils/strings.dart';

class FeaturedSessionCard extends StatelessWidget {
  Session element;
  bool? isFeatured;
  bool? isArchived;

  FeaturedSessionCard({Key? key, required this.element, required this.visitedUsersID, required this.visitedEgoName}) : super(key: key);
  late String visitedUsersID;
  late String visitedEgoName;

  User? currentUser = FirebaseAuth.instance.currentUser;


  /// Edit feature

  Future<bool?> setToFeatured() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(element.sessionId)
        .update({
      "featured": value,
    },
    );
    logger.d('Successfully changed feature');
    print('Is Featured?: $value');
    isFeatured = value;
    return value;
  }


  Future<bool?> removeFromFeatured() async {
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(element.sessionId)
        .update({
      "featured": value,
    },
    );
    logger.d('Successfully changed feature');
    print('Is Featured?: $value');
    isFeatured = value;
    return value;
  }



  /// Archive a session

  Future<bool?> sendToArchive() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(element.sessionId)
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
        .doc(element.sessionId)
        .update({
      "archived": value,
    },
    );
    logger.d('Successfully changed archive');
    print('Is Archived?: $value');
    isArchived = value;
    return value;
  }


  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () => PageRouter.gotoWidget(
          EgoModeSessionDetail(featuredSessionModel: element),
          context),
      padding: EdgeInsets.zero,
      child: Container(
        height: 400,
        width: 400,
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: HexColor.fromHex(element.colorHex!)),
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
                    visitedUsersID = element.userId!;
                    visitedEgoName = element.userNickname!;
                    String thisEgoName = visitedEgoName;
                    String thisUser = visitedUsersID;

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
                      width: 48,
                      height: 48,
                      imageUrl: element.userAvatarUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                        width: 48,
                        height: 48,
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
                          visitedUsersID = element.userId!;
                          visitedEgoName = element.userNickname!;
                          String thisEgoName = visitedEgoName;
                          String thisUser = visitedUsersID;
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
                        child: Text(element.userNickname!,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 18.0,
                                color: Pallet.colorWhite,
                                fontWeight: FontWeight.w800)),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(timeConverter(element.timeCreated!),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: Colors.white70,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Text(Mood.getMood(element.moodId) ?? "${Mood.getMood(1)}",
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Pallet.colorWhite,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 3,
                      ),
                      Text(element.location ?? "",
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: Colors.white70,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 6,
            ),
            Center(
              child: Text(element.title!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.lato(
                      fontSize: 28.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 5,
            ),
            Column(
              children: [
                Text(
                  element.message!,
                  textAlign: TextAlign.start,
                  maxLines: element.imageUrls!.isNotEmpty ? 4 : 6,
                  style: GoogleFonts.lato(
                      fontSize: 25.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: 6,
                ),

                Container(
                  alignment: Alignment.topLeft,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        element.audioUrl!.isNotEmpty
                            ? CustomPlaySoundWidget(filePath: element.audioUrl)
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),

                Visibility(
                  visible: element.imageUrls!.isNotEmpty,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 5,
                    children: List.generate(element.imageUrls!.length, (index) {
                      String image = element.imageUrls![index].toString();
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              PageRouter.gotoWidget(CustomImageWidget(imageUrl: image), context);
                            },
                            child: CachedNetworkImage(
                                height: 100,
                                width: 100,
                                imageUrl: image,
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover
                                    ),
                                  ),
                                  margin: EdgeInsets.all(3),
                                ),
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                  width: 48,
                                  height: 48,
                                ) //Icon(Icons.error),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                MetooButton(
                  cheers: element.meToos!.length,
                  thanks: element.meLove!.length,
                  sorry: element.meHiFive!.length,
                  me2: element.meFlower!.length,
                  color: Pallet.colorWhite,
                  onReactionChanged: (reaction, index) async {
                    if (await firebaseServices
                        .isUserSignIn(context)) {
                      final _userModel =
                      await firebaseServices.getUserInfo();

                      firebaseServices.addUsersReactionToASession(
                          context, index,
                          session: element,
                          sender: _userModel.nickname ?? '');

                      saveUserMe2Activity();
                      await firebaseServices.updateSessionLastTimeActivity(element.sessionId.toString());
                    }

                  }, session: element,
                ),

                new Spacer(),

                Visibility(
                  visible: element.userId == currentUser?.uid,
                  child: GestureDetector(
                    onTap: () {
                      if (element.featured == false)
                        featureAlertDialog(context);
                      else unfeatureAlertDialog(context);
                    },
                    child: Container(
                      child: Visibility(
                        visible: element.repliesEnabled == true,
                        child: Icon(
                          element.featured == true ? Icons.lightbulb : Icons.lightbulb_outline,
                          color: Pallet.colorWhite,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 10,),


                Visibility(
                  visible: element.userId == currentUser?.uid,
                  child: GestureDetector(
                    onTap: () {
                      if (element.archived == false)
                        showCustomDialog(context,
                            message: element.archived == true
                                ? AppString.unarchive_alert_note
                                : AppString.archive_alert_note,
                            onPressed: () {
                              sendToArchive();
                              Navigator.pushReplacementNamed(context, AppRoutes.diarySessions);
                            });
                      else
                        showCustomDialog(context,
                            message: element.archived == false
                                ? AppString.archive_alert_note
                                : AppString.unarchive_alert_note,
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.diarySessions);
                              removeFromArchive();
                            });
                    },

                    child: Container(
                      child: Visibility(
                        visible: element.userId == currentUser?.uid,
                        child: Icon(
                          element.archived == true ? Icons.archive_rounded : Icons.archive_outlined,
                          color: Pallet.colorWhite,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),

                new Spacer(),


                StreamBuilder(
                    stream: firebaseServices
                        .getFeaturedSessionsComments(element.sessionId!),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                      if (snapShot.hasError) {
                        return Container();
                      }
                      if (snapShot.hasData) {
                        return CommentsButton(
                          count: snapShot.data!.docs.length,
                          onPressed: () => PageRouter.gotoWidget(
                              EgoModeSessionDetail(featuredSessionModel: element),
                              context),);
                      }
                      return Container();
                    }),
              ],
            ),
            const Divider(
              thickness: 1,
              indent: 0,
              endIndent: 0,
              color: Colors.white70,
              height: 3,
            ),

            StreamBuilder(
                stream: firebaseServices
                    .getFeaturedSessionsComments(element.sessionId!),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                  if (snapShot.hasError) {
                    return Container();
                  }

                  List<CommentSessionModel> _commentSessionList = [];

                  if (snapShot.hasData) {
                    _commentSessionList.clear();

                    /// clear list
                    snapShot.data!.docs
                        .map((e) => _commentSessionList
                        .add(CommentSessionModel.fromJson(e.data())))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Text(
                          _returnComment(_commentSessionList).message ?? '',
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }
                  return Container();
                }),
          ],
        ),
      ),
    );
  }

  CommentSessionModel _returnComment(
      List<CommentSessionModel> _commentSessionList) {
    try {
      final _filter = _commentSessionList
          .where((element) =>
      _commentSessionList.isNotEmpty &&
          element.isUserAdmin)
          .toList();
      return _filter.first;
    } catch (e) {
      return CommentSessionModel();
    }
  }


  String? getDonateUrl(){
    return AppString.donate_url;
  }

  onDonateClicked() {
    var donateUrl = getDonateUrl();
    launch(donateUrl!);
  }




  featureAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("TopUp Love"),
      onPressed:  () {
        onDonateClicked();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Request Feature\n"
          "Cost: 1,000+ Loves"),
      onPressed:  () {
        // setToFeatured();
        Navigator.pushReplacementNamed(context, AppRoutes.requestFeatureForm);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Feature This Session?"),
      content: Text(AppString.ego_mode_feature_alert_note),
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


  unfeatureAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
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


  /// Save user reaction activity

  Future<void> saveUserMe2Activity() async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = element.sessionId;
    final sessionOwnerId = element.userId;
    final sessionOwnerAvatar = element.userAvatarUrl.toString();
    final sessionOwnerNickname = element.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = _user.nickname.toString();
    final sessionVisitorAvatar =  _user.userType != "REGULAR"
        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
        : _user.avatarUrl.toString();
    final activityMessage = "$sessionVisitorNickname reacted to $sessionOwnerNickname's session.";
    final activityType = "react";
    final userActivityId = "";
    FirebaseFirestore.instance
        .collection('user_activity')
        .add({
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
