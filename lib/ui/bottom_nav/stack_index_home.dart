import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
import 'package:dear_claire/ui/dairy/diary.dart';
import 'package:dear_claire/ui/ego-profile/profile.dart';
import 'package:dear_claire/ui/featured/all_featured.dart';
import 'package:dear_claire/ui/followed/followed.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shake/shake.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/helper.dart';
import '../routes/page_router_animation.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'destination.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomeDashboardPageState createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomePage>
    with TickerProviderStateMixin<HomePage> {
  var currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late WebViewController _webViewController;
  late ShakeDetector detector;
  String filePath = 'assets/web_games/tictactoe/index2.html';
  String tweets = 'assets/tweet/index.html';
  int _currentIndex = 0;
  late String _title;
  String userName = "";
  String userType = "";

  PageController _pageController = PageController(initialPage: 0);

  List<Widget> _body = [
    AllFeaturedPage(title: 'Dear Claire'),
    FollowedPage(title: 'Dear Claire'),
    DiaryPage(title: 'Dear Claire'),
    ChatRoomsPage(),
    EgoProfilePage(),
  ];

  launchEmailApp() {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dearclaireapp@gmail.com',
      query: encodeQueryParameters(
          <String, String>{'subject': 'Questions About Dear Claire'}),
    );

    launch(emailLaunchUri.toString());
  }



  String? getWhatsAppUrl(){
    return AppString.WHATSAPP_URL;
  }

  onContinueToWhatsAppClicked() {
    var whatsAppUrl = getWhatsAppUrl();
    launch(whatsAppUrl!);
  }

  _loadHtmlFromAssets() async {
    String fileHtmlContents = await rootBundle.loadString(filePath);
    _webViewController.loadUrl(Uri.dataFromString(fileHtmlContents,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }


  void setTabIndex(index) async {
    if (await firebaseServices.isUserSignIn(context))
      _pageController.animateToPage(
          index, duration: Duration(milliseconds: 1500),
          curve: Curves.elasticOut);
    switch(index) {
      case 0: { _title = 'Featured Sessions'; }
      break;
      case 1: { _title = 'Followed Sessions'; }
      break;
      case 2: { _title = 'Diary Sessions'; }
      break;
      case 3: { _title = 'Diary Rooms'; }
      break;
      case 4: { _title = 'Ego Profile'; }
      break;

    }
  }

  @override
  void initState() {
    _title = "Dear Claire";
    shakeDevice();
    super.initState();
  }

  shakeDevice() async {
    detector = ShakeDetector.waitForStart(
      onPhoneShake: () async {
        var _type = FeedbackType.error;
        Vibrate.feedback(_type);
        Fluttertoast.showToast(
          toastLength: Toast.LENGTH_LONG,
          msg: "Switching Ego",
          textColor: Colors.white,
          backgroundColor: Pallet.colorSplashScreen,
        );
        String id = await sharedPreference.getAlterEgoId();
        String accessCode = await sharedPreference.getAlterEgoAccessCode();
        print("Show Alter details:: $id || $accessCode");
        id.isNotEmpty && accessCode.isNotEmpty
            ? await firebaseServices.getUserAlterEgo(context, id, accessCode)
            : Navigator.of(context).pushReplacementNamed(AppRoutes.alterEgoLogin);
      },
      minimumShakeCount: 1,
    );
    await Future.delayed(Duration(seconds: 1), () {
      detector.startListening();
    });
  }

  dispose() {
    super.dispose();
    detector.stopListening();
  }

  @override
  Widget build(BuildContext context, {String? avatarUrl}) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Pallet.colorPrimary,
          centerTitle: false,
          title: Text(_title,
              textAlign: TextAlign.start,
              maxLines: 1,
              style: GoogleFonts.lato(
                  fontSize: 25.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          actions: [
            CupertinoButton(
                child: Icon(
                  Icons.search,
                  color: Pallet.colorWhite,
                ),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AppRoutes.searchPage);
                })
          ],
          leading: IconButton(
              icon: Icon(
                Icons.menu,
                color: Pallet.colorWhite,
              ),
              onPressed: () {
                _openEndDrawer();
              }),
        ),
        body: Stack(
          children: [
            PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index){
              setState(() {
                _currentIndex  = index;
              });
            },
            children: _body
          ),
      ]
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Pallet.colorBottomNav,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          iconSize: 22,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          onTap: (int index) => setTabIndex(index),
          items: allDestinations.map((Destination destination) {
            return BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  destination.icon,
                ),
                activeIcon: SvgPicture.asset(
                  destination.activeIcon,
                ),
                backgroundColor: destination.color,
                label: destination.title);
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          backgroundColor: Pallet.colorSplashScreen,
          onPressed: () {
            if (currentUser == null) {
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.authSelection);
            } else {
              Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
            }
          },
          tooltip: 'Hi, Darling!',
          child: RotateImage(45, 45),
        ),
        drawer: Drawer(
          child: Container(
            width: 200.w,
            color: Pallet.colorSecondaryDark,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: Pallet.colorPrimary,
                    ),
                    accountEmail: Text(
                    "You'll never be not truly loved.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    accountName: Text(userName,
                        style: TextStyle(color: Pallet.colorWhite,
                            fontSize: 19.0, fontWeight: FontWeight.w700,)),
                    currentAccountPicture: FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(currentUser?.uid)
                          .get(),
                      builder: (_, snapshot) {
                        if (snapshot.hasData) {
                          var data = snapshot.data!.data();
                          userName = data?["nickname"] ?? " ";
                          userType = data?["userType"] ?? " ";
                          avatarUrl = data?["avatarUrl"] ?? " ";
                          return
                            GestureDetector(
                              onTap: () {
                                lockAlertDialog(context);
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
                                      width: 60,
                                      height: 60,
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
                            );
                        }

                        return CircularProgressIndicator();
                      },
                    ),

                    otherAccountsPictures: [
                      InkWell(
                          onTap: () async {
                            String id = await sharedPreference.getAlterEgoId();
                            String accessCode = await sharedPreference.getAlterEgoAccessCode();
                            print("Show Alter details:: $id || $accessCode");
                            id.isNotEmpty && accessCode.isNotEmpty ? await firebaseServices.getUserAlterEgo(context,id, accessCode)
                                : Navigator.of(context)
                                .pushNamed(AppRoutes.alterEgoLogin);
                          },
                          child: Image.asset(
                            "assets/images/claire_icon.png",
                            height: 50,
                            width: 50,
                          ),
                      ),

                      GestureDetector(
                        onTap: () async {
                          String id = await sharedPreference.getAlterEgoId();
                          String accessCode = await sharedPreference.getAlterEgoAccessCode();
                          print("Show Alter details:: $id || $accessCode");
                          id.isNotEmpty && accessCode.isNotEmpty ? await firebaseServices.getUserAlterEgo(context,id, accessCode)
                              : Navigator.of(context)
                              .pushNamed(AppRoutes.alterEgoLogin);
                        },
                        child: Text(
                          userType == 'REGULAR'? 'Ego' :
                          userType == 'ADMIN'? 'Alter Ego' :
                          userType == 'SUPER_ADMIN'? 'Super Ego' :
                          'Ego',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Pallet.colorSecondaryDark,
                          ),
                        ),
                      ),
                    ],

                  ),

                  SizedBox(height: 28,),
                  ListTile(
                    title: Text("How Claire Works",
                        style: TextStyle(color: Pallet.colorWhite)),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.howClaireWorks);
                    },
                    leading: Icon(Icons.info_rounded,
                        color: Pallet.colorWhite),
                  ),
                  SizedBox(height: 18,),
                  ListTile(
                    title: Text("Request Alter Ego Mode     🔥",
                        style: TextStyle(color: Pallet.colorWhite)),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks);
                    },
                    leading: Icon(Icons.star, color: Pallet.colorWhite),
                  ),
                  SizedBox(height: 18,),
                  ListTile(
                    title: Text("Send Claire To Someone",
                        style: TextStyle(color: Pallet.colorWhite)),
                    onTap: ()=>sendClaireToSomeone(),
                    leading: Icon(Icons.share, color: Pallet.colorWhite),
                  ),
                  SizedBox(height: 18,),
                  ListTile(
                    title: Text("Play Games With Claire",
                        style: TextStyle(color: Pallet.colorWhite)),
                    onTap: (){Navigator. pop(context);
                    Navigator.of(context).pushNamed(AppRoutes.games);
                    },
                    leading: Icon(Icons.gamepad_rounded, color: Pallet.colorWhite),
                  ),
                  SizedBox(height: 18,),
                  ListTile(
                    title: Text("Contact Us",
                        style: TextStyle(color: Pallet.colorWhite)),
                    onTap: () =>launchEmailApp(),
                    leading: Icon(Icons.email, color: Pallet.colorWhite),
                  ),
                  SizedBox(height: 10,),
                  
                  Container(
                    height: 290,
                    child: WebView(
                      initialUrl: '',
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController webViewController) {
                        _webViewController = webViewController;
                        _loadHtmlFromAssets();
                      },
                    ),
                  ),
                  SizedBox(height: 18,),

                  Container(
                    height: 650,
                    child: WebView(
                      initialUrl: 'https://clairetweets.netlify.app',
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController webViewController) {
                        _webViewController = webViewController;
                        //_loadTweetFromAssets();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }


  lockAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Ego Profile"),
      onPressed:  () {
        String thisEgoName = "Guest View Of Your Ego";
        String? thisUser = currentUser?.uid.toString();
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: thisUser.toString(),
                visitedEgoName: thisEgoName),
            context);
        print("Visited User ID::: $thisEgoName");
        },
    );

    Widget continueButton = TextButton(
      child: Text("Lock Out."),
      onPressed:  () {
        firebaseServices.logUserOut(context);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Lock Diary Or Visit Your Ego Profile?"),
      content: Text(AppString.lock_out_ego_alert_note),
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


}
