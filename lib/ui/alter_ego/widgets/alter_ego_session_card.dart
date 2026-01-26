import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/alter_ego/widgets/alter_ego_mode_session_detail.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/comments_button.dart';
import 'package:clairediary/widgets/metoo_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:flutter/cupertino.dart';

import '../../../helpers/toast_helper.dart';
import '../../../services/firebase_services.dart';
import '../../../services/notification_service.dart';
import '../../../services/user_model.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../create_session/sound/custom_play_sound_widget.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class AlterEgoModeSessionCard extends StatefulWidget {
  Session element;
  bool? isFeatured;
  bool? isArchived;

  AlterEgoModeSessionCard({Key? key, required this.element, required this.visitedUsersID, required this.visitedEgoName}) : super(key: key);
  late String visitedUsersID;
  late String visitedEgoName;

  @override
  State<AlterEgoModeSessionCard> createState() => _AlterEgoModeSessionCardState();
}

class _AlterEgoModeSessionCardState extends State<AlterEgoModeSessionCard> {
  bool? isFeatured;
  UserModel? _currentUserModel;
  UserModel userModel = UserModel();
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _updateLanguagePreference();
    widget.isFeatured = widget.element.featured;
    widget.isArchived = widget.element.archived;
  }

  /// Get user detail for language/translation sake.
  Future<void> _updateLanguagePreference() async {
    if (currentUser != null) {
      // 1. Fetch user data from Firestore
      var userModel = await firebaseServices.getUserInfo();

      // 2. Check if language preference is missing (for existing users)
      if (userModel.languagePreference == null || userModel.languagePreference!.isEmpty) {
        // Get device language
        final deviceLanguageCode = Platform.localeName.split('_').first;

        // Update the model in memory immediately for the UI
        userModel.languagePreference = deviceLanguageCode;

        // Asynchronously update Firestore in the background
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'languagePreference': deviceLanguageCode});

        logger.d("Updated language preference for existing user: $deviceLanguageCode");
      }

      // 3. Update the state to rebuild the widget with the correct language
      if (mounted) {
        setState(() {
          _currentUserModel = userModel;
        });
      }
    }
  }

  /// Edit feature
  Future<bool?> setToFeatured() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.element.sessionId)
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
        .doc(widget.element.sessionId)
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
    final Color backgroundColor = HexColor.fromHex(widget.element.colorHex!);
    final Color textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

    return CupertinoButton(
      onPressed: () => PageRouter.gotoWidget(
          AlterEgoModeSessionDetail(featuredSessionModel: widget.element),
          context),
      padding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
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
                  onTap: (){
                    String thisEgoName = widget.visitedEgoName;
                    String thisUser = widget.visitedUsersID;
                    PageRouter.gotoWidget(
                        VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                        context);
                    print("Visited User ID::: ${widget.visitedUsersID}");
                  },
                  child: CachedNetworkImage(
                      width: 50,
                      height: 50,
                      imageUrl: widget.element.userAvatarUrl!,
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
                        onTap: (){
                          String thisEgoName = widget.visitedEgoName;
                          String thisUser = widget.visitedUsersID;
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                              context);
                          print("Visited User ID::: ${widget.visitedUsersID}");
                        },
                        child: Text(widget.element.userNickname!,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 20.0,
                                color: textColor,
                                fontWeight: FontWeight.w800)),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(timeConverter(widget.element.timeCreated!),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Text(Mood.getMood(widget.element.moodId) ?? "${Mood.getMood(1)}",
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: textColor,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 3,
                      ),
                      Text(widget.element.location ?? "",
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 7,
            ),
            Center(
              child: Text(
                (_currentUserModel?.languagePreference != null &&
                    widget.element.translatedTitle != null &&
                    widget.element.translatedTitle!.containsKey(_currentUserModel!.languagePreference))
                    ? widget.element.translatedTitle![_currentUserModel!.languagePreference]!
                    : widget.element.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.0,
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            SizedBox(
              height: 8,
            ),
            Column(
              children: [
                Text(
                  // Choose translated message if available, otherwise default to original
                  (_currentUserModel?.languagePreference != null &&
                      widget.element.translatedSession != null &&
                      widget.element.translatedSession!
                          .containsKey(_currentUserModel!.languagePreference))
                      ? widget.element.translatedSession![_currentUserModel!.languagePreference]!
                      : widget.element.message!,
                  textAlign: TextAlign.justify,
                  maxLines: (widget.element.imageUrls?.isNotEmpty ??
                      false) ||
                      (widget.element.videoUrls?.isNotEmpty ??
                          false)
                      ? 2
                      : 7,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize:
                    17.0,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    height:
                    1.4,
                    letterSpacing:
                    -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: 6,
                ),

                Container(
                  child: widget.element.audioUrl!.isNotEmpty
                      ? CustomPlaySoundWidget(filePath: widget.element.audioUrl)
                      : SizedBox.shrink(),
                ),

                Visibility(
                  visible: widget.element.imageUrls!.isNotEmpty,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 5,
                    children: List.generate(widget.element.imageUrls!.length, (index) {
                      String image = widget.element.imageUrls![index].toString();
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              PageRouter.gotoWidget(CustomImageWidget(imageUrl: image), context);
                            },
                            child: CachedNetworkImage(
                                height: 400,
                                width: 400,
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
                  cheers: widget.element.meToos!.length,
                  thanks: widget.element.meLove!.length,
                  sorry: widget.element.meHiFive!.length,
                  me2: widget.element.meFlower!.length,
                  color: textColor,
                  session: widget.element,
                  onReactionChanged: (reaction, index) async {
                    if (await firebaseServices.isUserSignIn(context) == false) {
                      return;
                    }

                    // --- 1. SETUP TRANSACTION DETAILS ---
                    final reactingUser = await firebaseServices.getUserInfo();
                    final String reactingUserId = reactingUser.userId!;
                    final String sessionOwnerId = widget.element.userId!;
                    const int reactionCost = 1;

                    // --- 2. PREVENT SELF-REACTION & INSUFFICIENT LOVES ---
                    if (reactingUserId == sessionOwnerId) {
                      // User is reacting to their own post, just update the reaction locally.
                      // The original logic handles this well.
                      firebaseServices.addUsersReactionToASessionByIndex(
                        context,
                        index,
                        session: widget.element,
                        sender: reactingUser.nickname ?? '',
                      );
                      showToast(message: "You reacted to your own session.");
                      return;
                    }

                    if (reactingUser.currentLoveCount < reactionCost) {
                      showToast(message: "You need at least 1❤️ to react.");
                      return;
                    }

                    if (currentUser == null) {
                      showToast(message: "You must be logged in to react to a session.");
                      return;
                    }

                    // --- 3. PERFORM THE LOVE TRANSACTION ---
                    final bool success =
                    await firebaseServices.transferLoveBetweenUsers(
                      senderId: reactingUserId,
                      receiverId: sessionOwnerId,
                      amountToSend: reactionCost,
                      taxAmount: 0, // No tax on a 1-love transaction
                      totalDebitAmount: reactionCost,
                      senderTransactionDesc:
                      "1❤️ for reacting to session ${widget.element.title}.",
                      receiverTransactionDesc:
                      "1❤️ from reaction to your session ${widget.element.title} by ${reactingUser.nickname}.",
                      claireTransactionDesc: "Tax from a session reaction.",
                      // Pass the specific stat increments
                      forReactions: reactionCost,
                      fromReactions: reactionCost,
                      metadata: {
                        'reason': 'session_reaction',
                        'sessionId': widget.element.sessionId,
                        'reactionIndex': index
                      },
                    );

                    // --- 4. UPDATE REACTION COUNT ON SUCCESS ---
                    if (success) {
                      // Only after a successful transaction, update the reaction on the session.
                      firebaseServices.addUsersReactionToASessionByIndex(
                        context,
                        index,
                        session: widget.element,
                        sender: reactingUser.nickname ?? '',
                      );
                      saveAlterEgoMe2Activity(); // Your existing activity tracking
                      // --- C. START: NEW TARGETED NOTIFICATION LOGIC ---
                      try {
                        final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(sessionOwnerId).get();
                        if (receiverDoc.exists) {
                          final receiverToken = receiverDoc.data()?['fcmId'] as String?;
                          final senderName = reactingUser.nickname ?? 'Someone';
                          final sessionTitle = widget.element.title ?? 'your session';
                          final truncatedTitle = sessionTitle.length > 30 ? sessionTitle.substring(0, 30) + '...' : sessionTitle;

                          // Note: 'reaction' is the Reaction object passed by the MetooButton
                          final reactionValue = reaction.value;

                          if (receiverToken != null && receiverToken.isNotEmpty) {
                            await notificationService.sendNotification({
                              "token": receiverToken,
                              "notification": {
                                "title": "Someone reacted to your session!",
                                "body": "$senderName reacted with '$reactionValue' to your session: \"$truncatedTitle\""
                              },
                              "data": {
                                "route": widget.element.sessionId
                              }
                            });
                            logger.d("Successfully sent 'new reaction' notification.");
                          }
                        }
                      } catch (e) {
                        print("Error sending 'new reaction' notification: $e");
                      }
                      // --- END: NEW TARGETED NOTIFICATION LOGIC ---
                      showToast(message: "1❤️ sent to the session owner!");
                    }
                    // If !success, the service method already shows a toast.
                  },
                ),
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
                      var userType = data?["userType"];
                      return
                        Visibility(
                          visible: userType == "SUPER_ADMIN",
                          child: GestureDetector(
                            onTap: () {
                              if (widget.element.featured == false)
                                featureAlertDialog(context);
                              else unfeatureAlertDialog(context);
                            },
                            child: Container(
                              child: Visibility(
                                visible: widget.element.repliesEnabled == true,
                                child: Icon(
                                  widget.element.featured == true ? Icons.lightbulb : Icons.lightbulb_outline,
                                  color: textColor,
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
                        .getFeaturedSessionsComments(widget.element.sessionId!),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                      if (snapShot.hasError) {
                        return Container();
                      }
                      if (snapShot.hasData) {
                        return CommentsButton(
                          count: snapShot.data!.docs.length,
                          onPressed: () => PageRouter.gotoWidget(
                              AlterEgoModeSessionDetail(featuredSessionModel: widget.element),
                              context),);
                      }
                      return Container();
                    }),
              ],
            ),
            Divider(
              thickness: 1,
              indent: 0,
              endIndent: 0,
              color: secondaryTextColor,
              height: 3,
            ),
            StreamBuilder(
                stream: firebaseServices
                    .getFeaturedSessionsComments(widget.element.sessionId!),
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
                            color: textColor,
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

  /// Save alter ego reaction activity

  Future<void> saveAlterEgoMe2Activity() async {
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = widget.element.sessionId;
    final sessionOwnerId = widget.element.userId;
    final sessionOwnerAvatar = widget.element.userAvatarUrl.toString();
    final sessionOwnerNickname = widget.element.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = "Claire";
    final sessionVisitorAvatar = "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691";

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
    logger.d('Successfully saved alter ego reaction activity');
    print('Activity Message: $activityMessage');

  }
}
