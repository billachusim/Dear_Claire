import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/ui/featured/ego_mode_session_detail.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:clairediary/widgets/comments_button.dart';
import 'package:clairediary/widgets/metoo_button.dart';
import 'package:clairediary/helpers/toast_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/transaction_model.dart' as t_model;
import '../services/data/notification_model.dart' as push_notification;
import '../services/firebase_services.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/user_model.dart';
import '../ui/create_session/sound/custom_play_sound_widget.dart';
import '../utils/strings.dart';
import '../ui/routes/routes.dart';
import 'unified_media_widget.dart';

class EgoModeSessionCard extends StatefulWidget {
  Session element;
  bool? isFeatured;
  bool? isArchived;

  EgoModeSessionCard(
      {Key? key,
      required this.element,
      required this.visitedUsersID,
      required this.visitedEgoName})
      : super(key: key);
  late String visitedUsersID;
  late String visitedEgoName;

  @override
  State<EgoModeSessionCard> createState() => _EgoModeSessionCardState();
}

class _EgoModeSessionCardState extends State<EgoModeSessionCard> {
  bool? isFeatured;
  bool? isArchived;
  final TransactionService _transactionService = TransactionService();
  User? currentUser = FirebaseAuth.instance.currentUser;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final GlobalKey<UnifiedMediaViewerState> _mediaViewerKey =
      GlobalKey<UnifiedMediaViewerState>();
  bool _isAvatarLoading = false;

  @override
  void initState() {
    super.initState();
    widget.isFeatured = widget.element.featured;
    widget.isArchived = widget.element.archived;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Edit feature

  Future<bool?> setToFeatured() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.element.sessionId)
        .update(
      {
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
        .update(
      {
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

    if (currentUser != null) {
      // --- NEW TREASURY LOGIC ---
      // A single, safe call to the new centralized method.
      // It handles the user's debit, Claire's credit, and the transaction recording.
      await firebaseServices.updateTreasuryAndUser(
        userId: currentUser!.uid,
        amount: 10,
        type: t_model.TransactionType.debit,
        userTransactionDescription:
            "10 Loves deducted for archiving a session.",
        metadata: {
          'sessionId': widget.element.sessionId,
          'sessionTitle': widget.element.title
        },
      );
      // --- END OF NEW TREASURY LOGIC ---

      // --- Send Push Notification ---
      try {
        final notificationModel = push_notification.NotificationModel(
            topic: currentUser!.uid, // Send to the user's personal topic
            data: push_notification.Data(id: currentUser!.uid, route: 'wallet'),
            notification: push_notification.Notification(
                title: "Session Archived",
                body: "Your session has been archived. 10 ❤️ were deducted."));
        await notificationService.sendNotification(notificationModel.toJson());
      } catch (e) {
        print("Failed to send 'Archive Session' push notification: $e");
      }
      // --- End of Push Notification ---
    }

    // This part remains the same: update the session document itself.
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.element.sessionId)
        .update({
      "archived": value,
    });

    logger.d('Successfully changed archive');
    print('Is Archived?: $value');
    isArchived = value;
    showToast(message: "Session archived. 10 Loves deducted.");

    return value;
  }

  Future<bool?> removeFromArchive() async {
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.element.sessionId)
        .update(
      {
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
    final Color backgroundColor = HexColor.fromHex(widget.element.colorHex!);
    final Color textColor =
        backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black54
        : Colors.white70;

    return GestureDetector(
      onTap: () {
        // This tap is for the whole card.
        // We first check if a video is playing. If so, pause it.
        // If not, navigate to the detail page.
        final bool didPause =
            _mediaViewerKey.currentState?.pauseAllVideos() ?? false;

        // If a video was NOT paused by this tap, then proceed with navigation.
        if (!didPause) {
          PageRouter.gotoWidget(
              EgoModeSessionDetail(featuredSessionModel: widget.element),
              context);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25), color: backgroundColor),
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
                      final visitingUser = await firebaseServices.getUserInfo();
                      final String visitedUserId = widget.element.userId!;
                      final String visitedEgoName =
                          widget.element.userNickname!;
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
                        showToast(
                            message:
                                "Need up to 500 Loves in Wallet or Alter Ego Access to view other Ego Profiles.");
                        return;
                      }

                      if (visitingUser.currentLoveCount < visitCost) {
                        showToast(
                            message:
                                "You need at least 1 ❤️ to visit a profile.");
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
                        claireTransactionDesc: "Tax from a profile visit.",
                        // Will be 0, but required
                        forRoomVisits: 1,
                        // Stat for the sender
                        fromRoomVisits: 1,
                        // Stat for the receiver
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
                          width: 50,
                          height: 50,
                          imageUrl: widget.element.userAvatarUrl!,
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
                                width: 50,
                                height: 50,
                              )),

                      // --- 2. ADD THE OVERLAY LOADER ---
                      if (_isAvatarLoading)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
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
                  width: 8,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // --- 1. SHOW THE LOADER ---
                          setState(() {
                            _isAvatarLoading = true;
                          });
                          try {
                            // --- 1. SETUP TRANSACTION DETAILS ---
                            final visitingUser =
                            await firebaseServices.getUserInfo();
                            final String visitedUserId = widget.element.userId!;
                            final String visitedEgoName =
                            widget.element.userNickname!;
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
                                visitingUser.currentLoveCount < 500) {
                              // Changed from 50 to 500 for consistency
                              showToast(
                                  message:
                                  "Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                              return;
                            }

                            if (visitingUser.currentLoveCount < visitCost) {
                              showToast(
                                  message:
                                  "You need at least 1 ❤️ to visit a profile.");
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
                              "1❤️ from ${visitingUser
                                  .nickname} visiting your Ego.",
                              claireTransactionDesc:
                              "Tax from a profile visit.",
                              // Will be 0, but required
                              forRoomVisits: 1,
                              // Stat for the sender
                              fromRoomVisits: 1,
                              // Stat for the receiver
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
                        child: Text(widget.element.userNickname!,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 18.0,
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
                      Text(
                          Mood.getMood(widget.element.moodId) ??
                              "${Mood.getMood(1)}",
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: textColor,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 3,
                      ),
                      Text(
                        widget.element.location ?? "",
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 8,
            ),
            Center(
              child: Text(widget.element.title!,
                  textAlign: TextAlign.center,
                  maxLines: widget.element.imageUrls!.isNotEmpty ? 1 : 2,
                  style: GoogleFonts.lato(
                      fontSize: 24.0,
                      color: textColor,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 7,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2.0, 0, 2.0, 0.0),
                  child: Text(
                    widget.element.message!,
                    textAlign: TextAlign.justify,
                    maxLines: (widget.element.imageUrls?.isNotEmpty ?? false) ||
                            (widget.element.videoUrls?.isNotEmpty ?? false)
                        ? 2
                        : 7,
                    style: GoogleFonts.lato(
                        fontSize: 18.0,
                        color: textColor,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(
                  height: 7,
                ),

                // +++++++++++++ UNIFIED MEDIA VIEWER +++++++++++++

                if ((widget.element.imageUrls?.isNotEmpty ?? false) ||
                    (widget.element.videoUrls?.isNotEmpty ?? false))
                  Builder(builder: (context) {
                    // Create a unified list of all media items.
                    final List<MediaItem> allMedia = [];

                    // Add images to the list.
                    if (widget.element.imageUrls != null) {
                      for (var imageUrl in widget.element.imageUrls!) {
                        allMedia.add(MediaItem(
                            networkUrl: imageUrl, type: MediaType.image));
                      }
                    }

                    // Add videos to the list.
                    if (widget.element.videoUrls != null) {
                      for (int i = 0;
                          i < widget.element.videoUrls!.length;
                          i++) {
                        final videoUrl = widget.element.videoUrls![i];
                        final thumbnailUrl =
                            (widget.element.videoThumbnailUrls != null &&
                                    widget.element.videoThumbnailUrls!.length >
                                        i)
                                ? widget.element.videoThumbnailUrls![i]
                                : '';
                        allMedia.add(MediaItem(
                            networkUrl: videoUrl,
                            thumbnailUrl: thumbnailUrl,
                            type: MediaType.video));
                      }
                    }

                    return GestureDetector(
                      onTap: () {},
                      child: UnifiedMediaViewer(
                        key: _mediaViewerKey,
                        mediaItems: allMedia,
                        aspectRatio: 0.8, // A taller, more immersive ratio
                      ),
                    );
                  }),

                // End of Unified Media Viewer

                // Audio is here
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    child: widget.element.audioUrl!.isNotEmpty
                        ? CustomPlaySoundWidget(
                            filePath: widget.element.audioUrl)
                        : SizedBox.shrink(),
                  ),
                ),
              ],
            ),

            // End of Audio Player

            // MeToo Button is here
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
                      showToast(message: "You need at least 1 ❤️ to react.");
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
                      saveUserMe2Activity(); // Your existing activity tracking
                      showToast(message: "1❤️ sent to the session owner!");
                    }
                    // If !success, the service method already shows a toast.
                  },
                ),
                new Spacer(),
                Visibility(
                  visible: widget.element.userId == currentUser?.uid,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.element.featured == false)
                        featureAlertDialog(context);
                      else
                        unfeatureAlertDialog(context);
                    },
                    child: Container(
                      child: Visibility(
                        visible: widget.element.repliesEnabled == true,
                        child: Icon(
                          widget.element.featured == true
                              ? Icons.lightbulb
                              : Icons.lightbulb_outline,
                          color: textColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Visibility(
                  visible: widget.element.userId == currentUser?.uid,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.element.archived == false)
                        showCustomDialog(context,
                            message: widget.element.archived == true
                                ? AppString.unarchive_alert_note
                                : AppString.archive_alert_note, onPressed: () {
                          sendToArchive();
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.diarySessions);
                        });
                      else
                        showCustomDialog(context,
                            message: widget.element.archived == false
                                ? AppString.archive_alert_note
                                : AppString.unarchive_alert_note,
                            onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.diarySessions);
                          removeFromArchive();
                        });
                    },
                    child: Container(
                      child: Visibility(
                        visible: widget.element.userId == currentUser?.uid,
                        child: Icon(
                          widget.element.archived == true
                              ? Icons.archive_rounded
                              : Icons.archive_outlined,
                          color: textColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
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
                              EgoModeSessionDetail(
                                  featuredSessionModel: widget.element),
                              context),
                        );
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
                            fontSize: 13.0,
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
              _commentSessionList.isNotEmpty && element.isUserAdmin)
          .toList();
      return _filter.first;
    } catch (e) {
      return CommentSessionModel();
    }
  }

  onDonateClicked() {
    var donateUrl = Uri.parse(AppString.donate_url);
    launchUrl(donateUrl);
  }

  featureAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("TopUp Love"),
      onPressed: () {
        onDonateClicked();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Request Feature\n"
          "Cost: 1,000+ Loves"),
      onPressed: () {
        // setToFeatured();
        Navigator.pushReplacementNamed(context, AppRoutes.requestFeatureForm,
            arguments: widget.element);
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
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Unfeature"),
      onPressed: () {
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
    final sessionId = widget.element.sessionId;
    final sessionOwnerId = widget.element.userId;
    final sessionOwnerAvatar = widget.element.userAvatarUrl.toString();
    final sessionOwnerNickname = widget.element.userNickname.toString();
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
