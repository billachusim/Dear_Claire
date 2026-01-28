import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/Admob/ad_state.dart';
import 'package:clairediary/ui/Categories/next_unreplied_sessions.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/ui/featured/widget/post_details_widget.dart';
import 'package:clairediary/ui/splash_screen/custom_rotate_bacground.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:clairediary/widgets/comment_widget.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/transaction_model.dart' as t_model;
import '../../../services/data/notification_model.dart' as push_notification;
import '../../../services/firebase_services.dart';
import '../../../services/notification_service.dart';
import '../../../services/transaction_service.dart';
import '../../../services/user_model.dart';
import '../../../utils/color.dart';

class AlterEgoModeSessionDetail extends StatefulWidget {
  var featuredSessionModel;

  AlterEgoModeSessionDetail({Key? key, required this.featuredSessionModel})
      : super(key: key);

  @override
  _AlterEgoModeSessionDetailState createState() =>
      _AlterEgoModeSessionDetailState(featuredSessionModel);
}

const int maxFailedLoadAttempts = 3;

class _AlterEgoModeSessionDetailState extends State<AlterEgoModeSessionDetail> {
  Session? featuredSessionModel;
  _AlterEgoModeSessionDetailState(this.featuredSessionModel);

  List<CommentSessionModel> _commentSessionList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;
  final TransactionService _transactionService = TransactionService();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // --- ADMOB COMPLIANCE FIX 1: Add new ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  late Future<UserModel> _userFuture;


  @override
  void initState() {
    super.initState();
    _createAdviseInterstitialAd();
    _userFuture = firebaseServices.getUserInfo();
  }

  @override
  void dispose() {
    // --- ADMOB COMPLIANCE FIX 2: Show interstitial on exit and dispose all ads ---
    _showAdviseInterstitialAd();
    _interstitialAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  /// Create new sub chat interstitial ad.
  void _createAdviseInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? "ca-app-pub-2404156870680632/9839548530" :
      Platform.isIOS ? "ca-app-pub-2404156870680632/8291211887" :
      '', request: AdRequest(),
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

  // --- ADMOB COMPLIANCE FIX 3: Clean up banner ad loading logic ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerAdInitialized) {
      final adState = Provider.of<AdState>(context);
      adState.initialization.then((status) {
        if (mounted) {
          setState(() {
            _bottomBannerAd = BannerAd(
                size: AdSize.banner,
                // Using a specific ad unit for this page
                adUnitId: adState.alterEgoModeBottomCommentBannerAdUnitId,
                request: AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) =>
                      print('Alter Ego session detail banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print(
                        'Alter Ego session detail banner failed to load: $error');
                    ad.dispose();
                  },
                )
            )
              ..load();
            _isBannerAdInitialized = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = HexColor.fromHex(
        featuredSessionModel!.colorHex!);
    final Color textColor = backgroundColor.computeLuminance() > 0.5 ? Colors
        .black : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: backgroundColor,
        title: Text(
            featuredSessionModel!.title!, style: TextStyle(color: textColor)),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      // --- ADMOB COMPLIANCE FIX 4: Restructure body with a Stack ---
        body: GestureDetector(
          onTap: () {
            // Hide keyboard when tapping outside of a text field
            FocusScope.of(context).unfocus();
          },
          child: Stack(
        children: [
          CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
          ListView(
            children: [
              PostDetailsWidget(
                sessionId: featuredSessionModel!.sessionId,
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
                        duration: Duration(milliseconds: 2500),
                        curve: Curves.fastLinearToSlowEaseIn,
                        horizontalOffset: 30,
                        verticalOffset: 300.0,
                        child: FlipAnimation(
                          duration: Duration(milliseconds: 3000),
                          curve: Curves.fastLinearToSlowEaseIn,
                          flipAxis: FlipAxis.y,

                          child: StreamBuilder(
                              stream: firebaseServices
                                  .getFeaturedSessionsComments(
                                  featuredSessionModel!.sessionId!),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapShot) {
                                if (snapShot.hasError) {
                                  return Container();
                                }

                                if (snapShot.hasData) {
                                  _commentSessionList.clear();
                                  snapShot.data!.docs
                                      .map((e) =>
                                      _commentSessionList
                                          .add(CommentSessionModel.fromJson(
                                          e.data() as Map<String, dynamic>)))
                                      .toList();
                                  // --- ADMOB COMPLIANCE FIX 5: Remove ads from the Column ---
                                  return Column(
                                    children: [
                                      // Top ad unit REMOVED
                                      ..._commentSessionList
                                          .map((element) =>
                                          CommentWidget(
                                            commentSessionModel: element,
                                            onShare: () =>
                                                _share(element.message),
                                            featuredSessionModel: featuredSessionModel!,
                                            userId: '',
                                          ))
                                          .toList(),

                                      SizedBox(height: 4,),
                                      Text(
                                        "Earn more> Respond to more sessions from category - " +
                                            featuredSessionModel!.category1
                                                .toString(),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                        ),
                                      ),

                                      NextUnrepliedSession(
                                        element: featuredSessionModel!,),
                                      SizedBox(height: 4),
                                      // Bottom ad unit REMOVED
                                    ],
                                  );
                                }
                                return Container();
                              }),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Adjust space for the input field AND the banner ad
              SizedBox(height: 120),
            ],
          ),

          // --- ADMOB COMPLIANCE FIX 6: Place a single, compliant banner ad ---
          if (_bottomBannerAd != null && _isBannerAdInitialized)
            Positioned(
              bottom: 60, // Position above the ChatEditField
              left: 0,
              right: 0,
              child: Container(
                height: _bottomBannerAd!.size.height.toDouble(),
                width: _bottomBannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bottomBannerAd!),
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

                // Check if the current user is the owner of the session.
                final isSessionOwner = widget.featuredSessionModel?.userId == currentUser?.uid;

                if (isSessionOwner) {
                  hasPermission = true;
                } else if (snapshot.hasData) {
                  // If not the owner, check user role.
                  final user = snapshot.data!;
                  final userType = user.userType ?? '';
                  final hasAlterEgoRole = ['ADMIN', 'SUPER_ADMIN'].contains(userType);
                  hasPermission = hasAlterEgoRole;
                }

                return ChatEditField(
                  canComment: hasPermission,
                  onTap: (String comment, voiceNote, image1, image2) {
                    if (hasPermission) {
                      _sendComment(comment, voiceNote, widget.featuredSessionModel!, image1, image2);
                    }
                  },
                );
              },
            ),
          )

        ],
          ),
        ),
    );
  }

  void _sendComment(String comment, String voiceNote, Session session,
      String image1, String image2) async {
    // ... This method's implementation remains the same
    if (!await firebaseServices.isUserSignIn(context)) return;

    CollectionReference ref = FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId!)
        .collection("comments");
    String docId = ref
        .doc()
        .id;
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
        isUserAdmin: true,
        message: comment,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname: _userModel.nickname,
        originalAdviseCategory: session.category1);
    await ref.doc(docId).set(_commentModel.toJson());
    firebaseServices.addCommentNotification(
      title: session.title ?? '',
      docId: session.sessionId!,
      sender: _userModel.userType == 'ADMIN'
          ? 'Claire'
          : _userModel.userType == 'SUPER_ADMIN'
          ? 'Claire'
          : _userModel.nickname.toString(),
    );
    updateSessionTimeLastActivity(session);
    isOriginalAdvise(context, comment, session);
    saveAlterEgoCommentActivity();
    firebaseServices.subscribeAlterEgoToAdvisedSession(session);
  }

  String timeAgo() {
    final commentTime = featuredSessionModel!.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    return _time;
  }

  /// checks if advise meets original advise rules...
  /// if it does, then increment necessary counts.
  // In /lib/ui/alter_ego/widgets/alter_ego_mode_session_detail.dart

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
    // ... This method's implementation remains the same
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

  Future<void> incrementAdviseCount() async {
    // ... This method's implementation remains the same
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




  /// Save alter ego comment activity

  Future<void> saveAlterEgoCommentActivity() async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final Session? theSession = featuredSessionModel;
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = currentUser?.uid.toString();
    final sessionVisitorNickname = _user.userType == 'ADMIN'? 'Alter Ego' :
    _user.userType == 'SUPER_ADMIN'? 'Super Ego' :
    'Alter-Ego';
    final sessionVisitorAvatar = "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691";
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


  /// Save user thanks activity

  Future<void> saveUserThanksActivity(CommentSessionModel commentSessionModel) async {
    final UserModel _user = await firebaseServices.getUserInfo();
    final Session? theSession = widget.featuredSessionModel;
    final CommentSessionModel? theComment = commentSessionModel;
    final dateCreated = FieldValue.serverTimestamp();
    final commentOwnerNickname = theComment?.isUserAdmin == true? "Claire" : theComment?.userNickname.toString();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = _user.userId.toString();
    final sessionVisitorNickname = _user.userType == "ADMIN" ? "Alter Ego" : "Super Ego";
    final sessionVisitorAvatar =  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691";
    final activityMessage = "$sessionVisitorNickname thanked $commentOwnerNickname's advise.";
    final activityType = "thank";
    final userActivityId = "";
    if (!commentSessionModel.thanks!.contains(sessionVisitorId)) {
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

  }


  /// Update a session's timeLastActivity when new comment is made.

  Future<void> updateSessionTimeLastActivity(Session session) async {
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId)
        .update({
      'timeLastActivity': FieldValue.serverTimestamp(),
      'respondentUserId': currentUser!.uid,
    },
    );
    logger.d('Successfully updated time of last activity');

  }


  _share(String? message) {
    String _message = '''
    And here is the advise from Claire:
    
     $message  
    ''';
    shareMessage(_message);
  }
}
