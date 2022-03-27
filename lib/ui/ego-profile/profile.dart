import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/data/models/profile_page_model.dart';
import 'package:dear_claire/data/models/session_model.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
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
import 'package:dear_claire/utils/textFormatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Search/search_page.dart';
import '../create_session/create_session_page.dart';
import 'clairevatar.dart';


class EgoProfilePage extends StatefulWidget {
  const EgoProfilePage({Key? key,}) : super(key: key);

  @override
  _EgoProfilePageState createState() => _EgoProfilePageState();
}


class _EgoProfilePageState extends State<EgoProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mantraController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  GlobalKey<FlipCardState> cardKey2 = GlobalKey<FlipCardState>();



  @override
  void initState() {
    super.initState();
    getUser();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print(_tabController.index);
    });
    _createEgoNameInterstitialAd();
    _createEgoMantraInterstitialAd();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    _interstitialAd?.dispose();
    _interstitialAd2?.dispose();
  }

  int currentTabIndex = 0;
  //String? userName;
  UserModel userModel = UserModel();
  SessionModel sessionModel = SessionModel();
  User? currentUser = FirebaseAuth.instance.currentUser;
  UserModel? user;

  getUser() async {
    userModel = await firebaseServices.getUserInfo();
  }

  /// Edit nickname

  Future<void> editNickName() async {
    final nickname = _nicknameController.text;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .update({
      "nickname": nickname,
    },
    );
    logger.d('Successfully saved new nickname');
    print('Nickname: $nickname');

    getUserNickname();
  }

  getUserNickname() async {
    userModel = await firebaseServices.getUserInfo();
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

  InterstitialAd? _interstitialAd;
  InterstitialAd? _interstitialAd2;
  int _interstitialLoadAttempts = 0;

  // Create interstitial ad.

  void _createEgoNameInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-3940256099942544/1033173712" :
      Platform.isIOS? "ca-app-pub-3940256099942544/4411468910" :
      '',
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
            _createEgoNameInterstitialAd();
          }
        },
      ),
    );
  }

  void _createEgoMantraInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-3940256099942544/1033173712" :
      Platform.isIOS? "ca-app-pub-3940256099942544/4411468910" :
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

  void _showEgoNameInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createEgoNameInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createEgoNameInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
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





  /// Profile Cover header

  Widget _pageHeader(
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
                        GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil<dynamic>(
                              context,
                              MaterialPageRoute<dynamic>(
                                builder: (BuildContext context) => EditClairevatar(),
                              ),
                                  (route) => false,//if you want to disable back feature set to false
                            );
                          },
                          child: Container(
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
                            child: IconButton(
                              padding: EdgeInsets.only(right: 1),
                                icon: Icon(Icons.edit),
                                iconSize: 15,
                                color: Pallet.colorWhite,
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.editClairevatar);
                              }
                            ),
                          ),
                        ),

                        //Clairevatar Container is here
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.editClairevatar);
                          },
                          child: Container(
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
                                followCount ?? "---",
                                style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black),
                              ),

                              Text(
                                "Follows",
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
                    child: FlipCard(
                      key: cardKey2,
                      direction: FlipDirection.VERTICAL, // default
                      front: Stack(
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

                          Icon(Icons.edit_rounded,
                              color: Pallet.colorWhite,
                          size: 16,
                          ),

                        ],
                      ),
                      back: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 4),
                            height: 40,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Pallet.colorPrimary),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  new ConstrainedBox(
                                    constraints: new BoxConstraints(
                                      minWidth: 125,
                                      maxWidth: 190,
                                      minHeight: 40.0,
                                      maxHeight: 60.0,
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
                                          keyboardType: TextInputType.text,
                                          maxLines: 1,
                                          controller: _nicknameController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                            EdgeInsets.only(left: 13.0, bottom: 18, right: 13.0),
                                            hintText: "...change ego name...",
                                            hintStyle: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Pallet.colorSecondary,
                                              fontSize: 13,
                                            ),
                                            counterText: '',
                                          ),
                                          maxLength: 35,
                                        ),
                                      ),
                                    ),
                                  ),

                                  FloatingActionButton(
                                      mini: true,
                                      backgroundColor: Pallet.colorWhite,
                                      child: SvgPicture.asset(
                                        AppImages.appSend,
                                        color: Pallet.colorPrimary,
                                        height: 20,
                                      ),
                                      onPressed: () {
                                        if (_nicknameController.text.isNotEmpty)
                                          editNickName();
                                        _nicknameController.clear();
                                        if(cardKey2.currentState != null) { //null safety
                                          cardKey2.currentState!.toggleCard();
                                        }
                                        setState(() {

                                        });
                                        showToast(AppString.change_ego_name);

                                        Future.delayed(Duration(seconds: 3), () {
                                          _showEgoNameInterstitialAd();
                                        });
                                      }
                                      ),

                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Spacer(flex: 1,),


                  /// Here is the Ego badge showing user's usertype

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                            left: 8, right: 4, top: 4, bottom: 4),
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
                            topBarWidget(),
                          ],
                        ),
                      ),
                      SizedBox(width: 6,)
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
                              :Pallet.colorBlue,
                        ),
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

                                        Future.delayed(Duration(seconds: 3), () {
                                          _showEgoMantraInterstitialAd();
                                        });                                      },
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
    print("User nickname::: ${userModel.nickname}");
    print("User type::: ${userModel.userType}");

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Material(
                elevation: 10,
                child: FutureBuilder(
                    future: firebaseServices.getEgoProfileInfo(),
                    builder:
                        (context, AsyncSnapshot<EgoProfileInfo> profileInfo) {
                      if (profileInfo.connectionState ==
                          ConnectionState.waiting) {
                        return RotateImage(50, 50);
                      }
                      if (!profileInfo.hasData) {
                        return _pageHeader();
                      }

                      if (profileInfo.hasError) {
                        return _pageHeader();
                      }

                      if (profileInfo.hasData) {
                        return _pageHeader(
                            userName: profileInfo.data!.userModel!.nickname,
                            sessionCount: profileInfo.data!.sessionCount,
                            advisesCount: profileInfo.data!.advisesCount,
                            followCount: profileInfo.data!.followCount,
                            userType: profileInfo.data!.userModel!.userType,
                            avatarUrl: profileInfo.data!.userModel!.avatarUrl,
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
                length: 3, child: Column(children: [
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
                                      color: Pallet.colorPrimary, width: 3)
                                  : Border.all(
                                      color: Pallet.colorPrimary, width: 6),
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
                                  "Activity",
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
                                currentTabIndex != 0
                                    ? SizedBox.shrink()
                                    : Icon(Icons.circle_notifications,
                                        color: Pallet.colorPrimary)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),


                        /// Second tab is Archive Tab

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
                                      color: Pallet.deepGreen, width: 3)
                                      : Border.all(
                                      color: Pallet.deepGreen, width: 6),
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
                                      "Archive",
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
                                    currentTabIndex != 1
                                        ? SizedBox.shrink()
                                        : Icon(Icons.archive_rounded,
                                        color: Pallet.deepGreen)
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
                      ActivityWidget(),
                      ArchiveWidget(),
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

/// A top bar widget for logout and switch ego. Might remove soon.

class topBarWidget extends StatelessWidget {
  const topBarWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FocusedMenuHolder(
              menuWidth: MediaQuery.of(context).size.width * 0.30,
              menuItemExtent: 45,
              menuBoxDecoration: BoxDecoration(
                  color: Pallet.colorPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              duration: Duration(milliseconds: 100),
              animateMenuItems: true,
              blurBackgroundColor: Pallet.colorPrimary,
              openWithTap: true,
              // Open Focused-Menu on Tap rather than Long Press
              menuOffset: 10.0,
              // Offset value to show menuItem from the selected item
              bottomOffsetHeight: 80.0,
              // Offset height to consider, for showing the menu item ( for example bottom navigation bar), so that the popup menu will be shown on top of selected item.
              menuItems: <FocusedMenuItem>[
                FocusedMenuItem(title: Text("< SWITCH >", style: TextStyle(color: Pallet.colorSecondary),),
                  onPressed: () async {
                  String id = await sharedPreference.getAlterEgoId();
                  String accessCode = await sharedPreference.getAlterEgoAccessCode();
                  print("Show Alter details:: $id || $accessCode");
                  id.isNotEmpty && accessCode.isNotEmpty ? await firebaseServices.getUserAlterEgo(context,id, accessCode)
                      : Navigator.of(context)
                      .pushNamed(AppRoutes.alterEgoLogin);
                },),
                FocusedMenuItem(
                    title: Text(
                      "Lock Out",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onPressed: () async =>
                        firebaseServices.logUserOut(context)),
              ],
              onPressed: () {},
              child: Icon(Icons.unfold_more_sharp,
                color: Pallet.colorWhite,
                size: 19,
              )
          )
        ],
      ),
    );
  }
}
