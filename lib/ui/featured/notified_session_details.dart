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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/firebase_services.dart';
import '../../../services/user_model.dart';
import '../../../utils/strings.dart';
import '../../Admob/ad_state.dart';
import '../../data/models/transaction_model.dart' as t_model;
import '../../services/data/notification_model.dart' as push_notification;
import '../../services/native_gallery_saver.dart';
import '../../services/notification_service.dart';
import '../../widgets/chat_edit_field.dart';
import '../../widgets/comment_widget.dart';
import '../../widgets/toast.dart';
import '../../widgets/unified_media_widget.dart';
import '../Categories/similar_category_sessions.dart';
import '../create_session/sound/custom_play_sound_widget.dart';
import '../routes/page_router_animation.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'model/comment_session_model.dart';


class NotifiedSessionDetails extends StatefulWidget {
  NotifiedSessionDetails({Key? key, required this.sessionId}) : super(key: key);
  String? sessionId;

  @override
  _NotifiedSessionDetailsState createState() => _NotifiedSessionDetailsState();
}

class _NotifiedSessionDetailsState extends State<NotifiedSessionDetails> {
  final screenshotController = ScreenshotController();
  TextEditingController editSessionController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  UserModel? _currentUserModel;
  bool? isFeatured;
  late String visitedUsersID;
  late String visitedEgoName;
  //initialize the audio record file that stores user audio record. null by default
  String? recordFile;
  Session? theSession;
  bool? isFlagged;
  bool? isArchived;
  int _currentPage = 0;
  final GlobalKey<UnifiedMediaViewerState> _mediaViewerKey = GlobalKey<UnifiedMediaViewerState>();
  bool _isAvatarLoading = false;
  late Future<UserModel> _userFuture;

  List<CommentSessionModel> _commentList = [];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Admob Ad Units.
  late BannerAd egoModeSessionDetailBottomBanner;
  bool _isBannerAdInitialized = false;


  @override
  void initState() {
    super.initState();
    _updateLanguagePreference();
    _createAdviseInterstitialAd();
    _userFuture = firebaseServices.getUserInfo();
  }



  @override
  void dispose() {
    _showAdviseInterstitialAd();
    _interstitialAd?.dispose();
    egoModeSessionDetailBottomBanner.dispose();
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


  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  /// Create new sub chat interstitial ad.
  void _createAdviseInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/9839548530"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/8291211887"
          : '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createAdviseInterstitialAd();
          }
        },
      ),
    );
  }

  void _showAdviseInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; // Prevent showing the same ad twice
    }
  }





  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerAdInitialized) {
      final adState = Provider.of<AdState>(context);
      adState.initialization.then((status) {
        if (mounted) { // Ensure widget is still in the tree
          setState(() {
            egoModeSessionDetailBottomBanner = BannerAd(
                size: AdSize.banner,
                adUnitId: adState.egoModeBottomCommentBannerAdUnitId,
                request: const AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) => print('Notified session banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print('Notified session banner failed to load: $error');
                    ad.dispose();
                  },
                ))
              ..load();
            _isBannerAdInitialized = true;
          });
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    final Color backgroundColor = Theme.of(context).cardColor;
    final Color textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Notified Session", style: TextStyle(color: textColor)),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: GestureDetector(
        onTap: () {
          // Hide keyboard when tapping outside of a text field
          FocusScope.of(context).unfocus();
        },
        child: Stack(
        children: [
          ListView(
          children: [
            Screenshot(
            controller: screenshotController,
            child: Material(
              child: GestureDetector(
                onTap: () {
                  // This tap is for the whole card.
                  // We first check if a video is playing. If so, pause it.
                  // If not, navigate to the detail page.
                  final bool didPause = _mediaViewerKey.currentState?.pauseAllVideos() ?? false;

                  // If a video was NOT paused by this tap, do something else.
                  if (!didPause) {

                  }
                },
                child: SafeArea(
                  child: StreamBuilder(
                      stream: firebaseServices.getSingleDocument(id: widget.sessionId),
                      builder: (context,
                          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
                        if (snaps.hasData) {
                          final _session = Session.fromJson(snaps.data!.data()!);
                          theSession = _session;
                          final Color backgroundColor =
                          HexColor.fromHex(_session.colorHex!);
                          final Color textColor =
                          backgroundColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white;
                          final Color secondaryTextColor =
                          backgroundColor.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 7),
                            decoration: BoxDecoration(color: backgroundColor),
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
                                          final String visitedUserId = _session.userId!;
                                          final String visitedEgoName =
                                          _session.userNickname!;
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
                                            claireTransactionDesc: "Tax from a profile visit.",
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

                                          // --- 4. NAVIGATE ON SUCCESS ---
                                          if (success) {
                                            showToast("You are visiting ${visitedEgoName} with a kola of 1❤️.");

                                            // --- START TARGETED NOTIFICATION LOGIC ---
                                            try {
                                              // We already have the visiting user's info, now get the visited user's token.
                                              final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(visitedUserId).get();
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
                                              imageUrl: _session.userAvatarUrl!,
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
                                              width: 60,
                                              height: 60,
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
                                              visitedUsersID = _session.userId!;
                                              visitedEgoName = _session.userNickname!;
                                              String thisEgoName =
                                              _session.userNickname.toString();
                                              String thisUser =
                                              _session.userId.toString();
                                              UserModel user =
                                              await firebaseServices.getUserInfo();
                                              if (user.userType != "REGULAR") {
                                                PageRouter.gotoWidget(
                                                    VisitedUserEgoProfilePage(
                                                        visitedUsersID: thisUser,
                                                        visitedEgoName: thisEgoName),
                                                    context);
                                              } else if (user.currentLoveCount > 500) {
                                                PageRouter.gotoWidget(
                                                    VisitedUserEgoProfilePage(
                                                        visitedUsersID: thisUser,
                                                        visitedEgoName: thisEgoName),
                                                    context);
                                              } else {
                                                showToast(
                                                    "Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                                              }
                                              print(
                                                  "Visited User ID::: $visitedUsersID");
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
                                  child: Text(
                                    // Check for and use the translated title if available
                                    (_currentUserModel?.languagePreference != null &&
                                        _session.translatedTitle != null &&
                                        _session.translatedTitle!.containsKey(_currentUserModel!.languagePreference))
                                        ? _session.translatedTitle![_currentUserModel!.languagePreference]!
                                        : _session.title!,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 26.0,
                                      color: textColor,
                                      fontWeight: FontWeight.w800, // Extra Bold
                                      height: 1.1,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 13,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText.rich(
                                        TextSpan(
                                          text: (_currentUserModel?.languagePreference != null &&
                                              _session.translatedSession != null &&
                                              _session.translatedSession!
                                                  .containsKey(_currentUserModel!.languagePreference))
                                              ? _session.translatedSession![_currentUserModel!.languagePreference]!
                                              : _session.message!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20.0,
                                            color: textColor.withValues(alpha: 0.9),
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                        textAlign: TextAlign.justify,
                                        onTap: () {
                                          // This area remains unchanged.
                                        },
                                        contextMenuBuilder: (context, editableTextState) {
                                          return AdaptiveTextSelectionToolbar.buttonItems(
                                            anchors: editableTextState.contextMenuAnchors,
                                            buttonItems: editableTextState.contextMenuButtonItems,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),


                                // +++++++++++++ UNIFIED MEDIA VIEWER +++++++++++++

                                if ((_session.imageUrls?.isNotEmpty ?? false) || (_session.videoUrls?.isNotEmpty ?? false))
                                  Builder(
                                      builder: (context) {
                                        // Create a unified list of all media items.
                                        final List<MediaItem> allMedia = [];

                                        // Add images to the list.
                                        if (_session.imageUrls != null) {
                                          for (var imageUrl in _session.imageUrls!) {
                                            allMedia.add(MediaItem(networkUrl: imageUrl, type: MediaType.image));
                                          }
                                        }

                                        // Add videos to the list.
                                        if (_session.videoUrls != null) {
                                          for (int i = 0; i < _session.videoUrls!.length; i++) {
                                            final videoUrl = _session.videoUrls![i];
                                            final thumbnailUrl = (_session.videoThumbnailUrls != null && _session.videoThumbnailUrls!.length > i)
                                                ? _session.videoThumbnailUrls![i]
                                                : '';
                                            allMedia.add(MediaItem(networkUrl: videoUrl, thumbnailUrl: thumbnailUrl, type: MediaType.video));
                                          }
                                        }

                                        return GestureDetector(
                                          onTap: () {},
                                          child: UnifiedMediaViewer(
                                            key: _mediaViewerKey,
                                            mediaItems: allMedia,
                                            aspectRatio: 0.6, // A taller, more immersive ratio
                                          ),
                                        );
                                      }
                                  ),

                                // End of Unified Media Viewer

                                // Audio is here

                                SizedBox(
                                  height: 7,
                                ),
                                Container(
                                  child: _session.audioUrl!.isNotEmpty
                                      ? CustomPlaySoundWidget(
                                      filePath: _session.audioUrl)
                                      : SizedBox.shrink(),
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
                                      color: textColor,
                                      session: _session,
                                      onReactionChanged: (reaction, index) async {
                                        if (await firebaseServices.isUserSignIn(context) == false) {
                                          return;
                                        }

                                        // --- 1. SETUP TRANSACTION DETAILS ---
                                        final reactingUser = await firebaseServices.getUserInfo();
                                        final String reactingUserId = reactingUser.userId!;
                                        final String sessionOwnerId = _session.userId!;
                                        const int reactionCost = 1;

                                        // --- 2. PREVENT SELF-REACTION & INSUFFICIENT LOVES ---
                                        if (reactingUserId == sessionOwnerId) {
                                          // User is reacting to their own post, just update the reaction locally.
                                          firebaseServices.addUsersReactionToASessionByIndex(
                                            context,
                                            index,
                                            session: _session,
                                            sender: reactingUser.nickname ?? '',
                                          );
                                          showToast("You reacted to your own session.");
                                          return;
                                        }

                                        if (reactingUser.currentLoveCount < reactionCost) {
                                          showToast("You need at least 1 ❤️ to react.");
                                          return;
                                        }

                                        // --- 3. PERFORM THE LOVE TRANSACTION ---
                                        final bool success = await firebaseServices.transferLoveBetweenUsers(
                                          senderId: reactingUserId,
                                          receiverId: sessionOwnerId,
                                          amountToSend: reactionCost,
                                          taxAmount: 0, // No tax on a 1-love transaction
                                          totalDebitAmount: reactionCost,
                                          senderTransactionDesc: "1❤️ for reacting to session ${_session.title}.",
                                          receiverTransactionDesc: "1❤️ from a reaction to your session by ${reactingUser.nickname}.",
                                          claireTransactionDesc: "Tax from a session reaction.",
                                          forReactions: reactionCost,
                                          fromReactions: reactionCost,
                                          metadata: {
                                            'reason': 'session_reaction',
                                            'sessionId': _session.sessionId,
                                            'reactionIndex': index
                                          },
                                        );

                                        // --- 4. HANDLE SUCCESS (UPDATE DB, NOTIFY, LOG ACTIVITY) ---
                                        if (success) {
                                          // A. Update the reaction array in Firestore
                                          firebaseServices.addUsersReactionToASessionByIndex(
                                            context,
                                            index,
                                            session: _session,
                                            sender: reactingUser.nickname ?? '',
                                          );

                                          // B. Save the user activity
                                          saveUserMe2Activity(); // Your existing activity tracking

                                          // --- C. START: NEW TARGETED NOTIFICATION LOGIC ---
                                          try {
                                            final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(sessionOwnerId).get();
                                            if (receiverDoc.exists) {
                                              final receiverToken = receiverDoc.data()?['fcmId'] as String?;
                                              final senderName = reactingUser.nickname ?? 'Someone';
                                              final sessionTitle = _session.title ?? 'your session';
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
                                                    "route": _session.sessionId
                                                  }
                                                });
                                                logger.d("Successfully sent 'new reaction' notification.");
                                              }
                                            }
                                          } catch (e) {
                                            print("Error sending 'new reaction' notification: $e");
                                          }
                                          // --- END: NEW TARGETED NOTIFICATION LOGIC ---

                                          // D. Show confirmation to the user
                                          showToast("1❤️ sent to the session owner!");
                                        }
                                        // If !success, the service method already shows a toast.
                                      },
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
                                          Text(
                                            _session.followers!.length.toString(),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Icon(
                                            _session.followers!
                                                .contains(currentUser?.uid)
                                                ? Icons
                                                .notifications_active_rounded
                                                : Icons
                                                .notifications_off_outlined,
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
                                        if (await firebaseServices
                                            .isUserSignIn(context)) {
                                          final follower = await firebaseServices
                                              .getUserInfo();
                                          final sessionOwnerId = _session.userId;
                                          final isAlreadyFollowing = _session
                                              .followers!
                                              .contains(currentUser?.uid);
                                          if (isAlreadyFollowing) {
                                            firebaseServices.followThisSession(
                                                context,
                                                session: _session);
                                            showToast(
                                                "You've unfollowed this session.");
                                            return; // Stop here
                                          }
                                          if (follower.currentLoveCount < 1) {
                                            showToast(
                                                "You need at least 1❤️ to follow a session.");
                                            return;
                                          }

                                          final bool success =
                                          await firebaseServices
                                              .transferLoveBetweenUsers(
                                            senderId: follower.userId!,
                                            receiverId: sessionOwnerId!,
                                            amountToSend: 1,
                                            taxAmount: 0, // No tax for following
                                            totalDebitAmount: 1,
                                            senderTransactionDesc:
                                            "1❤️ to follow '${_session.title}'.",
                                            receiverTransactionDesc:
                                            "1❤️ from followed session '${_session.title}'.",
                                            claireTransactionDesc:
                                            "Follow transaction tax (0%).",
                                            metadata: {
                                              'reason': 'follow_session',
                                              'sessionId': _session.sessionId,
                                            },
                                          );

                                          if (success) {
                                            firebaseServices.followThisSession(
                                                context,
                                                session: _session);
                                            await firebaseServices
                                                .updateSessionLastTimeActivity(
                                                _session.sessionId
                                                    .toString());

                                            await firebaseServices
                                                .saveUserActivity(
                                              activityType: 'follow',
                                              activityMessage:
                                              "${follower.nickname} followed the session: '${_session.title}'.",
                                              recipientId: sessionOwnerId,
                                              recipientNickname:
                                              _session.userNickname,
                                              sessionId: _session.sessionId,
                                            );

                                            try {
                                              await notificationService.sendNotification(
                                                  push_notification.NotificationModel(
                                                      topic: sessionOwnerId,
                                                      data: push_notification.Data(id: sessionOwnerId, route: _session.sessionId.toString()),
                                                      notification: push_notification.Notification(
                                                          title: "Someone reacted to your session!",
                                                          body: "Someone reacted to your session with 1❤️."
                                                      )
                                                  ).toJson()
                                              );
                                            } catch (e) {
                                              print("Failed to send profile visit notification: $e");
                                              // Do not block navigation if notification fails
                                            }

                                            showToast(
                                                "Now following! 1❤️ was sent to the author.");
                                          } else {
                                            showToast(
                                                "Could not complete the follow. Please try again.");
                                          }
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

                                          return Visibility(
                                            visible: userType == "SUPER_ADMIN",
                                            child: GestureDetector(
                                              onTap: () {
                                                if (_session.featured == false)
                                                  modFeatureAlertDialog(context);
                                                else
                                                  unfeatureAlertDialog(context);
                                              },
                                              child: Container(
                                                child: Visibility(
                                                  visible:
                                                  _session.repliesEnabled == true,
                                                  child: Icon(
                                                    _session.featured == true
                                                        ? Icons.lightbulb
                                                        : Icons.lightbulb_outline,
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

                                              return Visibility(
                                                visible: userType == "SUPER_ADMIN",
                                                child: Visibility(
                                                  visible: _session.flagged == true,
                                                  child: Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          if (_session.archived ==
                                                              false)
                                                            showCustomDialog(context,
                                                                message: _session
                                                                    .archived ==
                                                                    true
                                                                    ? AppString
                                                                    .unarchive_alert_note
                                                                    : AppString
                                                                    .archive_alert_note,
                                                                onPressed: () {
                                                                  sendToArchive();
                                                                  Navigator.of(context)
                                                                      .pop();
                                                                  setState(() {});
                                                                });
                                                          else
                                                            showCustomDialog(context,
                                                                message: _session
                                                                    .archived ==
                                                                    false
                                                                    ? AppString
                                                                    .archive_alert_note
                                                                    : AppString
                                                                    .unarchive_alert_note,
                                                                onPressed: () {
                                                                  removeFromArchive();
                                                                  Navigator.of(context)
                                                                      .pop();
                                                                  setState(() {});
                                                                });
                                                        },
                                                        child: Container(
                                                          child: Icon(
                                                            _session.archived == true
                                                                ? Icons.archive_rounded
                                                                : Icons
                                                                .archive_outlined,
                                                            color:
                                                            Pallet.colorSecondary,
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
                                                                color: Pallet
                                                                    .colorSecondary,
                                                              ),
                                                              SizedBox(
                                                                width: 2,
                                                              ),
                                                              Text(
                                                                'MOD',
                                                                style: GoogleFonts.lato(
                                                                    fontSize: 14.0,
                                                                    color: Pallet
                                                                        .colorSecondary,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .w800),
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
            ),
          ),



            AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics:
                BouncingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                itemCount: 1,
                itemBuilder: (BuildContext c, int i) {
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    delay: Duration(milliseconds: 500),
                    child: SlideAnimation(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.linearToEaseOut,
                      horizontalOffset: 100,
                      verticalOffset: 350.0,
                      child: FlipAnimation(
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeInCubic,
                        flipAxis: FlipAxis.y,

                        child: StreamBuilder(
                            stream: firebaseServices.getFeaturedSessionsComments(
                                widget.sessionId.toString()),
                            builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                              if (snapShot.hasError) {
                                return Container();
                              }

                              if (snapShot.hasData) {
                                _commentList.clear();

                                /// clear list
                                snapShot.data!.docs
                                    .map((e) => _commentList
                                    .add(CommentSessionModel.fromJson(e.data())))
                                    .toList();
                                return Column(

                                  children: [

                                    ..._commentList
                                        .map((element) => CommentWidget(
                                      commentSessionModel: element,
                                      // onPressed is now removed.
                                      onShare: () => _share(element.message),
                                      featuredSessionModel: theSession!,
                                      userId: theSession!.userId.toString(),
                                    ))
                                        .toList(),

                                    SizedBox(height: 4,),
                                    Text(
                                      "Check the next sessions from same category - " + theSession!.category1.toString(),
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),

                                    SimilarCategorySessions(element: theSession!,),
                                  ],
                                );
                              }
                              return Container();
                            }
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              height: 120,
            )

          ]
        ),

          if (egoModeSessionDetailBottomBanner != null && _isBannerAdInitialized)
            Positioned(
              bottom: 60, // Position above the ChatEditField
              left: 0,
              right: 0,
              child: Container(
                height: egoModeSessionDetailBottomBanner.size.height.toDouble(),
                width: egoModeSessionDetailBottomBanner.size.width.toDouble(),
                child: AdWidget(ad: egoModeSessionDetailBottomBanner),
                alignment: Alignment.center,
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: FutureBuilder<UserModel>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Or a loading indicator
                }

                bool hasPermission = false;

                // First, check if the current user is the owner of the session.
                final isSessionOwner = theSession?.userId == currentUser?.uid;

                if (isSessionOwner) {
                  // If the user is the owner, they always have permission.
                  hasPermission = true;
                } else if (snapshot.hasData) {
                  // If not the owner, check the user's role.
                  final user = snapshot.data!;
                  final userType = user.userType ?? '';
                  final hasRequiredRole = ['ADMIN', 'SUPER_ADMIN'].contains(userType);
                  hasPermission = hasRequiredRole;
                }
                // If the user is not the owner and user data fails to load, hasPermission remains false.

                // Also allow commenting if replies are explicitly enabled for everyone
                // or if the user is the designated respondent.
                final canCommentBySessionRules = (theSession?.repliesEnabled == true) ||
                    (theSession?.respondentUserId == currentUser?.uid);

                final bool finalCanComment = hasPermission || canCommentBySessionRules;

                return ChatEditField(
                  canComment: finalCanComment,
                  onTap: (String comment, String voiceNote, String image1, String image2) {
                    if (finalCanComment) {
                      _sendComment(comment, voiceNote, theSession!, image1, image2);
                    }
                  },
                );
              },
            ),
          )


        ]
      ),
    ),
    );
  }




  void _sendComment(String comment, String voiceNote, Session session, String image1, String image2) async {
    if (!await firebaseServices.isUserSignIn(context)) return;


    CollectionReference ref =
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId!)
        .collection("comments");

    String docId = ref.doc().id;

    final _userModel = await firebaseServices.getUserInfo();
    final _commentModel = CommentSessionModel(
        alterEgoId: _userModel.alterEgoId,
        audioUrl: voiceNote,
        commentId: docId,
        flagged: session.flagged!,
        imageUrls: [],
        image1: image1,
        image2: image2,
        thanks: [],
        numberOfThanks: 0,
        isUserAdmin: false,
        message: comment,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname:  _userModel.nickname);

    await ref.doc(docId).set(_commentModel.toJson());


    firebaseServices.addCommentNotification(
      title: session.title ?? '',
      docId: session.sessionId!,
      sender: "Someone",
    );

    updateSessionTimeLastActivity(session);
    isOriginalAdvise(context, comment, session);
    saveUserCommentActivity();
    firebaseServices.followAdvisedSessionImmediately(session);
  }



  String timeAgo() {
    final commentTime = theSession!.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    return _time;
  }

  /// checks if advise meets original advise rules...
  /// if it does, then increment necessary counts.
  Future<bool> isOriginalAdvise(BuildContext context, String adviseText,
      Session session) async {
    final _timeAgo = timeAgo();
    final _advise = adviseText.toString();
    final _length = _advise.length;

    if (!_timeAgo.contains('day') && _advise.contains("arling") &&
        _length >= 20) {

      incrementAdviseCount();

      if (currentUser != null) {
        // --- NEW TREASURY LOGIC ---
        // A single, safe call to the new centralized method.
        final bool wasApproved = await firebaseServices.updateTreasuryAndUser(
          userId: currentUser!.uid,
          amount: 10,
          type: t_model.TransactionType.credit,
          userTransactionDescription: "10 Loves received for an original advise.",
          metadata: {'sessionId': session.sessionId},
        );

        // Check if the transaction was approved or is pending
        if (!wasApproved) {
          // If the treasury was too low, the transaction is now pending.
          showToast("Your reward of 10 Loves is pending admin approval.");
          // We don't send a push notification here because the reward isn't confirmed.
          return true; // Exit the function gracefully.
        }
        // --- END OF NEW TREASURY LOGIC ---


        // --- Send Push Notification (Only if approved) ---
        try {
          final notificationModel = push_notification.NotificationModel(
              topic: currentUser!.uid, // Send to the user's personal topic
              data: push_notification.Data(id: currentUser!.uid, route: 'wallet'),
              notification: push_notification.Notification(
                  title: "You've Earned Love!",
                  body: "You received 10 ❤️ for posting an original advise."));
          await notificationService.sendNotification(notificationModel.toJson());
        } catch (e) {
          print("Failed to send 'Original Advise' push notification: $e");
        }
      }

      showToast("Thanks! You earned 10 Loves.");

      // This local notification is still useful for immediate UI feedback.
      flutterLocalNotificationsPlugin.show(
          0,
          'ClaireLove Wallet',
          "Thanks for that original advise. You just earned 10 Loves.",
          _notificationDetails(),
          payload: "wallet");

      Future.delayed(Duration(seconds: 5), () {
        _showAdviseInterstitialAd();
      });
      return true;
    }
    return false;
  }



  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.high,
      playSound: true);

  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name,
            color: Pallet.colorPrimary,
            playSound: true,
            icon: '@drawable/claire_icon',
            enableLights: true,
            enableVibration: true,
            showWhen: true,
            channelShowBadge: true),
        iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true));
  }



  /// Increase advise counter when user creates new comment.

  Future<void> incrementAdviseCount() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser?.uid)
        .set({
      "adviseCount": FieldValue.increment(1),
    },
      SetOptions(merge: true),
    );
    logger.d('Increased advise count');
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


  /// Save user comment activity

  Future<void> saveUserCommentActivity() async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = _user.nickname.toString();
    final sessionVisitorAvatar =  _user.userType != "REGULAR"
        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
        : _user.avatarUrl.toString();
    final activityMessage = "$sessionVisitorNickname commented on $sessionOwnerNickname's session.";
    final activityType = "comment";
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
    logger.d('Successfully saved your comment activity');
    print('Activity Message: $activityMessage');

  }



  /// Save user comment activity

  Future<void> saveUserThanksActivity(CommentSessionModel commentSessionModel) async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final CommentSessionModel? theComment = commentSessionModel;
    final dateCreated = FieldValue.serverTimestamp();
    final commentOwnerNickname = theComment?.isUserAdmin == true? "Claire" : theComment?.userNickname.toString();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = _user.nickname.toString();
    final sessionVisitorAvatar =  _user.userType != "REGULAR"
        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
        : _user.avatarUrl.toString();
    final activityMessage = "$sessionVisitorNickname thanked $commentOwnerNickname's advise.";
    final activityType = "thank";
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
    logger.d('Successfully saved your thanks activity');
    print('Activity Message: $activityMessage');

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
    logger.d('Successfully updated time of last activity');
  }


  _share(String? message) {
    String _message = '''
    And here is the advise from Claire:
    
     $message  
    ''';
    shareAdvise(_message);
  }

  /// share advise
  void shareAdvise(String message) {
    Share.share(
        '${AppString.shareAdviseHeader}${theSession?.title}\n\n$message\n${AppString.shareLink}');
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            title: Container(
              child: Text(AppString.edit_session_dialog_header,
                  textAlign: TextAlign.center),
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
    final text = '${AppString.shareHeader}\n\n${AppString.shareLink}';
    await Share.shareXFiles([XFile(image.path)], text: text,);
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

  Future<bool?> sendToArchive() async {
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(theSession?.sessionId)
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

  Future<bool?> removeFromArchive() async {
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(theSession?.sessionId)
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
