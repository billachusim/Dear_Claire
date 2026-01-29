import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/Admob/ad_state.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/transaction_model.dart' as t_model;
import '../../services/data/notification_model.dart' as push_notification;
import '../../services/notification_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/color.dart';
import '../../utils/strings.dart';
import '../../widgets/comment_widget.dart';
import '../Categories/similar_category_sessions.dart';
import 'model/comment_session_model.dart';
import 'model/session.dart';
import 'widget/post_details_widget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Temp {
  String id;
  CommentSessionModel commentModel;
  Temp(this.id, this.commentModel);
}

class EgoModeSessionDetail extends StatefulWidget {
  var featuredSessionModel;

  EgoModeSessionDetail(
      {Key? key, required this.featuredSessionModel})
      : super(key: key);

  @override
  _EgoModeSessionDetailState createState() =>
      _EgoModeSessionDetailState(featuredSessionModel);
}

const int maxFailedLoadAttempts = 3;


class _EgoModeSessionDetailState
    extends State<EgoModeSessionDetail> {
  Session? featuredSessionModel;
  CommentSessionModel? commentSessionModel;
  final TransactionService _transactionService = TransactionService();
  _EgoModeSessionDetailState(this.featuredSessionModel);

  List<CommentSessionModel> _commentList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<String> imageUrls = [];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late Future<UserModel> _userFuture;
  bool _isPremium = false;
  bool _isBannerAdInitialized = false;





  @override
  void initState() {
    super.initState();
    _userFuture = firebaseServices.getUserInfo();
    _userFuture.then((user) {
      if (mounted) {
        setState(() {
          _isPremium = user.isPremium;
        });
        if (!_isPremium) {
          _createAdviseInterstitialAd();
        }
      }
    });
  }



  @override
  void dispose() {
    if (!_isPremium) {
      _showAdviseInterstitialAd();
    }
    _interstitialAd?.dispose();
    egoModeSessionDetailBottomBanner?.dispose();
    super.dispose();
  }


  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  /// Create new sub chat interstitial ad.

  void _createAdviseInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/9839548530" :
      Platform.isIOS? "ca-app-pub-2404156870680632/8291211887" :
      '',      request: AdRequest(),
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
          _createAdviseInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createAdviseInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }



  // Admob Ad Units.
  BannerAd? egoModeSessionDetailBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerAdInitialized && !_isPremium) {
      final adState = Provider.of<AdState?>(context);
      if (adState != null) {
        adState.initialization.then((status) {
          if (!mounted || _isPremium) return;
          setState(() {
            egoModeSessionDetailBottomBanner = BannerAd(
              size: AdSize.banner,
              adUnitId: adState.egoModeBottomCommentBannerAdUnitId,
              request: const AdRequest(),
              listener: BannerAdListener(
                onAdLoaded: (ad) => print('Session detail banner loaded.'),
                onAdFailedToLoad: (ad, error) {
                  print('Session detail banner failed to load: $error');
                  ad.dispose();
                },
              ),
            )..load();
            _isBannerAdInitialized = true;
          });
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = HexColor.fromHex(featuredSessionModel!.colorHex!);
    final Color textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: backgroundColor,
        title: Text(featuredSessionModel!.title!, style: TextStyle(color: textColor)),
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
                                    widget.featuredSessionModel!.sessionId.toString()),
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
                                          // onPressed is now removed. The CommentWidget handles its own logic.
                                          onShare: () => _share(element.message),
                                          featuredSessionModel: widget.featuredSessionModel!,
                                          userId: widget.featuredSessionModel!.userId.toString(),
                                        ))
                                            .toList(),

                                        SizedBox(height: 4,),
                                        Text(
                                          "Check the next sessions from same category - " + featuredSessionModel!.category1.toString(),
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 12,
                                          ),
                                        ),

                                        SimilarCategorySessions(element: featuredSessionModel!,),
                                        SizedBox(height: 4),
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
              ],
            ),

            if (!_isPremium && egoModeSessionDetailBottomBanner != null && _isBannerAdInitialized)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Container(
                  height: egoModeSessionDetailBottomBanner!.size.height.toDouble(),
                  width: egoModeSessionDetailBottomBanner!.size.width.toDouble(),
                  child: AdWidget(ad: egoModeSessionDetailBottomBanner!),
                  alignment: Alignment.center,
                ),
              ),

            // Your chat input field at the very bottom
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
                  // Note: `featuredSessionModel` from the state is used here as `widget.featuredSessionModel` is not available in `_EgoModeSessionDetailState`.
                  final isSessionOwner = featuredSessionModel?.userId == currentUser?.uid;

                  if (isSessionOwner) {
                    // If the user is the owner, they always have permission.
                    hasPermission = true;
                  } else if (snapshot.hasData) {
                    // If not the owner, check the user's role.
                    final user = snapshot.data!;
                    final userType = user.userType ?? '';
                    final hasRequiredRole = ['REGULAR', 'ADMIN', 'SUPER_ADMIN'].contains(userType);
                    hasPermission = hasRequiredRole;
                  }
                  // If the user is not the owner and user data fails to load, hasPermission remains false.

                  return ChatEditField(
                    canComment: hasPermission,
                    onTap: (String comment, String voiceNote, String image1, String image2) {
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


  void _sendComment(String comment, String voiceNote, Session session, String image1, String image2) async {
    if (!await firebaseServices.isUserSignIn(context)) return;
    if (image1.isNotEmpty) {
      imageUrls = [image1, image2];
    }


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
        imageUrls: imageUrls,
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
        sender: _userModel.nickname.toString(),
    );

    updateSessionTimeLastActivity(session);
    isOriginalAdvise(context, comment, session);
    saveUserCommentActivity();
    firebaseServices.followAdvisedSessionImmediately(session);
    if (session.featured != true) {
      //startAiChat(session, comment);
    }
  }





  String timeAgo() {
    final commentTime = featuredSessionModel!.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    return _time;
  }



  /// checks if advise meets original advise rules...
  /// if it does, then increment necessary counts.
  Future<bool> isOriginalAdvise(BuildContext context, String adviseText,
      Session session) async {
    final _timeAgo = timeAgo(); // Make sure this function exists in the file
    final _advise = adviseText.toString();
    final _length = _advise.length;

    if (!_timeAgo.contains('day') && _advise.contains("arling") &&
        _length >= 20) {

      // This is a simple stat counter and can remain.
      incrementAdviseCount();

      // The old incrementTotalLoveCount() and _transactionService calls are removed from here.

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
          // We don't send a push notification because the reward isn't confirmed.
          return true; // Exit the function gracefully.
        }
        // --- END OF NEW TREASURY LOGIC ---

        // --- Send Push Notification (Only if approved) ---
        try {
          final notificationModel = push_notification.NotificationModel(
              topic: currentUser!.uid, // Send to the user's personal topic
              data: push_notification.Data(id: currentUser!.uid, route: session.sessionId.toString()),
              notification: push_notification.Notification(
                  title: "You've Earned Love!",
                  body: "You received 10 ❤️ for posting an original advise."));
          await notificationService.sendNotification(notificationModel.toJson());
        } catch (e) {
          print("Failed to send 'Original Advise' push notification: $e");
        }
        // --- End of Push Notification ---
      }

      showToast("Thanks! You earned 10 Loves.");

      // This local notification is good to keep for immediate feedback.
      flutterLocalNotificationsPlugin.show(
          0,
          'ClaireLove Wallet',
          "Thanks for that original advise. You just earned 10 Loves.",
          _notificationDetails(), // Make sure this function exists in the file
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
    final Session? theSession = featuredSessionModel;
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
    final sessionVisitorNickname = _user.nickname.toString();
    final sessionVisitorAvatar =  _user.userType != "REGULAR"
        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
        : _user.avatarUrl.toString();
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
        '${AppString.shareAdviseHeader}${featuredSessionModel?.title}\n\n$message\n${AppString.shareLink}');
  }

}
