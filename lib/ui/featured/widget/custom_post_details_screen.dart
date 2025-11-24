import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../../../Admob/ad_state.dart';
import '../../../data/models/transaction_model.dart' as t_model;
import '../../../services/data/notification_model.dart' as push_notification;
import '../../../services/firebase_services.dart';
import '../../../services/native_gallery_saver.dart';
import '../../../services/notification_service.dart';
import '../../../services/transaction_service.dart';
import '../../../services/user_model.dart';
import '../../../utils/mood.dart';
import '../../../utils/strings.dart';
import '../../../widgets/chat_edit_field.dart';
import '../../../widgets/comment_widget.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/follow_button.dart';
import '../../../widgets/metoo_button.dart';
import '../../../widgets/toast.dart';
import '../../Categories/similar_category_sessions.dart';
import '../../create_session/sound/custom_play_sound_widget.dart';
import '../../routes/page_router_animation.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';
import '../model/comment_session_model.dart';

class CustomPostDetailsWidget extends StatefulWidget {
  CustomPostDetailsWidget({Key? key, required this.sessionId}) : super(key: key);
  String? sessionId;

  @override
  _CustomPostDetailsWidgetState createState() => _CustomPostDetailsWidgetState();
}

const int maxFailedLoadAttempts = 3;

class _CustomPostDetailsWidgetState extends State<CustomPostDetailsWidget> {
  final screenshotController = ScreenshotController();
  TextEditingController editSessionController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  User? currentUser = FirebaseAuth.instance.currentUser;

  bool? isFeatured;

  late String visitedUsersID;
  late String visitedEgoName;

  //initialize the audio record file that stores user audio record. null by default
  String? recordFile;
  Session? theSession;

  bool? isFlagged;

  List<CommentSessionModel> _commentList = [];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();



  @override
  void initState() {
    super.initState();
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
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Notified Session"),
        elevation: 0,
      ),
      body: Stack(
          children: [
            ListView(
                children: [
                  Screenshot(
                    controller: screenshotController,
                    child: Material(
                      child: SafeArea(
                        child: StreamBuilder(
                            stream: firebaseServices.getSingleDocument(id: widget.sessionId),
                            builder: (context,
                                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
                              if (snaps.hasData) {
                                final _session = Session.fromJson(snaps.data!.data()!);
                                theSession = _session;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: HexColor.fromHex(_session.colorHex!)),
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
                                              visitedUsersID = _session.userId!;
                                              visitedEgoName = _session.userNickname!;
                                              String thisEgoName =
                                              _session.userNickname.toString();
                                              String thisUser = _session.userId.toString();
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
                                              print("Visited User ID::: $visitedUsersID");
                                            },
                                            child: CachedNetworkImage(
                                                width: 48,
                                                height: 48,
                                                imageUrl: _session.userAvatarUrl!,
                                                imageBuilder: (context, imageProvider) =>
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: imageProvider,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                    ),
                                                placeholder: (context, url) => Center(
                                                    child: CircularProgressIndicator()),
                                                errorWidget: (context, url, error) =>
                                                    Image.asset(
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
                                                  onTap: () async {
                                                    visitedUsersID = _session.userId!;
                                                    visitedEgoName = _session.userNickname!;
                                                    String thisEgoName =
                                                    _session.userNickname.toString();
                                                    String thisUser =
                                                    _session.userId.toString();
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
                                                    print("Visited User ID::: $visitedUsersID");
                                                  },
                                                  child: Text(_session.userNickname!,
                                                      textAlign: TextAlign.start,
                                                      maxLines: 1,
                                                      style: GoogleFonts.lato(
                                                          fontSize: 18.0,
                                                          color: Pallet.colorWhite,
                                                          fontWeight: FontWeight.w700)),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(timeConverter(_session.timeCreated!),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                    style: GoogleFonts.lato(
                                                        fontSize: 13.0,
                                                        color: Pallet.colorWhite,
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
                                                        fontSize: 13.0,
                                                        color: Pallet.colorWhite,
                                                        fontWeight: FontWeight.w700)),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(_session.location ?? '',
                                                    textAlign: TextAlign.end,
                                                    maxLines: 1,
                                                    style: GoogleFonts.lato(
                                                        fontSize: 12.0,
                                                        color: Colors.white70,
                                                        fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: 14,
                                      ),
                                      Center(
                                        child: Text(_session.title!,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            style: GoogleFonts.lato(
                                                fontSize: 20.0,
                                                color: Pallet.colorWhite,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                      SizedBox(
                                        height: 12,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _session.message!,
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.lato(
                                                  fontSize: 17.0,
                                                  color: Pallet.colorWhite,
                                                  fontWeight: FontWeight.normal),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 5,),

                                      Container(
                                        child: _session.audioUrl!.isNotEmpty
                                            ? CustomPlaySoundWidget(
                                            filePath: _session.audioUrl)
                                            : SizedBox.shrink(),
                                      ),

                                      Visibility(
                                        visible: _session.imageUrls!.isNotEmpty,
                                        child: GridView.count(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          crossAxisCount: 5,
                                          children: List.generate(_session.imageUrls!.length, (index) {
                                            String image = _session.imageUrls![index].toString();
                                            return Stack(
                                              fit: StackFit.expand,
                                              children: <Widget>[
                                                GestureDetector(
                                                  onTap: () {
                                                    PageRouter.gotoWidget(CustomImageWidget(imageUrl: image), context);
                                                  },
                                                  child: Container(
                                                    child: CachedNetworkImage(
                                                        height: 100,
                                                        width: 100,
                                                        imageUrl: image,
                                                        imageBuilder: (context, imageProvider) => Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(25),
                                                            image: DecorationImage(
                                                                image: imageProvider,
                                                                fit: BoxFit.cover
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
                                                    margin: EdgeInsets.all(3),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),

                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          MetooButton(
                                            cheers: _session.meToos!.length,
                                            thanks: _session.meLove!.length,
                                            sorry: _session.meHiFive!.length,
                                            me2: _session.meFlower!.length,
                                            onReactionChanged: (reaction, index) async {
                                              if (await firebaseServices
                                                  .isUserSignIn(context)) {
                                                final _userModel =
                                                await firebaseServices.getUserInfo();

                                                firebaseServices.addUsersReactionToASession(
                                                    context, index,
                                                    session: _session,
                                                    sender: _userModel.nickname ?? '');

                                                saveUserMe2Activity();
                                                await firebaseServices.updateSessionLastTimeActivity(_session.sessionId.toString());

                                              }
                                            },
                                            color: Pallet.colorWhite,
                                            session: _session,
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
                                                Text(_session.followers!.length.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),

                                                Icon(
                                                  _session.followers!
                                                      .contains(currentUser?.uid)
                                                      ? Icons.notifications_active_rounded
                                                      : Icons.notifications_off_outlined,
                                                  color: Pallet.colorWhite,
                                                  size: 24,
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
                                              if (await firebaseServices.isUserSignIn(
                                                  context)) saveUserFollowActivity();

                                              firebaseServices.followThisSession(
                                                  context,
                                                  session: _session);
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

                                                return
                                                  Visibility(
                                                    visible: userType == "SUPER_ADMIN",
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        if (_session.featured == false)
                                                          modFeatureAlertDialog(context);
                                                        else unfeatureAlertDialog(context);
                                                      },
                                                      child: Container(
                                                        child: Visibility(
                                                          visible: _session.repliesEnabled == true,
                                                          child: Icon(
                                                            _session.featured == true ? Icons.lightbulb : Icons.lightbulb_outline,
                                                            color: Pallet.colorSecondary,
                                                            size: 24,
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
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 2.5, horizontal: 7),
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: Pallet.colorWhite,
                                                      )),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        size: 15,
                                                        color: Pallet.colorWhite,
                                                      ),
                                                      SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        'Edit',
                                                        style: GoogleFonts.lato(
                                                            fontSize: 12.0,
                                                            color: Pallet.colorWhite,
                                                            fontWeight: FontWeight.w800),
                                                      ),
                                                    ],
                                                  ),
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
                                                        color: Pallet.colorWhite,
                                                        size: 20,
                                                      ),
                                                      Text(
                                                        'Flag',
                                                        style: GoogleFonts.lato(
                                                            fontSize: 13.0,
                                                            color: Pallet.colorWhite,
                                                            fontWeight: FontWeight.w800),
                                                      ),
                                                    ],
                                                  ),
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
                                                        size: 15,
                                                        color: Pallet.colorWhite,
                                                      ),
                                                      Text(
                                                        'Share',
                                                        style: GoogleFonts.lato(
                                                            fontSize: 13.0,
                                                            color: Pallet.colorWhite,
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

                                          // Top ad unit is here
                                          Container(
                                            height: 60,
                                            child: AdWidget(ad: egoModeSessionDetailTopBanner),
                                          ),

                                          ..._commentList
                                              .map((element) => CommentWidget(
                                            commentSessionModel: element,
                                            onShare: () => _share(element.message),
                                            featuredSessionModel: theSession!,
                                            userId: theSession!.userId.toString(),

                                          ))
                                              .toList(),

                                          SizedBox(height: 4,),
                                          Text(
                                            "Check the next sessions from same category - " + theSession!.category1.toString(),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),

                                          SimilarCategorySessions(element: theSession!,),

                                          // Bottom ad unit is here
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

                ]
            ),

            ChatEditField(
              onTap: (String comment, voiceNote, image1, image2) =>
                  _sendComment(comment, voiceNote, theSession!, image1, image2),
            )
          ]
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
      sender: _userModel.nickname.toString(),
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


  void _updateReaction(commentSessionModel, session) async {
    if (!await firebaseServices.isUserSignIn(context)) {
      showToast('You have to login first before reacting.');
      return;
    }
    final String commentId = commentSessionModel!.commentId.toString();
    final String docId = session.sessionId.toString();
    final String sender = commentSessionModel.userNickname.toString();
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
