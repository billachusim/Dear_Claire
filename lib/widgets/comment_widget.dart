import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/create_session/sound/custom_play_sound_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/play_advise_voice_note.dart';
import 'package:clairediary/widgets/thanks_button.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/transaction_model.dart' as t_model;
import '../services/data/notification_model.dart' as pushNotification;
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/user_model.dart';
import '../ui/featured/model/session.dart';
import '../ui/routes/page_router_animation.dart';
import '../ui/visited_user_ego_page/visited_user_ego_page.dart';
import '../utils/constant.dart';
import '../utils/strings.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'custom_image_widget.dart';


class CommentWidget extends StatefulWidget {
  CommentWidget(
      {Key? key,
      this.onPressed,
      this.onShare,
      required this.commentSessionModel, required this.featuredSessionModel, required this.userId})
      : super(key: key);

  CommentSessionModel? commentSessionModel;
  final Function()? onPressed;
  final Function()? onShare;
  late String visitedUsersID;
  late String visitedEgoName;
  Session? featuredSessionModel;
  final String userId;

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  TextEditingController editAdviseController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool? isFlagged;
  String? _commentTime;

  String timeAgo() {
    final commentTime = widget.commentSessionModel?.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    _commentTime = _time;
    return _commentTime.toString();
  }




  Future<void> editAdvise() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final advise = editAdviseController.text;
    final document = FirebaseFirestore.instance
        .collection("sessions")
        .doc(sessionId)
        .collection("comments")
        .doc(commentId);
        await document.update({
      "message": advise,
    },
    );
    logger.d('Successfully saved edited advise');
    print('EditedAdvise: $advise');
  }

  //show up when user clicks on the FAB to edit an advise
  Future<void> _showCardDialog() async {
    editAdviseController.text = widget.commentSessionModel!.message.toString();
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
              child: Text(AppString.edit_advise_dialog_header,
                  textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack),),
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
                        controller: editAdviseController,
                        minLines: 4,
                        maxLines: 200,
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
                  editAdvise();
                  Navigator.of(context).pop();
                  setState(() {
                    editAdviseController.text = "";
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // In /lib/widgets/comment_widget.dart

  Future<void> _handleThanksTransaction() async {
    if (currentUser == null) {
      showToast("You must be logged in to thank an advise.");
      return;
    }

    final thankerId = currentUser!.uid;
    final thankedAdvise = widget.commentSessionModel!;
    final thankedUserId = thankedAdvise.userId!;

    // --- 1. PREVENT SELF-THANKS AND REPEAT THANKS ---
    if (thankerId == thankedUserId) {
      showToast("You cannot thank your own advise.");
      return;
    }
    if (thankedAdvise.thanks!.contains(thankerId)) {
      showToast("You have already thanked this advise.");
      return;
    }

    // This is the existing `onPressed` logic (likely _updateReaction)
    // We call it here to update the UI immediately and add the user to the `thanks` array.
    widget.onPressed?.call();

    // --- 2. CHECK IF THE THANKED USER IS AN ALTER EGO ---
    final isAlterEgo = thankedAdvise.alterEgoId != null && thankedAdvise.alterEgoId!.isNotEmpty;

    if (!isAlterEgo) {
      // If not an Alter Ego, just add the 'thanks' without a transaction.
      showToast("Thank you for your feedback!");
      return;
    }

    // --- 3. PROCEED WITH 1-LOVE "SILENT" TRANSACTION ---
    try {
      final thanker = await firebaseServices.getUserInfo();
      if (thanker.currentLoveCount < 1) {
        showToast("You need at least 1 ❤️ to thank an Alter Ego's advise.");
        return; // Not enough love.
      }

      // Use a Firestore WriteBatch for an atomic update.
      final batch = FirebaseFirestore.instance.batch();

      // a. Debit 1 love from the thanker's CURRENT count.
      final thankerRef = FirebaseFirestore.instance.collection('users').doc(thankerId);
      batch.update(thankerRef, {'currentLoveCount': FieldValue.increment(-1)});

      // b. Increment the thanker's NEW "loveSentForThanks" counter.
      batch.update(thankerRef, {'loveSentForThanks': FieldValue.increment(1)});

      // c. Credit 1 love to the thanked user's NEW "loveFromThanks" field.
      final thankedUserRef = FirebaseFirestore.instance.collection('users').doc(thankedUserId);
      batch.update(thankedUserRef, {'loveFromThanks': FieldValue.increment(1)});

      // Commit all three updates at once.
      await batch.commit();

      showToast("1 ❤️ sent to ${thankedAdvise.userNickname} as thanks!");

      // Notify the thanked user
      await notificationService.sendNotification(
          pushNotification.NotificationModel(
              topic: thankedUserId,
              data: pushNotification.Data(id: thankedUserId, route: 'wallet'),
              notification: pushNotification.Notification(
                  title: "You Received a Thank You!",
                  body: "${thanker.nickname} thanked your advise and sent you 1 ❤️."
              )
          ).toJson()
      );

    } catch (e) {
      print("Error during silent thanks transaction: $e");
      showToast("An error occurred. Please try again.");
    }
  }



  /// Delete an Advise

  Future<void> deleteAdvise() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final collection = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection(AppString.appFeaturedSessionsComments);
    await collection.doc(commentId).delete();
    logger.d('Successfully deleted an advise');
  }



  Future<void> decrementAdviseCount() async {
    final userId = widget.commentSessionModel!.userId.toString();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set({
      "adviseCount": FieldValue.increment(-1),
    },
      SetOptions(merge: true),
    );
    logger.d('Decreased advise count');
  }


  Future<void> decrementTotalLoveCount() async {
    final userId = widget.commentSessionModel!.userId.toString();

    // The old FirebaseFirestore.instance.collection('users')... call and
    // the old _transactionService.recordTransaction call are no longer needed here.

    // --- NEW TREASURY LOGIC ---
    // A single, safe call to the new centralized method.
    // It handles the user's debit, Claire's credit, and transaction recording.
    await firebaseServices.updateTreasuryAndUser(
      userId: userId,
      amount: 10,
      type: t_model.TransactionType.debit,
      userTransactionDescription: "10 Loves lost for a deleted advise.",
      metadata: {
        'sessionId': widget.featuredSessionModel?.sessionId,
        'commentId': widget.commentSessionModel?.commentId,
        'reason': 'advise_deleted'
      },
    );
    // --- END OF NEW TREASURY LOGIC ---

    // --- Send Push Notification to the User ---
    try {
      final notificationModel = pushNotification.NotificationModel(
          topic: userId, // Send to the user's personal topic
          data: pushNotification.Data(id: userId, route: 'wallet'),
          notification: pushNotification.Notification(
              title: 'An Advise Was Deleted',
              body: "Your advise was deleted, and you lost 10 ❤️."));
      await notificationService.sendNotification(notificationModel.toJson());
    } catch (e) {
      print("Failed to send 'Advise Deleted' push notification: $e");
    }
    // --- End of Push Notification ---
  }



  /// subscribe user to a topic
  Future<void> notifyForDeletedAdvise() async {
    final userId = widget.commentSessionModel!.userId.toString();
    final sessionTitle = widget.featuredSessionModel!.title ?? '';
    final sessionId = widget.featuredSessionModel!.sessionId.toString();
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
      topic: sessionId,
      data: pushNotification.Data(id: userId, route: sessionId.toString()),
      notification: pushNotification.Notification(
          title: 'Please, Be Careful.', body: 'Your advise on the session: $sessionTitle was deleted. You lost 10 Loves.'),
    );
    notificationService.sendNotification(_notificationModel.toJson());
    logger.d('Deleted an advise from this session: $sessionTitle');
  }




  /// Flag an Advise

  Future<bool?> sendToFlagged() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection(AppString.appFeaturedSessionsComments)
        .doc(commentId)
        .update({
      "flagged": value,
    },
    );
    logger.d('Successfully flagged a session');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }



  Future<bool?> removeFromFlagged() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection(AppString.appFeaturedSessionsComments)
        .doc(commentId)
        .update({
      "flagged": value,
    },
    );
    logger.d('Successfully unflagged a session');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            AppImages.appChatBg,
          ),
          fit: BoxFit.fill,
        ),
          borderRadius: BorderRadius.circular(30), color: Pallet.colorWhite),
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
                  widget.visitedUsersID =
                      widget.commentSessionModel?.isUserAdmin == true
                          ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                          : widget.commentSessionModel!.userId ?? '';
                  widget.visitedEgoName =
                      widget.commentSessionModel?.isUserAdmin == true
                          ? "Claire"
                          : widget.commentSessionModel!.userNickname ?? '';
                  String thisEgoName = widget.visitedEgoName;
                  String thisUser =
                      widget.commentSessionModel?.isUserAdmin == true
                          ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                          : widget.commentSessionModel!.userId ?? '';
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
                  print("Visited User ID::: $thisEgoName");
                },
                child: CachedNetworkImage(
                    width: 40,
                    height: 40,
                    imageUrl: widget.commentSessionModel?.isUserAdmin == true
                        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
                        : widget.commentSessionModel!.userAvatarUrl ?? '',
                    imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Image.asset(
                          "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                          width: 40,
                          height: 40,
                        ) //Icon(Icons.error),
                    ),
              ),
              SizedBox(
                width: 4,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        widget.visitedUsersID =
                            widget.commentSessionModel?.isUserAdmin == true
                                ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                                : widget.commentSessionModel!.userId ?? '';
                        widget.visitedEgoName =
                            widget.commentSessionModel?.isUserAdmin == true
                                ? "Lol, yes, it's me, Claire!"
                                : widget.commentSessionModel!.userNickname ??
                                    '';
                        String thisEgoName = widget.visitedEgoName;
                        String thisUser =
                            widget.commentSessionModel?.isUserAdmin == true
                                ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                                : widget.commentSessionModel!.userId ?? '';
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
                        print("Visited User ID::: $thisEgoName");
                      },
                      child: Text(
                          widget.commentSessionModel?.isUserAdmin == true
                              ? "Claire"
                              : widget.commentSessionModel!.userNickname ?? '',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 15.0,
                              color: Pallet.colorBlack,
                              fontWeight: FontWeight.w800)),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                        timeAgo(),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 11.0,
                            color: Pallet.colorGrey,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThanksButton(
                    count: widget.commentSessionModel!.thanks!.length,
                    onPressed: widget.onPressed,
                    color: 1 == 2 ? Pallet.colorPrimaryDark : Pallet.colorTextGray,
                  ),

                  SizedBox(width: 3,),

                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUser?.uid)
                        .get(),
                    builder: (_, snapshot) {
                      if (snapshot.hasData) {
                        var data = snapshot.data!.data();
                        var userType = data?["userType"] ?? "0";

                        return Visibility(
                          visible: userType == "SUPER_ADMIN",
                          child: Text(widget.commentSessionModel!.alterEgoId!,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorSecondaryDark,
                                  fontWeight: FontWeight.w800)),
                        );
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 1,
          ),
          SelectableLinkify(
            onOpen: (link) async {
              final Uri url = Uri.parse("${link.url}");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                throw 'Could not launch $link';
              }
            },
            linkStyle: TextStyle(color: Colors.blue),
            text: widget.commentSessionModel!.message!,
            textAlign: TextAlign.justify,
            style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          Visibility(
            visible: widget.commentSessionModel!.audioUrl! != 'null',
            child: Container(
              child: widget.commentSessionModel!.audioUrl!.isNotEmpty
                  ? PlayAdviseVoiceNote(
                      filePath: widget.commentSessionModel!.audioUrl)
                  : SizedBox.shrink(),
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                  visible: widget.commentSessionModel!.image1!.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      PageRouter.gotoWidget(CustomImageWidget(imageUrl: widget
                          .commentSessionModel!.image1!), context);
                    },
                    child: CachedNetworkImage(
                        height: 150,
                        width: 150,
                        imageUrl: widget
                                .commentSessionModel!.image1!,
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
              SizedBox(
                width: 12,
              ),
              Visibility(
                  visible: widget.commentSessionModel!.image2!.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      PageRouter.gotoWidget(CustomImageWidget(imageUrl: widget
                          .commentSessionModel!.image2!), context);
                    },
                    child: CachedNetworkImage(
                        height: 150,
                        width: 150,
                        imageUrl: widget.commentSessionModel!.image2!,
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


          Row(

            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [

                if (widget.commentSessionModel!.isUserAdmin)
                  GestureDetector(
                    onTap: widget.onShare,
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_rounded,
                          size: 17,
                          color: Pallet.colorSecondary,
                        ),
                        Text(
                          'Share',
                          style: GoogleFonts.lato(
                              fontSize: 15.0,
                              color: Pallet.colorSecondary,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),


                  Visibility(
                    visible: widget.commentSessionModel?.flagged == true,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.userId == currentUser?.uid)
                          showCustomDialog(context,
                              message: AppString.delete_advise_alert_note,
                              onPressed: () {
                                PageRouter.goBack(context);
                                deleteAdvise();
                                decrementAdviseCount();
                                decrementTotalLoveCount();
                                notifyForDeletedAdvise();
                              });
                        },
                      child: Visibility(
                        visible: widget.userId == currentUser?.uid,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_forever_rounded,
                              color: Pallet.colorPrimaryDark,
                              size: 16,
                            ),
                            Text(
                              'Delete',
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorPrimaryDark,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                    SizedBox(width: 5,),

                    if (widget.commentSessionModel!.userId == currentUser?.uid)
                      GestureDetector(
                        onTap: _showCardDialog,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 17,
                              color: Pallet.colorPrimaryDark,
                            ),
                            Text(
                              'Edit',
                              style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  color: Pallet.colorPrimaryDark,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
              ]
              ),

              Spacer(flex: 1,),


              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  if (widget.commentSessionModel!.isUserAdmin != true)
                    GestureDetector(
                      onTap: () {
                        if (widget.commentSessionModel?.flagged == false)
                          showCustomDialog(context,
                              message: widget.commentSessionModel!.flagged == true
                                  ? AppString.unflag_advise_alert_note
                                  : AppString.flag_advise_alert_note,
                              onPressed: () {
                                PageRouter.goBack(context);
                                sendToFlagged();
                              });
                        else
                          showCustomDialog(context,
                              message: widget.commentSessionModel!.flagged == false
                                  ? AppString.flag_advise_alert_note
                                  : AppString.unflag_advise_alert_note,
                              onPressed: () {
                                PageRouter.goBack(context);
                                removeFromFlagged();
                              });
                      },
                      child: Row(
                        children: [
                          Icon(
                            widget.commentSessionModel!.flagged == true
                                ? Icons.flag
                                : Icons.flag_outlined,
                            color: Pallet.colorPrimary,
                            size: 16,
                          ),
                          Text(
                            'Flag',
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorPrimary,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(width: 5,),

                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUser?.uid)
                        .get(),
                    builder: (_, snapshot) {
                      if (snapshot.hasData) {
                        var data = snapshot.data!.data();
                        var userType = data?["userType"];

                        return
                          Visibility(
                            visible: userType == "SUPER_ADMIN",
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (currentUser == null) {
                                      Navigator.of(context)
                                          .pushReplacementNamed(AppRoutes.authSelection);
                                    } else {
                                      _showCardDialog();
                                    }
                                  },
                                  child: Row(
                                    children: [

                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Pallet.colorSecondary,
                                      ),

                                      Text(
                                        'Mod',
                                        style: GoogleFonts.lato(
                                            fontSize: 13.0,
                                            color: Pallet.colorSecondary,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 4,),

                                Visibility(
                                  visible: widget.commentSessionModel?.flagged == true,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (currentUser == null) {
                                        Navigator.of(context)
                                            .pushReplacementNamed(AppRoutes.authSelection);
                                      } else {
                                        showCustomDialog(context,
                                            message: AppString.delete_advise_alert_note,
                                            onPressed: () {
                                              PageRouter.goBack(context);
                                              deleteAdvise();
                                              decrementAdviseCount();
                                              decrementTotalLoveCount();
                                              notifyForDeletedAdvise();
                                            });
                                      }
                                      },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_forever_rounded,
                                          color: Pallet.colorSecondary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                      }

                      return Container();
                    },
                  ),
                ],
              ),

            ],
          ),

          SizedBox(height: 6,),
        ],
      ),
    );
  }
}
