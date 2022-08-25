import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/featured/notified_session_details.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_profile_page_model.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_claireloves.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_model.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../services/notification_service.dart';
import '/services/data/notification_model.dart' as pushNotification;
import '../../services/user_activity_model.dart';
import '../../services/user_model.dart';
import '../../utils/constant.dart';
import '../../widgets/ego_mode_session_card.dart';
import '../featured/model/comment_session_model.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class VisitedUserEgoProfilePage extends StatefulWidget {
  final String visitedUsersID;
  final String visitedEgoName;

  VisitedUserEgoProfilePage(
      {Key? key, required this.visitedUsersID, required this.visitedEgoName})
      : super(key: key);

  @override
  _VisitedUserEgoProfilePageState createState() => _VisitedUserEgoProfilePageState();
}

const int maxFailedLoadAttempts = 3;



class _VisitedUserEgoProfilePageState extends State<VisitedUserEgoProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _visitorMantraController = TextEditingController();
  late FocusNode _visitorMantraFocusNode = FocusNode();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  GlobalKey<FlipCardState> cardKey2 = GlobalKey<FlipCardState>();
  /// create instance of FirebaseMessaging
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;




  @override
  void initState() {
    super.initState();
    getVisitedUser();
    getVisitingUser();
    _createEgoMantraInterstitialAd();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    _interstitialAd2?.dispose();
  }

  int currentTabIndex = 0;
  User? currentUser = FirebaseAuth.instance.currentUser;
  VisitedUserModel? visitedUser = VisitedUserModel();
  String? visitedUsersID;
  List<Session>? _sessionList = [];
  UserModel? _visitingUser = UserModel();
  bool? isFlagged;



  // Admob Ad Units.
  late BannerAd visitedUserTopOfSessionsBanner;
  late BannerAd visitedUserBottomOfSessionsBanner;
  late BannerAd visitedUserTopOfActivitiesBanner;
  late BannerAd visitedUserBottomOfActivitiesBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        visitedUserTopOfSessionsBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserTopOfSessionBannerAdUnitId,
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
        visitedUserBottomOfSessionsBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserBottomOfSessionsBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });



    // Implement a top location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        visitedUserTopOfActivitiesBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserTopOfActivitiesBannerAdUnitId,
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
        visitedUserBottomOfActivitiesBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserBottomOfActivitiesBannerAdUnitId,
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




  getVisitedUser() async {
    visitedUserModel = await getVisitedUserInfo();
  }

  getVisitingUser() async {
    userModel = await getVisitingUserInfo();
  }

  /// Get Visiting Ego User info
  Future<UserModel> getVisitingUserInfo() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(currentUser?.uid)
        .get();

    var visitingUser = UserModel.fromFirestore(response.data() as Map<String, dynamic>);
    _visitingUser = visitingUser;
    logger.d('Successfully got the visiting user model');
    return visitingUser;
  }



  /// Query Ego stream from Firestore

  Stream<QuerySnapshot<Map<String, dynamic>>> getVisitedUserEgoStream() {

    return FirebaseFirestore.instance
        .collection('ego_stream')
        .where("userId", isEqualTo: widget.visitedUsersID)
        .limit(300)
        .orderBy('egoTime', descending: true)
        .snapshots();
  }



  /// Save Ego mantra

  Future<void> saveEgoMessage() async {
    final egoMessage = _visitorMantraController.text;
    final egoTime = FieldValue.serverTimestamp();
    final egoName = _visitingUser?.nickname;
    final egoImage = _visitingUser?.avatarUrl;
    final userId = widget.visitedUsersID;
    final senderId = currentUser?.uid;
    FirebaseFirestore.instance
        .collection('ego_stream')
        .add({
      "egoMessage": egoMessage,
      "egoTime": egoTime,
      "egoName": egoName,
      "egoImage": egoImage,
      "userId": userId,
      "senderId": senderId,
    },
    );
    logger.d('Successfully sent an Ego message to $egoName');
    print('Ego Message: $egoMessage');
  }


  Future<void> pushMantraNotification() async {
    final egoMessage = _visitorMantraController.text;
    final egoName = _visitingUser?.nickname;
    final userId = widget.visitedUsersID;
    final senderId = currentUser?.uid;

    await _firebaseMessaging.subscribeToTopic(userId);

    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
        to: '/topics/${userId.toString()}',
        collapseKey: 'type_a',
        data: pushNotification.Data(id: senderId, route: 'wallet'),
        notification: pushNotification.Notification(
            title: "Ego Mantra",
            body: '$egoName sent a new mantra to your ego stream.\n$egoMessage'));
    notificationService.sendNotification(_notificationModel.toJson());

    logger.d('Successfully pushed an Ego message notification to $egoName');
    print('Ego Message: $egoMessage');
  }



  /// Delete an ego message

  Future<void> deleteEgoMessage(String egoMessage) async {
    final collection = FirebaseFirestore.instance
        .collection('ego_stream')
        .where("egoMessage", isEqualTo: egoMessage);
    collection.get().then((value) {
      value.docs.forEach((element) {
        element.reference.delete();
      });
    });
    logger.d('Successfully deleted an ego message');
  }



  /// Get Visited Ego User info
  Future<VisitedUserModel> getVisitedUserInfo() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(widget.visitedUsersID)
        .get();

    var visitedUser = VisitedUserModel.fromFirestore(response.data() as Map<String, dynamic>);
    logger.d('Successfully got the visited user model');
    return visitedUser;
  }



  /// Get visited user's sessions that have been featured or marked for replies.
  Stream<QuerySnapshot<Map<String, dynamic>>> visitedUsersSessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("userId", isEqualTo: widget.visitedUsersID)
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
    //.orderBy('timeLastActivity', descending: true)
        .snapshots();
  }

  /// [User Activity] -> get visited user activities.
  Future<List<UserActivityModel>> getActivityByVisitedUser() async {
    List<UserActivityModel> _userActivityList = [];
    visitedUser = await getVisitedUserInfo();
    try {
      final _value = await FirebaseFirestore.instance
          .collection(AppString.userActivity)
          .where("clientId", isEqualTo: widget.visitedUsersID)
          .orderBy('dateCreated', descending: true)
          .limit(AppString.allSessionLength)
          .get();

      _value.docs
          .map((e) =>
          _userActivityList.addAll([UserActivityModel.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _userActivityList;
  }

  //show up when user clicks on the FAB to send a mantra.
  Future<void> _showCardDialog() async {
    Future.delayed(Duration(seconds: 2), () {
      _visitorMantraFocusNode.requestFocus();
    }
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            title: Container(
              child: Text(AppString.send_ego_message_header,
                  textAlign: TextAlign.center),
            ),
            content: SingleChildScrollView(
              child: Container(
                width: getDeviceWidth(context),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      "assets/images/bottle_message.jpeg",
                    ),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      focusNode: _visitorMantraFocusNode,
                      controller: _visitorMantraController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        iconColor: Colors.white,
                        icon: Icon(
                          Icons.message,
                          color: Colors.white,
                        ),
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
                  'Send',
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  if (userModel.nickname != null)
                    if (_visitorMantraController.text.isNotEmpty) {

                      saveEgoMessage();
                      pushMantraNotification();
                      _visitorMantraController.clear();
                      Navigator.of(context).pop();
                      //setState(() {});
                      showToast(AppString.sent_ego_message);

                      Future.delayed(Duration(seconds: 4), () {
                        _showEgoMantraInterstitialAd();
                      });
                    }
                },
              ),
            ],
          ),
        );
      },
    );
  }


  InterstitialAd? _interstitialAd2;
  int _interstitialLoadAttempts = 0;


  void _createEgoMantraInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/2338869057" :
      Platform.isIOS? "ca-app-pub-2404156870680632/5936716173" :
      '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd2 = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd2 = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createEgoMantraInterstitialAd();
          }
        },
      ),
    );
  }



  void _showEgoMantraInterstitialAd() {
    if (_interstitialAd2 != null) {
      _interstitialAd2!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createEgoMantraInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createEgoMantraInterstitialAd();
        },
      );
      _interstitialAd2!.show();
    }
  }



  /// Block a user only by Super Ego

  Future<void> blockUser() async {
    final userId = visitedUser?.userId;
    final userToBlock = FirebaseFirestore.instance
        .collection('users')
        .doc(userId);
    await userToBlock.delete();
    logger.d('Successfully blocked a user');
    print("The Blocked User Is: $userId");
  }


  flagEgoAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Flag"),
      onPressed:  () {
        sendToFlagged();
        showToast("Thank You!\n Claire will check this Ego for violations.");
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Flag And Report This User?"),
      content: Text(AppString.flag_ego_alert_note),
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

  /// Flag a user

  Future<bool?> sendToFlagged() async {
    final userId = visitedUser?.userId;
    final value = true;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
      "flagged": value,
    },
      SetOptions(merge: true),
    );
    logger.d('Successfully flagged a user');
    print('Is Flagged?: $userId');
    isFlagged = value;
    return value;
  }




  unflagEgoAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Back"),
      onPressed:  () {
        Navigator.of(context).pop();      },
    );
    Widget continueButton = TextButton(
      child: Text("Unflag"),
      onPressed:  () {
        removeFromFlagged();
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Unflag This User?"),
      content: Text(AppString.unflag_ego_alert_note),
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

  /// Unflag a user

  Future<bool?> removeFromFlagged() async {
    final userId = visitedUser?.userId;
    final value = false;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
      "flagged": value,
    },
      SetOptions(merge: true),
    );
    logger.d('Successfully unflagged a user');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }


  /// Visited User Ego Profile Info Here


  Future<VisitedEgoProfileInfo> getVisitedUserEgoProfileInfo()async{
    VisitedEgoProfileInfo visitedProfileInfo = VisitedEgoProfileInfo();
    visitedUser = await getVisitedUserInfo();

    visitedProfileInfo = VisitedEgoProfileInfo(visitedUserModel: visitedUser);



    //get user session count
    List<Session> _sessionList = [];
    try {
      final _value = await FirebaseFirestore.instance
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: widget.visitedUsersID)
      // .limit(AppString.appSessionLength)
          .get();


      debugPrint(
          " This is the number of sessions by date for this visited user ${_value.docs.length}");
      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of sessions by date for this visited user ${_sessionList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }


    //get advises count

    List<CommentSessionModel> _advisesList = [];


    try {
      final _value = await FirebaseFirestore.instance
          .collection("user_comment_counters")
          .where("userId", isEqualTo: widget.visitedUsersID)
      //  .limit(AppString.appSessionLength)
          .get();


      debugPrint(
          " This is the number of advises given by this visited user ${_value.docs.length}");
      _value.docs
          .map((e) => _advisesList.addAll([CommentSessionModel.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of advises given by this visited user ${_advisesList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }


    //get follows count

    List<VisitedUserModel> _followsList = [];


    try {
      final _value = await FirebaseFirestore.instance
          .collection(AppString.users)
          .where("userId", isEqualTo: widget.visitedUsersID)
      // .limit(AppString.appCommentLength)
          .get();


      debugPrint(
          " This is the number of follows given to this visited user ${_value.docs.length}");
      _value.docs
          .map((e) => _followsList.addAll([VisitedUserModel.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of follows given to this visited user ${_followsList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }



    visitedProfileInfo = VisitedEgoProfileInfo(
      visitedUserModel: visitedUser,
      sessionCount: _sessionList.length,
      advisesCount: _advisesList.length,
      followCount: _followsList.length,
    );
    return visitedProfileInfo;

  }




  /// Profile Cover header

  Widget _visitedPageHeader(
      {String? avatarUrl, String? userName, String? userType,
        var sessionCount, var totalLoveCount, var adviseCount})
  {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              AppImages.appChatBg,
            ),
            fit: BoxFit.fill,
          ),
        ),
        margin: EdgeInsets.only(bottom: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Edit Clairevatar icon is here
                      Container(
                        decoration: BoxDecoration(
                            color: userType == 'REGULAR'? Pallet.colorPrimary
                                : userType == 'ADMIN'? Pallet.colorSecondary
                                : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                                :Pallet.colorBlue,
                            borderRadius: BorderRadius.circular(100)
                        ),
                        height: 22,
                        width: 20,
                        margin: EdgeInsets.only(left: 4),

                        child: Icon(
                          visitedUser?.userType == "ADMIN" ? Icons.star_half_rounded
                          : visitedUser?.userType == "SUPER_ADMIN" ? Icons.star
                              : Icons.star_border_rounded,
                          color: Pallet.colorWhite,
                          size: 20,
                        ),
                      ),

                      //Clairevatar Container is here
                      Container(
                        decoration: BoxDecoration(
                          color: userType == 'REGULAR'? Pallet.colorPrimary
                              : userType == 'ADMIN'? Pallet.colorSecondary
                              : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                              :Pallet.colorBlue,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        margin: EdgeInsets.only(left: 0),
                        child: Container(
                          height: 75,
                          width: 75,
                          margin: EdgeInsets.all(4),
                          child: CachedNetworkImage(
                              width: 70,
                              height: 70,
                              imageUrl: avatarUrl ??"",
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Image.asset(
                                "assets/images/brown_boy_mask.png",
                                width: 50,
                                height: 50,
                              ) //Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),


                  // The count columns are here
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        sessionCount ?? "---",
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),

                      Text(
                        "Sessions",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ],
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        adviseCount ?? "---",
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),

                      Text(
                        "Advises",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ],
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        totalLoveCount ?? "---",
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),

                      Text(
                        "Loves",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(width: 6,),
                ],
              ),
            ),



            /// Nickname and edit nickname FlipCard method

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                Container(
                  margin: EdgeInsets.all(4),
                  height: 40,
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    color: userType == 'REGULAR'? Pallet.colorPrimary
                        : userType == 'ADMIN'? Pallet.colorSecondary
                        : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                        :Pallet.colorBlue,
                  ),
                  child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Pallet.colorWhite,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: EdgeInsets.only(left: 17, right: 4, top: 4, bottom: 4),
                          alignment: Alignment.centerLeft,
                          width: 250,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              SizedBox(width: 4,),

                              Text(
                                userName ??"",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          visitedUser?.userType == "ADMIN" ? Icons.star_half_rounded
                              : visitedUser?.userType == "SUPER_ADMIN" ? Icons.star
                          : Icons.star_border_rounded,

                          color: Pallet.colorWhite,
                          size: 20,
                        ),

                      ],
                    ),
                ),

                Spacer(flex: 1,),


                /// Here is the Ego badge showing user's usertype

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 6),
                          padding: EdgeInsets.only(
                              left: 8, right: 4, top: 4, bottom: 4,),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: userType == 'REGULAR'? Pallet.colorPrimary
                                : userType == 'ADMIN'? Pallet.colorSecondary
                                : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                                :Pallet.colorBlue,
                          ),
                          child: Row(
                            children: [
                              Text(
                                userType == 'REGULAR'? 'Ego' :
                                userType == 'ADMIN'? 'Alter Ego' :
                                userType == 'SUPER_ADMIN'? 'Super Ego' :
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                      SizedBox(height: 3,),

                      /// Flagged user label

                      GestureDetector(
                        onTap: () {
                          if (visitedUser!.flagged == false)
                            showCustomDialog(context,
                                message: visitedUser!.flagged == true
                                    ? AppString.unflag_ego_alert_note
                                    : AppString.flag_ego_alert_note,
                                onPressed: () {
                              setState(() {
                                PageRouter.goBack(context);
                                sendToFlagged();
                              });
                                });
                          else
                            showCustomDialog(context,
                                message: visitedUser!.flagged == false
                                    ? AppString.flag_ego_alert_note
                                    : AppString.unflag_ego_alert_note,
                                onPressed: () {
                              setState(() {
                                PageRouter.goBack(context);
                                removeFromFlagged();
                              });
                                });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 6),
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Pallet.colorPrimaryDark,
                              )),
                          child: Row(
                            children: [
                              Icon(
                                visitedUser?.flagged == true ? Icons.flag : Icons.flag_outlined,
                                color: Pallet.colorPrimaryDark,
                                size: 15,
                              ),
                              SizedBox(width: 2,),
                              Text(
                                userType == 'REGULAR'? 'Flag Ego' :
                                userType == 'ADMIN'? 'Flag Alter Ego' :
                                userType == 'SUPER_ADMIN'? 'Flag Super Ego' :
                                '',
                                style: GoogleFonts.lato(
                                    fontSize: 11.0,
                                    color: Pallet.colorPrimaryDark,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            SizedBox(
              height: 2,
            ),



            /// Front card: Write Ego mantra and send to stream


            Container(
              width: getDeviceWidth(context),
              height: 100,
              margin: EdgeInsets.only(left: 4, right: 4),
              child: FlipCard(
                key: cardKey,
                direction: FlipDirection.HORIZONTAL, // default
                back: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        color: userType == 'REGULAR'? Pallet.colorPrimary
                            : userType == 'ADMIN'? Pallet.colorSecondary
                            : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                            :Pallet.colorBlue,                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                userType == 'REGULAR'? 'Ego Stream:' :
                                userType == 'ADMIN'? 'Alter Ego Stream:' :
                                userType == 'SUPER_ADMIN'? 'Super Ego Stream:' :
                                '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 3,),
                            Row(
                              children: [
                                FloatingActionButton(
                                  onPressed: () {},
                                  mini: true,
                                  backgroundColor: Pallet.colorWhite,
                                  child: Icon(
                                    Icons.mic_rounded,
                                    size: 22,
                                    color: Pallet.colorPrimary,
                                  ),),
                                Expanded(
                                  child: new ConstrainedBox(
                                    constraints: new BoxConstraints(
                                      minWidth: getDeviceWidth(context),
                                      maxWidth: getDeviceWidth(context),
                                      minHeight: 50.0,
                                      maxHeight: 90.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: _showCardDialog,
                                      child: Container(
                                        padding: EdgeInsets.all(5),
                                        width: double.infinity,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          gradient: LinearGradient(
                                            begin: Alignment(-0.37857140550652835, -1.9473685559777252),
                                            end: Alignment(1.2428571464417884, 2.526316110739735),
                                            stops: [0.0, 0.856177031993866, 1.0],
                                            colors: [
                                              Pallet.colorWhite,
                                              Pallet.colorSecondary,
                                              Pallet.colorSecondaryDark,
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Text('Drop an anonymous message into this Ego\'s Stream.',
                                            style: GoogleFonts.lato(
                                                fontSize: 12.0,
                                                color: Pallet.colorBlack,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                FloatingActionButton(
                                    onPressed: () {
                                      if (userModel.nickname != null)
                                        if (_visitorMantraController.text.isNotEmpty)
                                          saveEgoMessage();
                                      _visitorMantraController.clear();
                                      if(cardKey.currentState != null) { //null safety
                                        cardKey.currentState!.toggleCard();
                                      }
                                      showToast(AppString.sent_ego_message);
                                    },
                                    mini: true,
                                    backgroundColor: Pallet.colorWhite,
                                    child: SvgPicture.asset(
                                      AppImages.appSend,
                                      color: Pallet.colorPrimary,
                                      height: 20,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),


                /// Back of card is Ego Stream for display


                front: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                        color: userType == 'REGULAR'? Pallet.colorPrimary
                            : userType == 'ADMIN'? Pallet.colorSecondary
                            : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                            :Pallet.colorBlue,
                      ),
                    ),

                    /// Build Ego stream from Firebase on a ListView

                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: getVisitedUserEgoStream(),
                              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Something went wrong');
                                }
                                if (!snapshot.hasData) {
                                  return Text('Write a mantra that you wish to live by currently by tapping on this space',
                                    style: TextStyle(color: Colors.white),);
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text("Loading");
                                }

                                return ListView(
                                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                                    return ListTile(
                                      leading: ClipOval(
                                        child: GestureDetector(
                                          onTap: (){
                                            final String _mantraUserId = data['senderId'].toString();
                                            final String _mantraEgoName = data['egoName'].toString();
                                            PageRouter.gotoWidget(
                                                VisitedUserEgoProfilePage(visitedUsersID: _mantraUserId, visitedEgoName: _mantraEgoName),
                                                context);
                                            print("Visited User ID::: $_mantraUserId");
                                          },
                                          child: CachedNetworkImage(
                                            width: 40,
                                            height: 40,
                                            imageUrl: data['egoImage'].toString(),
                                            imageBuilder: (context, imageProvider) => Container(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                            placeholder: (context, url) =>
                                                CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => Image.asset(
                                              "assets/images/brown_boy_mask.png",
                                              width: 30,
                                              height: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(data['egoName'].toString(),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      subtitle: Text(data['egoMessage'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: Visibility(
                                        visible: _visitingUser!.userType == "SUPER_ADMIN",
                                        child: GestureDetector(
                                          onTap: () {
                                            final String _egoMessage = data['egoMessage'];
                                            showCustomDialog(context,
                                                message: AppString.delete_mantra_alert_note,
                                                onPressed: () {
                                                  PageRouter.goBack(context);
                                                  deleteEgoMessage(_egoMessage);
                                                });
                                          },
                                          child: Icon(
                                            Icons.delete_forever_rounded,
                                            color: Colors.white70,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }






  @override
  Widget build(BuildContext context) {
    print("User nickname::: ${visitedUserModel.nickname}");
    print("User type::: ${visitedUserModel.userType}");

    return SafeArea(
      child: Scaffold(
        backgroundColor: Pallet.colorSecondaryDark,
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.visitedEgoName.toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Pallet.colorWhite,
          ),
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            Material(
              elevation: 10,
              child: FutureBuilder(
                  future: getVisitedUserEgoProfileInfo(),
                  builder:
                      (context, AsyncSnapshot<VisitedEgoProfileInfo> visitedProfileInfo) {
                    if (visitedProfileInfo.connectionState ==
                        ConnectionState.waiting) {
                      return RotateImage(50, 50);
                    }
                    if (!visitedProfileInfo.hasData) {
                      return _visitedPageHeader();
                    }

                    if (visitedProfileInfo.hasError) {
                      return _visitedPageHeader();
                    }

                    if (visitedProfileInfo.hasData) {
                      return _visitedPageHeader(
                        userName: visitedProfileInfo.data?.visitedUserModel?.nickname,
                        sessionCount: visitedUserModel.sessionCount.toString(),
                        adviseCount: visitedUserModel.adviseCount.toString(),
                        totalLoveCount: visitedUserModel.totalLoveCount.toString(),
                        userType: visitedProfileInfo.data?.visitedUserModel?.userType,
                        avatarUrl: visitedProfileInfo.data?.visitedUserModel?.avatarUrl,
                      );
                    }
                    return Container();
                  }
              ),
            ),


            /// The three Ego page tabs are here
            /// First tab is Sessions Tab

            Expanded(
                child: DefaultTabController(
                  length: 3, child:
                Column(
                    children: [
                  SizedBox(height: 7.h),
                  Container(
                    // margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Pallet.colorPrimary, width: 1),
                    ),
                    child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tabController.animateTo(0);
                                  currentTabIndex = 0;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 8),
                                height: 43,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border: currentTabIndex != 0
                                        ? Border.all(
                                        color: Pallet.deepGreen, width: 3)
                                        : Border.all(
                                        color: Pallet.deepGreen, width: 6),
                                    borderRadius: BorderRadius.circular(25),
                                    color: currentTabIndex != 0
                                        ? Pallet.colorWhite
                                        : Pallet.colorWhite),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Sessions",
                                        style: TextStyle(
                                          color: currentTabIndex != 1
                                              ? Pallet.deepGreen
                                              : Pallet.deepGreen,
                                          fontWeight: currentTabIndex != 1
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          fontSize: currentTabIndex != 1 ? 14 : 14,
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      currentTabIndex != 0
                                          ? SizedBox.shrink()
                                          : Icon(Icons.archive_rounded,
                                          color: Pallet.deepGreen)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),


                          /// Second tab is Activities Tab

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tabController.animateTo(1);
                                  currentTabIndex = 1;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 8),
                                height: 43,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border: currentTabIndex != 1
                                        ? Border.all(
                                        color: Pallet.colorPrimary, width: 3)
                                        : Border.all(
                                        color: Pallet.colorPrimary, width: 6),
                                    borderRadius: BorderRadius.circular(25),
                                    color: currentTabIndex != 1
                                        ? Pallet.colorWhite
                                        : Pallet.colorWhite),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Activities",
                                        style: TextStyle(
                                          color: currentTabIndex != 0
                                              ? Pallet.colorPrimary
                                              : Pallet.colorPrimary,
                                          fontWeight: currentTabIndex != 0
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          fontSize: currentTabIndex != 0 ? 14 : 14,
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      currentTabIndex != 1
                                          ? SizedBox.shrink()
                                          : Icon(Icons.circle_notifications,
                                          color: Pallet.colorPrimary)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          /// Third tab is Claire Love Tab

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tabController.animateTo(2);
                                  currentTabIndex = 2;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 8),
                                height: 43,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border: currentTabIndex != 2
                                        ? Border.all(
                                        color: Pallet.colorSecondary, width: 3)
                                        : Border.all(
                                        color: Pallet.colorSecondary, width: 6),
                                    borderRadius: BorderRadius.circular(25),
                                    color: currentTabIndex != 2
                                        ? Pallet.colorWhite
                                        : Pallet.colorWhite),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Loves",
                                        style: TextStyle(
                                          color: currentTabIndex != 2
                                              ? Pallet.colorSecondary
                                              : Pallet.colorSecondary,
                                          fontWeight: currentTabIndex != 2
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          fontSize: currentTabIndex != 2 ? 14 : 14,
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      currentTabIndex != 2
                                          ? SizedBox.shrink()
                                          : Icon(Icons.monetization_on_rounded,
                                          color: Pallet.colorSecondary)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [



                        StreamBuilder(
                          stream: visitedUsersSessions(),
                          builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                            if (session.connectionState == ConnectionState.waiting) {
                              return RotateImage(70, 70);
                            }
                            if (!session.hasData) {
                              return Center(
                                child: Text("No Session data",
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                        fontSize: 15.0,
                                        color: Pallet.colorBlack,
                                        //fontStyle: FontStyle.normal,
                                        fontWeight: FontWeight.w600)),
                              );
                            }
                            if (session.hasData) {
                              // clear list
                              _sessionList!.clear();

                              session.data!.docs.map((e) {
                                _sessionList!.add(Session.fromJson(e.data()));
                              }).toList();

                              return Scrollbar(
                                child: ListView(
                                  children: [

                                    // Top ad unit is here
                                    if(visitedUserTopOfSessionsBanner == null)
                                      SizedBox(height: 70)
                                    else
                                      Container(
                                        height: 60,
                                        child: AdWidget(ad: visitedUserTopOfSessionsBanner),
                                      ),


                                    ..._sessionList!
                                        .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),

                                    // Top ad unit is here
                                    if(visitedUserBottomOfSessionsBanner == null)
                                      SizedBox(height: 70)
                                    else
                                      Container(
                                        height: 60,
                                        child: AdWidget(ad: visitedUserBottomOfSessionsBanner),
                                      ),

                                  ],
                                ),
                              );
                            }
                            return Container();
                          },
                        ),



                        FutureBuilder(
                        future: getActivityByVisitedUser(),
                      builder: (context, AsyncSnapshot<List<UserActivityModel>> userActivity) {
                        if (userActivity.connectionState == ConnectionState.waiting) {
                          return RotateImage(70, 70);
                        }
                        if (!userActivity.hasData) {
                          return Center(
                            child: Text("There are no activities yet",
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                    fontSize: 15.0,
                                    color: Pallet.colorBlack,
                                    //fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w600)),
                          );
                        }

                        if (userActivity.hasError) {
                          return Container(
                            child: Text(userActivity.error.toString(),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                    fontSize: 15.0,
                                    color: Pallet.colorBlack,
                                    //fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w600)),
                          );
                        }

                        if (userActivity.hasData) {
                          return ListView(
                            children: [

                              // Top ad unit is here
                              if(visitedUserTopOfActivitiesBanner == null)
                                SizedBox(height: 70)
                              else
                                Container(
                                  height: 60,
                                  child: AdWidget(ad: visitedUserTopOfActivitiesBanner),
                                ),


                              ...userActivity.data!
                                  .map((element) => VisitedUserActivityCard(element: element,)
                              )
                                  .toList(),


                              // Top ad unit is here
                              if(visitedUserBottomOfActivitiesBanner == null)
                                SizedBox(height: 70)
                              else
                                Container(
                                  height: 60,
                                  child: AdWidget(ad: visitedUserBottomOfActivitiesBanner),
                                ),

                            ],
                          );
                        }
                        return Container();
                      }
                  ),



                        VisitedUserClaireLoves(visitedEgoName: visitedUser?.nickname.toString() ?? '', visitedUsersID: visitedUser?.userId.toString() ?? '',),
                      ],
                    ),
                  )
                ]),
                ))
          ],
        ),
      ),
    );
  }
}







class VisitedUserActivityCard extends StatelessWidget {
  UserActivityModel element;
  VisitedUserModel visiteduserModel = VisitedUserModel();

  VisitedUserActivityCard({Key? key, required this.element}) : super(key: key);

  getUser() async{
    userModel = await firebaseServices.getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    getUser();
    return Container(
      margin: EdgeInsets.all(5),
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(35)),
        elevation: 20,
        child: GestureDetector(
          onTap: () => PageRouter.gotoWidget(
              NotifiedSessionDetails(sessionId: element.sessionId),
              context),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  AppImages.appChatBg,
                ),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                ClipOval(
                child: CachedNetworkImage(
                  width: 30,
                  height: 30,
                  imageUrl: element.userAvatarUrl ?? "",
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  placeholder: (context, url) =>
                      CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Image.asset(
                    "assets/images/brown_boy_mask.png",
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              SizedBox(width: 4.w,),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(element.activityMessage.toString(),
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Pallet.colorSecondaryDark)),
                    Text(timeConverter(element.dateCreated!),
                        style: TextStyle(fontSize: 11.sp, color: Pallet.colorTextGray)),
                  ],
                ),
              )
            ],),
          ),
        ),
      ),
    );
  }

}

