import 'dart:async';
import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/Admob/ad_state.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
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

  _EgoModeSessionDetailState(this.featuredSessionModel);

  List<CommentSessionModel> _commentList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  ChatGPT? chatGPT;
  StreamSubscription? _subscription;




  @override
  void initState() {
    super.initState();
    chatGPT = ChatGPT.instance.builder(
      "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",
    );
    _createAdviseInterstitialAd();
  }



  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
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
  late BannerAd egoModeSessionDetailTopBanner;
  late BannerAd egoModeSessionDetailBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        egoModeSessionDetailTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.egoModeTopCommentBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        egoModeSessionDetailBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.egoModeBottomCommentBannerAdUnitId,
            request: AdRequest(),
          listener: BannerAdListener(
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
            },
          )
        )..load();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor.fromHex(featuredSessionModel!.colorHex!),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(featuredSessionModel!.colorHex!),
        title: Text(featuredSessionModel!.title!),
        elevation: 0,
      ),
      body: Stack(
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

                                      // Top ad unit is here
                                      if(egoModeSessionDetailTopBanner == null)
                                        SizedBox(height: 70)
                                      else
                                        Container(
                                          height: 60,
                                          child: AdWidget(ad: egoModeSessionDetailTopBanner),
                                        ),

                                      ..._commentList
                                          .map((element) => CommentWidget(
                                        commentSessionModel: element,
                                        onPressed: () => _updateReaction(
                                            element, widget.featuredSessionModel!),
                                        onShare: () => _share(element.message),
                                        featuredSessionModel: widget.featuredSessionModel!,
                                        userId: widget.featuredSessionModel!.userId.toString(),

                                      ))
                                          .toList(),

                                      SizedBox(height: 4,),
                                      Text(
                                        "Check the next sessions from same category - " + featuredSessionModel!.category1.toString(),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),

                                      SimilarCategorySessions(element: featuredSessionModel!,),
                                      SizedBox(height: 4),

                                      // Bottom ad unit is here
                                      if(egoModeSessionDetailBottomBanner == null)
                                        SizedBox(height: 70)
                                      else
                                        Container(
                                          height: 60,
                                          child: AdWidget(ad: egoModeSessionDetailBottomBanner),
                                        ),
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
                height: 70,
              )
            ],
          ),

          ChatEditField(
            onTap: (String comment, voiceNote, image1, image2) =>
                _sendComment(comment, voiceNote, widget.featuredSessionModel!, image1, image2),
          )

        ],
      ),
    );
  }

  void _sendComment(String comment, String voiceNote, Session session, String image1, String image2) async {
    if (session.location == "#QuickSession") {
      startAiChat(session, comment);
    } else
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
        sender: _userModel.nickname.toString(),
    );

    updateSessionTimeLastActivity(session);
    isOriginalAdvise(context, comment, session);
    saveUserCommentActivity();
    firebaseServices.followAdvisedSessionImmediately(session);
  }


  void startAiChat(Session session, String input) async {
    final request = CompleteReq(
        prompt: input, model: kTranslateModelV3, max_tokens: 200);

    _subscription = chatGPT!
        .onCompleteStream(request: request)
        .asBroadcastStream()
        .listen((response) {
      print("ADVISE IS : ${response!.choices[0].text}");
      sendAiAdvise(session, response.choices[0].text);
    });
  }



  void sendAiAdvise(Session session, String response) async {

    CollectionReference ref =
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId!)
        .collection("comments");

    String docId = ref.doc().id;

    final _commentModel = CommentSessionModel(
        alterEgoId: 'CLaiRE',
        audioUrl: '',
        commentId: docId,
        flagged: session.flagged!,
        imageUrls: [],
        image1: '',
        image2: '',
        thanks: [],
        numberOfThanks: 0,
        isUserAdmin: true,
        message: response,
        timeCreated: Timestamp.now(),
        userAvatarUrl: '',
        userId: 'CLaiRE',
        userNickname: 'CLaiRE',
        originalAdviseCategory: session.category1);

    await ref.doc(docId).set(_commentModel.toJson());


    firebaseServices.addCommentNotification(
      title: session.title ?? '',
      docId: session.sessionId!,
      sender: 'clAIre',
    );

    updateSessionTimeLastActivity(session);
    saveAICommentActivity();
  }



  String timeAgo() {
    final commentTime = featuredSessionModel!.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    return _time;
  }

  /// checks if advise meets original advise rules...
  /// if it does, then increment necessary counts.
  Future<bool> isOriginalAdvise(BuildContext context, String adviseText, Session session) async {
    final _timeAgo = timeAgo();
    final _advise = adviseText.toString();
    final _length = _advise.length;
    if(!_timeAgo.contains('day'))
    if (_advise.contains("arling"))
      if (_length >= 20)

      {
        incrementAdviseCount();
        incrementTotalLoveCount();

        showToast("Thanks! You earned 10 Loves.");

        flutterLocalNotificationsPlugin.show(0, 'ClaireLove Wallet',
            "Thanks for that original advise. You just earned 10 Loves.", _notificationDetails(), payload: "wallet");

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
        iOS: IOSNotificationDetails(
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

  /// Save AI Comment

  Future<void> saveAICommentActivity() async {
    final Session? theSession = featuredSessionModel;
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = "CLaiRE";
    final sessionVisitorNickname = "CLaiRE";
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


  void _updateReaction(commentSessionModel, session) async {
    if (!await firebaseServices.isUserSignIn(context)) {
      showToast('You have to login first before reacting.');
      return;
    }
    final _user = await firebaseServices.getUserInfo();
    final String commentId = commentSessionModel!.commentId.toString();
    final String docId = session.sessionId.toString();
    final String sender = _user.nickname.toString();
    firebaseServices.addThanksReaction(
        session: session,
        commentID: commentId,
        docId: docId,
        sender: sender,
        map: commentSessionModel!.thanks!.contains(currentUser?.uid)
            ? {
                'thanks': FieldValue.arrayRemove([currentUser?.uid])
              }
            : {
                'thanks': FieldValue.arrayUnion([currentUser?.uid])
              });
    saveUserThanksActivity(commentSessionModel);
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
