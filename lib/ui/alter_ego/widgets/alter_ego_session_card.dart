import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/alter_ego/widgets/alter_ego_mode_session_detail.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/comments_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/cupertino.dart';

import '../../../services/firebase_services.dart';
import '../../../services/user_model.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../create_session/sound/custom_play_sound_widget.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class AlterEgoModeSessionCard extends StatelessWidget {
  Session element;
  bool? isFeatured;

  AlterEgoModeSessionCard({Key? key, required this.element, required this.visitedUsersID, required this.visitedEgoName}) : super(key: key);
  late String visitedUsersID;
  late String visitedEgoName;
  UserModel userModel = UserModel();
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

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () => PageRouter.gotoWidget(
          AlterEgoModeSessionDetail(featuredSessionModel: element),
          context),
      padding: EdgeInsets.zero,
      child: Container(
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
                  onTap: (){
                    visitedUsersID = element.userId!;
                    visitedEgoName = element.userNickname!;
                    String thisEgoName = visitedEgoName;
                    String thisUser = visitedUsersID;
                    PageRouter.gotoWidget(
                        VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                        context);
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
                        "assets/images/brown_boy_mask.png",
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
                        onTap: (){
                          visitedUsersID = element.userId!;
                          visitedEgoName = element.userNickname!;
                          String thisEgoName = visitedEgoName;
                          String thisUser = visitedUsersID;
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                              context);
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
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
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
                      fontSize: 18.0,
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
                      fontSize: 15.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.normal),
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

                Container(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Visibility(
                            visible: element.imageUrls!.isNotEmpty,
                            child: GestureDetector(
                              onTap: () {
                                PageRouter.gotoWidget(CustomImageWidget(imageUrl: element.imageUrls!.first.toString()), context);
                              },
                              child: CachedNetworkImage(
                                  height: 100,
                                  width: 100,
                                  imageUrl: element.imageUrls!.isNotEmpty
                                      ? element.imageUrls!.first
                                      : '',
                                  imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      image: DecorationImage(
                                        image: imageProvider,
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
                            visible: element.imageUrls!.isNotEmpty,
                            child: GestureDetector(
                              onTap: () {
                                PageRouter.gotoWidget(CustomImageWidget(imageUrl: element.imageUrls!.last.toString()), context);
                              },
                              child: CachedNetworkImage(
                                  height: 100,
                                  width: 100,
                                  imageUrl: element.imageUrls!.isNotEmpty
                                      ? element.imageUrls!.last
                                      : '',
                                  imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      image: DecorationImage(
                                        image: imageProvider,
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
                      ],
                    ),
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
                      final _userModel = await firebaseServices.getUserInfo();
                      firebaseServices.addUsersReactionToASession(
                          context, index,
                          session: element, sender: _userModel.nickname ?? '');
                    }, session: element,),
                new Spacer(),

                FutureBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(currentUser!.uid)
                      .get(),
                  builder: (_, snapshot) {
                    if (snapshot.hasData) {
                      var data = snapshot.data!.data();
                      var userType = data?["userType"] ?? "0";
                      debugPrint(
                          " This is the actual userType of this user ${userType.toString()}");
                      return
                        Visibility(
                          visible: userType == "SUPER_ADMIN",
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
                        );
                    }

                    return Center(
                        child: CircularProgressIndicator());
                  },
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
                              AlterEgoModeSessionDetail(featuredSessionModel: element),
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
          element.isUserAdmin &&
          element.alterEgoId == "claire" &&
          element.userId == "fSMVS2DY8ngblW3LlUYowgPkdR83")
          .toList();
      return _filter.last;
    } catch (e) {
      return CommentSessionModel();
    }
  }


  featureAlertDialog(BuildContext context) {

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
        Navigator.pushReplacementNamed(context, AppRoutes.alterEgoHomepage);
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
        Navigator.pushReplacementNamed(context, AppRoutes.alterEgoHomepage);
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


}