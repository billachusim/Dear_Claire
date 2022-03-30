import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_profile_page_model.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_model.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/data/models/session_model.dart';
import 'package:dear_claire/ui/ego-profile/acvitity.dart';
import 'package:dear_claire/ui/ego-profile/archive.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/user_activity_model.dart';
import '../../utils/constant.dart';
import '../../widgets/ego_mode_session_card.dart';
import '../Search/search_page.dart';
import '../featured/model/comment_session_model.dart';
import '../featured/model/session.dart';
import '../featured/widget/post_details_widget.dart';
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



class _VisitedUserEgoProfilePageState extends State<VisitedUserEgoProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mantraController = TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  GlobalKey<FlipCardState> cardKey2 = GlobalKey<FlipCardState>();




  @override
  void initState() {
    super.initState();
    getVisitedUser();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int currentTabIndex = 0;
  //VisitedUserModel visitedUser = VisitedUserModel();
  SessionModel sessionModel = SessionModel();
  User? currentUser = FirebaseAuth.instance.currentUser;
  VisitedUserModel? visitedUser = VisitedUserModel();
  String? visitedUsersID;
  String? _visitedUsersId;
  List<Session>? _sessionList = [];



  getVisitedUser() async {
    visitedUserModel = await getVisitedUserInfo();
  }


  /// Query Ego stream from Firestore

  final Stream<QuerySnapshot> _egoStream = FirebaseFirestore.instance
      .collection('ego_stream')
      .orderBy('egoTime', descending: true)
      .limitToLast(50)
      .snapshots();


  /// Save Ego mantra

  Future<void> saveEgoMessage() async {
    final egoMessage = _mantraController.text;
    final egoTime = FieldValue.serverTimestamp();
    final egoName = userModel.nickname;
    final egoImage = userModel.avatarUrl;
    final userId = userModel.userId;
    FirebaseFirestore.instance
        .collection('ego_stream')
    //.doc(currentUser?.uid)
        .add({
      "egoMessage": egoMessage,
      "egoTime": egoTime,
      "egoName": egoName,
      "egoImage": egoImage,
      "userId": userId,
    },
      //SetOptions(merge: true)
    );
    logger.d('Successfully saved an Ego message');
    print('Ego Message: $egoMessage');

  }

  /// Get Visited Ego User info
  Future<VisitedUserModel> getVisitedUserInfo() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(widget.visitedUsersID)
        .get();

    var visitedUser = VisitedUserModel.fromFirestore(response.data() as Map<String, dynamic>);
    logger.d('Successfully got the visited user model');
    print('Visited user is: $visitedUser');
    return visitedUser;
  }

  /// Get sessions from the category and have been featured
  Future<DocumentSnapshot<Map<String, dynamic>>> getVisitedUserProfile() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .doc(widget.visitedUsersID)
        .get();
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


  /// Visited User Ego Profile Info Here


  Future<VisitedEgoProfileInfo> getVisitedUserEgoProfileInfo()async{
    VisitedEgoProfileInfo visitedProfileInfo = VisitedEgoProfileInfo();
    _visitedUsersId = widget.visitedUsersID;
    visitedUser = await getVisitedUserInfo();
    //visitedUserInfo = await getVisitedUserInfo();

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
      sessionCount: _sessionList.length.toString(),
      advisesCount: _advisesList.length.toString(),
      followCount: _followsList.length.toString(),
    );
    return visitedProfileInfo;

  }




  /// Profile Cover header

  Widget _visitedPageHeader(
      {String? avatarUrl, String? userName, String? userType,
        var sessionCount, var followCount, var advisesCount})
  {
    return Material(
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 4),
            Center(
              child: Row(
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
                  SizedBox(
                    width: 25,
                  ),

                  // The count columns are here
                  Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        SizedBox(
                          width: 30,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              advisesCount ?? "---",
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
                        SizedBox(
                          width: 30,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              followCount ?? "---",
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
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 2,
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
              ],
            ),

            SizedBox(
              height: 2,
            ),



            /// Front card: Write Ego mantra and send to stream


            Container(
              width: 385,
              height: 100,
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
                                userType == 'REGULAR'? 'Ego Mantra:' :
                                userType == 'ADMIN'? 'Alter Ego Mantra:' :
                                userType == 'SUPER_ADMIN'? 'Super Ego Mantra:' :
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
                                    child: new Scrollbar(
                                      child: Container(
                                        padding: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          color: Pallet.colorWhite,
                                        ),
                                        child: TextField(
                                          cursorColor: Pallet.colorSplashScreen,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 2,
                                          controller: _mantraController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                            EdgeInsets.only(left: 13.0, right: 13.0, top: 20),
                                            hintText: "...write a new ego mantra...",
                                            hintStyle: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Pallet.colorSecondary,
                                              fontSize: 14,
                                            ),
                                            counterText: '',
                                          ),
                                          maxLength: 160,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                FloatingActionButton(
                                    onPressed: () {
                                      if (userModel.nickname != null)
                                        if (_mantraController.text.isNotEmpty)
                                          saveEgoMessage();
                                      _mantraController.clear();
                                      if(cardKey.currentState != null) { //null safety
                                        cardKey.currentState!.toggleCard();
                                      }
                                      showToast(AppString.change_ego_mantra);
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
                              stream: _egoStream,
                              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Something went wrong');
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text("Loading");
                                }

                                return ListView(
                                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                                    return ListTile(
                                      leading: ClipOval(
                                        child: CachedNetworkImage(
                                          width: 35,
                                          height: 40,
                                          imageUrl: data['egoImage'],
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
                                      title: Text(data['egoName'],
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
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.visitedEgoName,
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
                        sessionCount: visitedProfileInfo.data!.sessionCount,
                        advisesCount: visitedProfileInfo.data!.advisesCount,
                        followCount: visitedProfileInfo.data!.followCount,
                        userType: visitedProfileInfo.data?.userType,
                        avatarUrl: visitedProfileInfo.data?.visitedUserModel?.avatarUrl,
                      );
                    }
                    return Container();
                  }
              ),
            ),


            /// The three Ego page tabs are here
            /// First tab is Activity Tab

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
                                        : null),
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
                                        : null),
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
                                        : null),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Claire Love",
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
                                    ..._sessionList!
                                        .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
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
                              ...userActivity.data!
                                  .map((element) => VisitedUserActivityCard(element: element,)
                              )
                                  .toList(),
                            ],
                          );
                        }
                        return Container();
                      }
                  ),



                        SearchPage(title: 'Search Claire',),
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
    print("show User info $userModel");
    return Container(
      margin: EdgeInsets.all(5),
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(35)),
        elevation: 20,
        child: GestureDetector(
          onTap: () => PageRouter.gotoWidget(
              PostDetailsWidget(sessionId: element.sessionId),
              context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            padding: EdgeInsets.all(8),
            child: Row(children: [
              Icon(
                Icons.notifications_active_rounded,
                color: Pallet.colorPrimary,
                size: 26,
              ),
              SizedBox(width: 8.w,),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  element.userId == userModel.userId && element.clientId == userModel.userId ?
                  Text("You ${element.activityType}ed on this session",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold,))
                      : element.userId == userModel.userId && element.clientId == userModel.userId ?
                  Text("Someone ${element.activityType}ed on your session",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold,))
                      : Text("${element.clientNickname} ${element.activityType}ed on this session",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold,)),
                  Text(timeConverter(element.dateCreated!),
                      style: TextStyle(fontSize: 11.sp, color: Pallet.colorTextGray)),
                ],)
            ],),
          ),
        ),
      ),
    );
  }

}

