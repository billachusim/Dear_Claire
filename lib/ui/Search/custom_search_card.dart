import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/ui/featured/ego_mode_session_detail.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:clairediary/widgets/comments_button.dart';
import 'package:clairediary/widgets/metoo_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_services.dart';
import '../../services/user_model.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/toast.dart';
import '../create_session/sound/custom_play_sound_widget.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';

class CustomSearchCard extends StatelessWidget {
  Session element;

  CustomSearchCard({Key? key, required this.element, required this.visitedUsersID, required this.visitedEgoName}) : super(key: key);
  late String visitedUsersID;
  late String visitedEgoName;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = HexColor.fromHex(element.colorHex!);
    final Color textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

    return GestureDetector(
      onTap: () => PageRouter.gotoWidget(
          EgoModeSessionDetail(featuredSessionModel: element),
          context),
      child: Container(
        width: 270,
        height: 195,
        margin: EdgeInsets.symmetric(vertical: 2, horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      // --- 1. SETUP TRANSACTION DETAILS ---
                      final visitingUser = await firebaseServices.getUserInfo();
                      final String visitedUserId = element.userId!;
                      final String visitedEgoName = element.userNickname!;
                      const int visitCost = 1;

                      // --- 2. HANDLE SELF-VISIT, INSUFFICIENT LOVES & PERMISSIONS ---
                      if (visitingUser.userId == visitedUserId) {
                        // If visiting self, just navigate without a transaction.
                        PageRouter.gotoWidget(
                            VisitedUserEgoProfilePage(
                                visitedUsersID: visitedUserId,
                                visitedEgoName: visitedEgoName),
                            context);
                        return;
                      }

                      if (visitingUser.userType == "REGULAR" &&
                          visitingUser.currentLoveCount < 100) {
                        showToast("Need up to 500 Loves in Wallet or Alter Ego Access to view other Ego Profiles.");
                        return;
                      }

                      if (visitingUser.currentLoveCount < visitCost) {
                        showToast("You need at least 1 ❤️ to visit a profile.");
                        return;
                      }

                      // --- 3. PERFORM THE LOVE TRANSACTION ---
                      final bool success =
                      await firebaseServices.transferLoveBetweenUsers(
                        senderId: visitingUser.userId!,
                        receiverId: visitedUserId,
                        amountToSend: visitCost,
                        taxAmount: 0,
                        totalDebitAmount: visitCost,
                        senderTransactionDesc:
                        "1❤️ for visiting ${visitedEgoName}'s Ego.",
                        receiverTransactionDesc:
                        "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                        claireTransactionDesc:
                        "Tax from a profile visit.", // Will be 0, but required
                        forRoomVisits: 1, // Stat for the sender
                        fromRoomVisits: 1, // Stat for the receiver
                        metadata: {
                          'reason': 'profile_visit',
                          'visitedUserId': visitedUserId
                        },
                      );

                      // --- 4. NAVIGATE ON SUCCESS ---
                      if (success) {
                        // Only navigate to the profile if the transaction was successful.
                        PageRouter.gotoWidget(
                            VisitedUserEgoProfilePage(
                                visitedUsersID: visitedUserId,
                                visitedEgoName: visitedEgoName),
                            context);
                      }
                    },
                    child: CachedNetworkImage(
                        width: 33,
                        height: 33,
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
                          width: 20,
                          height: 20,
                        ) //Icon(Icons.error),
                    ),
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // --- 1. SETUP TRANSACTION DETAILS ---
                            final visitingUser = await firebaseServices.getUserInfo();
                            final String visitedUserId = element.userId!;
                            final String visitedEgoName = element.userNickname!;
                            const int visitCost = 1;
                            // --- 2. HANDLE SELF-VISIT ---
                            if (visitingUser.userId == visitedUserId) {
                              // If visiting self, just navigate without a transaction.
                              PageRouter.gotoWidget(
                                  VisitedUserEgoProfilePage(
                                      visitedUsersID: visitedUserId,
                                      visitedEgoName: visitedEgoName),
                                  context);
                              return;
                            }

                            // --- 3. CHECK PERMISSIONS & SUFFICIENT LOVES ---
                            // Note: The permission message was slightly different, so I've used the more descriptive one from the avatar's logic.
                            if (visitingUser.userType == "REGULAR" &&
                                visitingUser.currentLoveCount < 500) { // Changed from 50 to 500 for consistency
                              showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                              return;
                            }

                            if (visitingUser.currentLoveCount < visitCost) {
                              showToast("You need at least 1 ❤️ to visit a profile.");
                              return;
                            }

                            // --- 4. PERFORM THE LOVE TRANSACTION ---
                            final bool success =
                            await firebaseServices.transferLoveBetweenUsers(
                              senderId: visitingUser.userId!,
                              receiverId: visitedUserId,
                              amountToSend: visitCost,
                              taxAmount: 0,
                              totalDebitAmount: visitCost,
                              senderTransactionDesc:
                              "1❤️ for visiting ${visitedEgoName}'s Ego.",
                              receiverTransactionDesc:
                              "1❤️ from ${visitingUser.nickname} visit to your Ego.",
                              claireTransactionDesc:
                              "Tax from a profile visit.", // Will be 0, but required
                              forRoomVisits: 1, // Stat for the sender
                              fromRoomVisits: 1, // Stat for the receiver
                              metadata: {
                                'reason': 'profile_visit',
                                'visitedUserId': visitedUserId
                              },
                            );

                            // --- 5. NAVIGATE ON SUCCESS ---
                            if (success) {
                              // Only navigate to the profile if the transaction was successful.
                              PageRouter.gotoWidget(
                                  VisitedUserEgoProfilePage(
                                      visitedUsersID: visitedUserId,
                                      visitedEgoName: visitedEgoName),
                                  context);
                            }
                          },
                          child: Text(element.userNickname!,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: GoogleFonts.lato(
                                  fontSize: 15.0,
                                  color: textColor,
                                  fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(
                          height: 1,
                        ),
                        Text(timeConverter(element.timeCreated!),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 10.0,
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

                        Text(Mood.getMood(element.moodId) ?? "${Mood.getMood(1)}",
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 11.0,
                                color: textColor,
                                fontWeight: FontWeight.w700)),
                        SizedBox(
                          height: 1,
                        ),
                        Text(element.location ?? "",
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w700)
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 3,
            ),
            Center(
              child: Text(element.title!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: textColor,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 3,
            ),
            Column(
              children: [
                Text(
                  element.audioUrl!.isNotEmpty ? "" : element.message!,
                  textAlign: TextAlign.start,
                  maxLines: element.imageUrls!.isNotEmpty ? 1 : 3,
                  style: GoogleFonts.lato(
                      fontSize: 14.0,
                      color: textColor,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: 3,
                ),
                Container(
                  child: element.audioUrl!.isNotEmpty
                      ? CustomPlaySoundWidget(filePath: element.audioUrl)
                      : SizedBox.shrink(),
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
                                  height: 45,
                                  width: 45,
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
                                    "assets/images/Speak_No_Evil_Monkey_Emoji.png",
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
                                  height: 45,
                                  width: 45,
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
                                    "assets/images/Speak_No_Evil_Monkey_Emoji.png",
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
                Flexible(
                  child: MetooButton(
                    cheers: element.meToos!.length,
                    thanks: element.meLove!.length,
                    sorry: element.meHiFive!.length,
                    me2: element.meFlower!.length,
                    color: textColor,
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
            Divider(
              thickness: 1,
              indent: 0,
              endIndent: 0,
              color: secondaryTextColor,
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
                          maxLines: 1,
                          style: GoogleFonts.lato(
                            fontSize: 11.0,
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
      _commentSessionList.isNotEmpty)
          .toList();
      return _filter.first;
    } catch (e) {
      return CommentSessionModel();
    }
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
