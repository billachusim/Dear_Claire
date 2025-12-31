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
import 'package:flutter/cupertino.dart';
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
      this.onShare,
      required this.commentSessionModel, required this.featuredSessionModel, required this.userId})
      : super(key: key);

  CommentSessionModel? commentSessionModel;
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
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool? isFlagged;
  String? _commentTime;
  bool _isThanked = false;
  bool _isAvatarLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the button's state based on Firestore data
    if (currentUser != null) {
      _isThanked = widget.commentSessionModel?.thanks?.contains(currentUser!.uid) ?? false;
    }
  }

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



// Replace the entire method in lib/widgets/comment_widget.dart

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
    if (thankedAdvise.thanks?.contains(thankerId) ?? false) {
      showToast("You have already thanked this advise.");
      return;
    }

    // --- 2. SETUP ---
    final isAlterEgo = thankedAdvise.alterEgoId != null && thankedAdvise.alterEgoId!.isNotEmpty;
    final thanker = await firebaseServices.getUserInfo(); // Fetch thanker info early

    // --- 3. HANDLE REGULAR USER TRANSACTION ---
    if (!isAlterEgo) {
      const int thankYouCost = 1;
      try {
        final bool success = await firebaseServices.transferLoveBetweenUsers(
          senderId: thankerId,
          receiverId: thankedUserId,
          amountToSend: thankYouCost,
          taxAmount: 0,
          totalDebitAmount: thankYouCost,
          senderTransactionDesc: "1❤️ for thanks to an advise from ${thankedAdvise.userNickname}.",
          receiverTransactionDesc: "1❤️ from thanks to your advise by ${thanker.nickname}.",
          claireTransactionDesc: "No Tax from a regular user 'Thank You' transaction.",
          forThanks: thankYouCost,
          fromThanks: thankYouCost,
          metadata: {
            'reason': 'thank_advise_regular',
            'sessionId': widget.featuredSessionModel?.sessionId,
            'commentId': thankedAdvise.commentId,
          },
        );

        if (success) {
          showToast("...and you too!");

          // --- POST-TRANSACTION LOGIC (NOTIFICATION & ACTIVITY) ---
          _performPostThanksActions(
            thanker: thanker,
            thankedUser: thankedAdvise,
            amount: thankYouCost,
          );
          // --- END POST-TRANSACTION LOGIC ---
        }
      } catch (e) {
        print("Error during regular user thanks transaction: $e");
        showToast("An error occurred. Please try again.");
      }
      return;
    }

    // --- 4. HANDLE ALTER EGO TRANSACTION ---
    const int thankYouCost = 3;
    const int taxAmount = 2;
    const int totalDebit = thankYouCost + taxAmount;

    try {
      if (thanker.currentLoveCount < totalDebit) {
        showToast("You need at least $totalDebit ❤️ to thank an Alter Ego's advise.");
        return;
      }

      final bool success = await firebaseServices.transferLoveBetweenUsers(
        senderId: thankerId,
        receiverId: thankedUserId,
        amountToSend: thankYouCost,
        taxAmount: taxAmount,
        totalDebitAmount: totalDebit,
        senderTransactionDesc: "$totalDebit❤️ for thanks to an advise from ${thankedAdvise.alterEgoId ?? thankedAdvise.userNickname}.",
        receiverTransactionDesc: "$thankYouCost❤️ from ${thanker.nickname} for your advise.",
        claireTransactionDesc: "$taxAmount❤️ tax from a 'Thank You' transaction.",
        forThanks: thankYouCost,
        fromThanks: thankYouCost,
        metadata: {
          'reason': 'thank_advise_alterego',
          'sessionId': widget.featuredSessionModel?.sessionId,
          'commentId': thankedAdvise.commentId,
        },
      );

      if (success) {
        showToast("$totalDebit❤️ sent to ${thankedAdvise.userNickname} as thanks!");

        // --- POST-TRANSACTION LOGIC (NOTIFICATION & ACTIVITY) ---
        _performPostThanksActions(
          thanker: thanker,
          thankedUser: thankedAdvise,
          amount: thankYouCost,
        );
        // --- END POST-TRANSACTION LOGIC ---
      }
    } catch (e) {
      print("Error during Alter Ego thanks transaction: $e");
      showToast("An error occurred. Please try again.");
    }
  }

// --- NEW HELPER METHOD FOR CLEANLINESS ---
  Future<void> _performPostThanksActions({
    required UserModel thanker,
    required CommentSessionModel thankedUser,
    required int amount,
  }) async {
    try {
      // 1. SAVE USER ACTIVITY (as you wanted)
      await firebaseServices.saveUserActivity(
        activityType: 'thank',
        activityMessage: "${thanker.nickname ?? 'An Ego'} gave thanks with ❤️ to ${thankedUser.alterEgoId ?? thankedUser.userNickname}'s advice.",
        recipientId: thankedUser.userId!,
        sessionId: widget.featuredSessionModel?.sessionId,
      );
      logger.d("User activity for 'thank' saved successfully.");

      // 2. SEND TARGETED NOTIFICATION
      final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(thankedUser.userId!).get();
      if (receiverDoc.exists) {
        final receiverToken = receiverDoc.data()?['fcmId'] as String?;
        if (receiverToken != null && receiverToken.isNotEmpty) {
          await notificationService.sendNotification({
            "token": receiverToken,
            "notification": {
              "title": "Someone thanked your advise!",
              "body": "${thanker.nickname ?? 'A user'} gave thanks with $amount❤️ for your advise."
            },
            "data": {
              // Navigate user to the session where they were thanked
              "route": widget.featuredSessionModel?.sessionId
            }
          });
          logger.d("Targeted 'thank you' notification sent successfully.");
        }
      }

      // 3. UPDATE LOCAL UI by updating the 'thanks' array in Firestore
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.featuredSessionModel?.sessionId)
          .collection('comments')
          .doc(thankedUser.commentId)
          .update({
        'thanks': FieldValue.arrayUnion([thanker.userId])
      });

    } catch (e) {
      print("Error during post-thanks actions (activity/notification): $e");
      // Don't block the user, but log the error.
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

    try {
      final notificationModel = pushNotification.NotificationModel(
          topic: userId, // Send to the user's personal topic
          data: pushNotification.Data(id: userId, route: 'wallet'),
          notification: pushNotification.Notification(
              title: 'An Advise Was Deleted',
              body: "Your advise was deleted, and you lost 10❤️."));
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
                  // --- 1. SHOW THE LOADER ---
                  setState(() {
                    _isAvatarLoading = true;
                  });
                  try {
                    // --- 1. SETUP TRANSACTION DETAILS ---
                    widget.visitedUsersID =
                    widget.commentSessionModel?.isUserAdmin == true
                        ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                        : widget.commentSessionModel!.userId ?? '';
                    widget.visitedEgoName =
                    widget.commentSessionModel?.isUserAdmin == true
                        ? "Claire"
                        : widget.commentSessionModel!.userNickname ?? '';
                    String thisEgoName = widget.visitedEgoName;
                    String thisUserID = widget.commentSessionModel?.isUserAdmin == true
                        ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                        : widget.commentSessionModel!.userId ?? '';
                    UserModel visitingUser = await firebaseServices.getUserInfo();
                    const int visitCost = 1;

                    // --- 2. HANDLE SELF-VISIT, INSUFFICIENT LOVES & PERMISSIONS ---
                    if (visitingUser.userId == thisUserID) {
                      // If visiting self, just navigate without a transaction.
                      PageRouter.gotoWidget(
                          VisitedUserEgoProfilePage(
                              visitedUsersID: thisUserID,
                              visitedEgoName: thisEgoName),
                          context);
                      return;
                    }

                    if (visitingUser.userType == "REGULAR" &&
                        visitingUser.currentLoveCount < 100) {
                      showToast("Need up to 100 Loves in Wallet or Alter Ego Access to view other Ego Profiles.");
                      return;
                    }

                    if (visitingUser.currentLoveCount < visitCost) {
                      showToast("You need at least 1❤️ to visit an ego.");
                      return;
                    }

                    if (currentUser == null) {
                      showToast("You must be logged in to visit an ego.");
                      return;
                    }

                    // --- 3. PERFORM THE LOVE TRANSACTION ---
                    final bool success =
                    await firebaseServices.transferLoveBetweenUsers(
                      senderId: visitingUser.userId!,
                      receiverId: thisUserID,
                      amountToSend: visitCost,
                      taxAmount: 0,
                      totalDebitAmount: visitCost,
                      senderTransactionDesc:
                      "1❤️ for visiting ${thisEgoName}'s Ego.",
                      receiverTransactionDesc:
                      "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                      claireTransactionDesc: "Tax from a profile visit.",
                      // Will be 0, but required
                      forProfileVisits: 1,
                      // Stat for the sender
                      fromProfileVisits: 1,
                      // Stat for the receiver
                      metadata: {
                        'reason': 'profile_visit',
                        'visitedUserId': thisUserID
                      },
                    );

                    // --- 4. NAVIGATE ON SUCCESS ---
                    if (success) {
                      showToast("You are visiting ${thisEgoName} with a kola of 1❤️.");


                      // --- NAVIGATE ---
                      // Only navigate to the profile if the transaction was successful.
                      PageRouter.gotoWidget(
                          VisitedUserEgoProfilePage(
                              visitedUsersID: thisUserID,
                              visitedEgoName: thisEgoName),
                          context);
                    }
                  } finally {
                    // --- 3. HIDE THE LOADER (GUARANTEED) ---
                    // This runs no matter how the try block exits.
                    if (mounted) {
                      setState(() {
                        _isAvatarLoading = false;
                      });
                    }
                  }
                },
                child: Stack(
                  alignment: AlignmentGeometry.center,
                  children: [
                    CachedNetworkImage(
                        width: 40,
                        height: 40,
                        imageUrl: widget.commentSessionModel?.isUserAdmin == true?
                        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691" :
                        widget.commentSessionModel!.userAvatarUrl ?? '',
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Image.asset(
                          "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                          width: 40,
                          height: 40,
                        )),

                    // --- 2. ADD THE OVERLAY LOADER ---
                    if (_isAvatarLoading)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
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
                        setState(() {
                          _isAvatarLoading = true;
                        });
                        try {
                        widget.visitedUsersID =
                        widget.commentSessionModel?.isUserAdmin == true
                            ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                            : widget.commentSessionModel!.userId ?? '';
                        widget.visitedEgoName =
                        widget.commentSessionModel?.isUserAdmin == true
                            ? "Oh, Yes, It's Me, Claire!"
                            : widget.commentSessionModel!.userNickname ??
                            '';
                        String thisEgoName = widget.visitedEgoName;
                        String thisUserID =
                        widget.commentSessionModel?.isUserAdmin == true
                            ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                            : widget.commentSessionModel!.userId ?? '';
                        UserModel visitingUser = await firebaseServices.getUserInfo();

                        const int visitCost = 1;

                        // --- 2. HANDLE SELF-VISIT ---
                        if (visitingUser.userId == thisUserID) {
                          // If visiting self, just navigate without a transaction.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: thisUserID,
                                  visitedEgoName: thisEgoName),
                              context);
                          return;
                        }

                        // --- 3. CHECK PERMISSIONS & SUFFICIENT LOVES ---
                        if (visitingUser.userType == "REGULAR" &&
                            visitingUser.currentLoveCount < 500) {
                          showToast(
                              "Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
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
                          receiverId: thisUserID,
                          amountToSend: visitCost,
                          taxAmount: 0,
                          totalDebitAmount: visitCost,
                          senderTransactionDesc: "1❤️ for visiting ${thisEgoName}'s Ego.",
                          receiverTransactionDesc:
                          "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                          claireTransactionDesc: "Tax from a profile visit.",
                          forProfileVisits: 1, // Stat for the sender
                          fromProfileVisits: 1, // Stat for the receiver
                          metadata: {
                            'reason': 'profile_visit',
                            'visitedUserId': thisUserID,
                            'from': 'comment_widget'
                          },
                        );

                        // --- 5. NAVIGATE ON SUCCESS ---
                        if (success) {
                          showToast("You are visiting ${thisEgoName} with a kola of 1❤️.");

                          // --- START TARGETED NOTIFICATION LOGIC ---
                          try {
                            // We already have the visiting user's info, now get the visited user's token.
                            final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(thisUserID).get();
                            if (receiverDoc.exists) {
                              final receiverToken = receiverDoc.data()?['fcmId'] as String?;
                              final senderName = visitingUser.nickname ?? 'A user';

                              if (receiverToken != null && receiverToken.isNotEmpty) {
                                await notificationService.sendNotification({
                                  "token": receiverToken,
                                  "notification": {
                                    "title": "Your Ego profile has a visitor!",
                                    "body": "$senderName just visited your profile with a kola of 1❤️."
                                  },
                                  "data": {
                                    // Navigate the user to their own profile page to see the updated stats.
                                    "route": "egoPage"
                                  }
                                });
                              }
                            }
                          } catch (e) {
                            print("Error sending profile visit notification: $e");
                            // Don't block the user flow if notifications fail.
                          }
                          // --- END TARGETED NOTIFICATION LOGIC ---

                          // --- NAVIGATE ---
                          // Only navigate to the profile if the transaction was successful.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: thisUserID,
                                  visitedEgoName: thisEgoName),
                              context);
                        }
                        // If !success, the service method already shows a toast.
                        } finally {
                          // --- 3. HIDE THE LOADER (GUARANTEED) ---
                          // This runs no matter how the try block exits.
                          if (mounted) {
                            setState(() {
                              _isAvatarLoading = false;
                            });
                          }
                        }
                      },
                      child: Text(
                          widget.commentSessionModel!.isUserAdmin == true
                              ? "Claire"
                              : widget.commentSessionModel!.userNickname ?? 'Anon Ego',
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
                    count: widget.commentSessionModel?.thanks?.length ?? 0,
                    onPressed: _handleThanksTransaction,
                    color: _isThanked ? Pallet.colorPrimaryDark : Pallet.colorTextGray,
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
            // Elite UI: Styled link to match a premium iOS feel
            linkStyle: GoogleFonts.plusJakartaSans(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
            text: widget.commentSessionModel!.message!,
            textAlign: TextAlign.justify,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),


          SizedBox(
            height: 8,
          ),

          Visibility(
            visible: widget.commentSessionModel!.imageUrls != null && widget.commentSessionModel!.imageUrls!.isNotEmpty,
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.commentSessionModel!.imageUrls!.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.commentSessionModel!.imageUrls!.length > 2 ? 5 : 2,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemBuilder: (context, index) {
                String imageUrl = widget.commentSessionModel!.imageUrls![index];
                return GestureDetector(
                  onTap: () {
                    PageRouter.gotoWidget(CustomImageWidget(imageUrl: imageUrl), context);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover, // Ensures the image fills the space without distortion
                      placeholder: (context, url) => const Center(child: CupertinoActivityIndicator()),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
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
