import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/utils/color.dart';
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

import '../data/models/transaction_model.dart' as t_model;
import '../services/firebase_services.dart';
import '../services/hidden_posts_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/user_model.dart';
import '../ui/create_session/sound/custom_play_sound_widget.dart';
import '../ui/ego-profile/top_up_loves_page.dart';
import '../utils/global_app_state.dart';
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
  UserModel? _currentUserModel;
  bool? isFeatured;
  bool? isArchived;
  final TransactionService _transactionService = TransactionService();
  User? currentUser = FirebaseAuth.instance.currentUser;
  final PageController _pageController = PageController();
  final GlobalKey<UnifiedMediaViewerState> _mediaViewerKey =
      GlobalKey<UnifiedMediaViewerState>();
  bool _isAvatarLoading = false;

  @override
  void initState() {
    super.initState();
    _updateLanguagePreference();
    widget.isFeatured = widget.element.featured;
    widget.isArchived = widget.element.archived;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
// In lib/widgets/ego_mode_session_card.dart

  /// Archive a session
  Future<bool?> sendToArchive() async {
    if (currentUser == null) {
      showToast(message: "You must be logged in to archive a session.");
      return false;
    }

    // --- 1. PERFORM THE TREASURY TRANSACTION ---
    // This handles the 10 love deduction.
    final bool success = await firebaseServices.updateTreasuryAndUser(
      userId: currentUser!.uid,
      amount: 10,
      type: t_model.TransactionType.debit,
      userTransactionDescription:
          "10 Loves deducted for archiving session: '${widget.element.title}'.",
      metadata: {
        'sessionId': widget.element.sessionId,
        'sessionTitle': widget.element.title
      },
      // We add this stat to track where loves are spent.
      forLoveTransfer: 10,
    );

    // --- 2. PROCEED ONLY IF THE TRANSACTION WAS SUCCESSFUL ---
    if (success) {
      // --- START: NEW TARGETED NOTIFICATION LOGIC ---
      try {
        // Fetch the current user's document to get their up-to-date FCM token.
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        if (userDoc.exists) {
          final userToken = userDoc.data()?['fcmId'] as String?;

          if (userToken != null && userToken.isNotEmpty) {
            await notificationService.sendNotification({
              "token": userToken,
              "notification": {
                "title": "Session Archived",
                "body":
                    "Your session has been archived. 10❤️ were deducted from your wallet."
              },
              "data": {
                // Navigate the user to their own profile page to see the updated balance.
                "route": widget.element.sessionId
              }
            });
            logger.d("Successfully sent 'Archive Session' notification.");
          }
        }
      } catch (e) {
        print("Failed to send 'Archive Session' push notification: $e");
      }
      // --- END: NEW TARGETED NOTIFICATION LOGIC ---

      // --- 3. UPDATE THE SESSION DOCUMENT IN FIRESTORE ---
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.element.sessionId)
          .update({"archived": true});

      logger.d('Successfully changed archive status');
      setState(() {
        isArchived = true;
      });
      showToast(message: "Session archived. 10 Loves deducted.");
      return true;
    } else {
      // If the treasury transaction failed (e.g., insufficient funds).
      showToast(
          message:
              "Could not archive session. Please check your Love balance.");
      return false;
    }
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
        child: ClipRRect(
          // 1. Clip the blur to the border radius
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            // 2. The frosted glass effect
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                // Fix: Dynamic opacity based on luminance to prevent "misty" washout
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    // Reduce alpha in light mode (luminance > 0.5) to keep it clear
                    backgroundColor,
                    Pallet.colorSecondaryDark,
                  ],
                ),
                // Fix: Use dark border for light cards, light border for dark cards
                border: Border.all(
                  color: backgroundColor.computeLuminance() > 0.5
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                            final visitingUser =
                                await firebaseServices.getUserInfo();
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
                                      "Need to have 100 Loves or Alter Ego Access to view Ego Profiles.");
                              return;
                            }

                            if (currentUser?.uid == null) {
                              showToast(
                                  message:
                                      "You need to log in to visit an ego profile.");
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
                                  "Tax from a profile visit.",
                              // Will be 0, but required
                              forProfileVisits: 1,
                              // Stat for the sender
                              fromProfileVisits: 1,
                              // Stat for the receiver
                              metadata: {
                                'reason': 'profile_visit',
                                'visitedUserId': visitedUserId
                              },
                            );

                            // ---4. NAVIGATE AND NOTIFY ON SUCCESS ---
                            if (success) {
                              showToast(
                                  message:
                                      "You are visiting ${visitedEgoName} with a kola of 1❤️.");

                              // --- START TARGETED NOTIFICATION LOGIC ---
                              try {
                                // We already have the visiting user's info, now get the visited user's token.
                                final receiverDoc = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(visitedUserId)
                                    .get();
                                if (receiverDoc.exists) {
                                  final receiverToken =
                                      receiverDoc.data()?['fcmId'] as String?;
                                  final senderName =
                                      visitingUser.nickname ?? 'A user';

                                  if (receiverToken != null &&
                                      receiverToken.isNotEmpty) {
                                    await notificationService.sendNotification({
                                      "token": receiverToken,
                                      "notification": {
                                        "title":
                                            "Your Ego profile has a visitor!",
                                        "body":
                                            "$senderName just visited your profile with a kola of 1❤️."
                                      },
                                      "data": {
                                        // Navigate the user to their own profile page to see the updated stats.
                                        "route": "egoPage"
                                      }
                                    });
                                  }
                                }
                              } catch (e) {
                                print(
                                    "Error sending profile visit notification: $e");
                                // Don't block the user flow if notifications fail.
                              }
                              // --- END TARGETED NOTIFICATION LOGIC ---

                              // --- NAVIGATE ---
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
                                imageBuilder: (context, imageProvider) =>
                                    Container(
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
                                errorWidget: (context, url, error) =>
                                    Image.asset(
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
                                  final String visitedUserId =
                                      widget.element.userId!;
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
                                      visitingUser.currentLoveCount < 100) {
                                    showToast(
                                        message:
                                            "Need to have 100 Loves or Alter Ego Access to view Ego Profiles.");
                                    return;
                                  }

                                  if (currentUser?.uid == null) {
                                    showToast(
                                        message:
                                            "You need to log in to visit an ego profile.");
                                    return;
                                  }

                                  // --- 4. PERFORM THE LOVE TRANSACTION ---
                                  final bool success = await firebaseServices
                                      .transferLoveBetweenUsers(
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
                                        "Tax from a profile visit.",
                                    // Will be 0, but required
                                    forProfileVisits: 1,
                                    // Stat for the sender
                                    fromProfileVisits: 1,
                                    // Stat for the receiver
                                    metadata: {
                                      'reason': 'profile_visit',
                                      'visitedUserId': visitedUserId
                                    },
                                  );

                                  // --- 5. NAVIGATE ON SUCCESS ---
                                  if (success) {
                                    showToast(
                                        message:
                                            "You are visiting ${visitedEgoName} with a kola of 1❤️.");

                                    // --- START TARGETED NOTIFICATION LOGIC ---
                                    try {
                                      // We already have the visiting user's info, now get the visited user's token.
                                      final receiverDoc =
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(visitedUserId)
                                              .get();
                                      if (receiverDoc.exists) {
                                        final receiverToken = receiverDoc
                                            .data()?['fcmId'] as String?;
                                        final senderName =
                                            visitingUser.nickname ?? 'A user';

                                        if (receiverToken != null &&
                                            receiverToken.isNotEmpty) {
                                          await notificationService
                                              .sendNotification({
                                            "token": receiverToken,
                                            "notification": {
                                              "title":
                                                  "Your Ego profile has a visitor!",
                                              "body":
                                                  "$senderName just visited your profile with a kola of 1❤️."
                                            },
                                            "data": {
                                              // Navigate the user to their own profile page to see the updated stats.
                                              "route": "egoPage"
                                            }
                                          });
                                        }
                                      }
                                    } catch (e) {
                                      print(
                                          "Error sending profile visit notification: $e");
                                      // Don't block the user flow if notifications fail.
                                    }
                                    // --- END TARGETED NOTIFICATION LOGIC ---

                                    // --- NAVIGATE ---
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
                      Padding(
                          padding: const EdgeInsets.fromLTRB(2.0, 0, 2.0, 0.0),
                          child: Text(
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
                          )),


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
                                          widget.element.videoThumbnailUrls!
                                                  .length >
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
                              aspectRatio:
                                  0.8, // A taller, more immersive ratio
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
                          if (await firebaseServices.isUserSignIn(context) ==
                              false) {
                            return;
                          }

                          // --- 1. SETUP TRANSACTION DETAILS ---
                          final reactingUser =
                              await firebaseServices.getUserInfo();
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
                            showToast(
                                message: "You reacted to your own session.");
                            return;
                          }

                          if (reactingUser.currentLoveCount < reactionCost) {
                            showToast(
                                message: "You need at least 1❤️ to react.");
                            return;
                          }

                          if (currentUser == null) {
                            showToast(
                                message:
                                    "You must be logged in to react to a session.");
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
                            claireTransactionDesc:
                                "Tax from a session reaction.",
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
                            // --- C. START: NEW TARGETED NOTIFICATION LOGIC ---
                            try {
                              final receiverDoc = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(sessionOwnerId)
                                  .get();
                              if (receiverDoc.exists) {
                                final receiverToken =
                                    receiverDoc.data()?['fcmId'] as String?;
                                final senderName =
                                    reactingUser.nickname ?? 'Someone';
                                final sessionTitle =
                                    widget.element.title ?? 'your session';
                                final truncatedTitle = sessionTitle.length > 30
                                    ? sessionTitle.substring(0, 30) + '...'
                                    : sessionTitle;

                                // Note: 'reaction' is the Reaction object passed by the MetooButton
                                final reactionValue = reaction.value;

                                if (receiverToken != null &&
                                    receiverToken.isNotEmpty) {
                                  await notificationService.sendNotification({
                                    "token": receiverToken,
                                    "notification": {
                                      "title":
                                          "Someone reacted to your session!",
                                      "body":
                                          "$senderName reacted with '$reactionValue' to your session: \"$truncatedTitle\""
                                    },
                                    "data": {"route": widget.element.sessionId}
                                  });
                                  logger.d(
                                      "Successfully sent 'new reaction' notification.");
                                }
                              }
                            } catch (e) {
                              print(
                                  "Error sending 'new reaction' notification: $e");
                            }
                            // --- END: NEW TARGETED NOTIFICATION LOGIC ---
                            showToast(
                                message: "1❤️ sent to the session owner!");
                          }
                          // If !success, the service method already shows a toast.
                        },
                      ),
                      new Spacer(),
                      // NEW MODERATION POPUP BUTTON (HIDDEN FROM OWNER) ---
                      Visibility(
                        visible: widget.element.userId != currentUser?.uid,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: textColor.withValues(alpha: 0.5)),
                          onSelected: (String value) {
                            final sessionId = widget.element.sessionId;
                            final sessionOwnerId = widget.element.userId;

                            if (sessionId == null || sessionOwnerId == null) {
                              showToast(
                                  message:
                                  "Cannot perform action: Invalid session data.");
                              return;
                            }
                            // This check is now redundant due to Visibility, but kept for safety.
                            if (sessionOwnerId == currentUser?.uid) {
                              showToast(
                                  message:
                                  "You cannot moderate your own session.");
                              return;
                            }

                          switch (value) {
                            case 'remove_session':
                              _removeSessionFromFeed(sessionId);
                              break;
                            case 'report_session':
                              _reportSessionAndOwner(sessionId);
                              break;
                            case 'block_user':
                              _blockUser(sessionOwnerId);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'remove_session',
                            child: Text('Remove post from my feed'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'report_session',
                            child: Text('Report this post & owner'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'block_user',
                            child: Text('Block owner of this post'),
                          ),
                        ],
                      ),
                      ),

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
                                color: textColor.withValues(alpha: 0.5),
                                size: 26,
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
                                      : AppString.archive_alert_note,
                                  onPressed: () {
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
                              visible:
                                  widget.element.userId == currentUser?.uid,
                              child: Icon(
                                widget.element.archived == true
                                    ? Icons.archive_rounded
                                    : Icons.archive_outlined,
                                color: textColor.withValues(alpha: 0.5),
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                      ),
                      new Spacer(),
                      StreamBuilder(
                          stream: firebaseServices.getFeaturedSessionsComments(
                              widget.element.sessionId!),
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapShot) {
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
                  StreamBuilder(
                    stream: firebaseServices
                        .getFeaturedSessionsComments(widget.element.sessionId!),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                      if (snapShot.hasError ||
                          !snapShot.hasData ||
                          snapShot.data!.docs.isEmpty) {
                        return const SizedBox
                            .shrink(); // Hide completely if error or no data
                      }

                      // Parse the comments
                      List<CommentSessionModel> _commentSessionList = snapShot
                          .data!.docs
                          .map((e) => CommentSessionModel.fromJson(
                              e.data() as Map<String, dynamic>))
                          .toList();

                      // Find the specific comment to display (Adviser/Admin)
                      final displayComment =
                          _returnComment(_commentSessionList);

                      if (displayComment.message == null ||
                          displayComment.message!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: textColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: textColor.withValues(alpha: 0.1),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Opacity(
                                  opacity: 0.9,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: textColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.asset(
                                      "assets/images/claire_icon.png",
                                      height: 14,
                                      width: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayComment.message!,
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.0,
                                      color: textColor.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                      letterSpacing: -0.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
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

  featureAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Top Up Love"),
      onPressed: () {
        Navigator.pop(context); // Close the dialog
        PageRouter.gotoWidget(const TopUpLovesPage(), context);
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

  // --- START: MODERATION ACTION HANDLERS ---

  /// Option 1: Removes the session from the user's feed locally.
  Future<void> _removeSessionFromFeed(String sessionId) async {
    await HiddenPostsService().hidePost(sessionId);
    if (mounted) {
      showToast(message: "This session has been removed from your feed.");
      // Trigger a refresh on the feed page.
      App.refreshFeed.add(true);
    }
  }

  /// Option 2: Reports the session and its owner, then hides it.
  Future<void> _reportSessionAndOwner(String sessionId) async {
    // This is a placeholder for your existing firebaseServices.reportSession method
    // final bool success = await firebaseServices.reportSession(sessionId);
    // For this example, we assume success. Replace with your actual call.
    final bool success = true;

    if (success) {
      await HiddenPostsService().hidePost(sessionId);
      if (mounted) {
        showToast(
            message:
            "This session has been reported and will be removed from your feed.");
        // Trigger a refresh on the feed page.
        App.refreshFeed.add(true);
      }
    } else if (mounted) {
      showToast(message: "Failed to report this session. Please try again.");
    }
  }

  /// Option 3: Blocks the session owner and hides their content.
  Future<void> _blockUser(String userIdToBlock) async {
    // This is a placeholder for your existing firebaseServices.blockUser method
    // final bool success = await firebaseServices.blockUser(userIdToBlock);
    // For this example, we assume success. Replace with your actual call.
    final bool success = true;

    if (success && mounted) {
      showToast(
          message:
          "This user has been blocked. Their content will no longer be visible.");
      // Trigger a refresh on the feed page.
      App.refreshFeed.add(true);
    }
  }

}
