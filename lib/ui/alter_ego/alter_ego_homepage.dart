import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/alter_ego/advised_page.dart';
import 'package:dear_claire/ui/alter_ego/alter_ego_all_page.dart';
import 'package:dear_claire/ui/alter_ego/chatrooms.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shake/shake.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../../utils/constant.dart';
import '../../utils/helper.dart';
import '../../utils/strings.dart';
import '../ego-profile/claire_loves.dart';
import 'flagged_sessions_page.dart';

class AlterEgoHomePage extends StatefulWidget {
  const AlterEgoHomePage({Key? key}) : super(key: key);

  @override
  _AlterEgoHomePageState createState() => _AlterEgoHomePageState();
}

class _AlterEgoHomePageState extends State<AlterEgoHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController? _pageController;
  int currentIndex = 0;
  late String _title;
  String userName = "";
  String userType = "";
  String avatarUrl = "";
  var currentUser = FirebaseAuth.instance.currentUser;

  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    _title = "Alter Ego Mode";
    _pageController = PageController(keepPage: true);
    shakeDevice();
  }


  void setTabIndex(index) async {
    if (await firebaseServices.isUserSignIn(context))
      _pageController?.animateToPage(
          index, duration: Duration(milliseconds: 1500),
          curve: Curves.elasticOut);
    switch(index) {
      case 0: { _title = 'Advising'; }
      break;
      case 1: { _title = 'All'; }
      break;
      case 2: { _title = 'Flagged'; }
      break;
      case 3: { _title = 'Rooms'; }
      break;
      case 4: { _title = 'Loves'; }
      break;

    }
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
       Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      },
      minimumShakeCount: 1,
    );
    await Future.delayed(Duration(seconds: 1), () {
      detector.startListening();
    });
  }

  dispose() {
    _pageController!.dispose();
    detector.stopListening();
    super.dispose();
  }

  String? getWhatsAppUrl(){
    return AppString.WHATSAPP_URL;
  }

  onContinueToWhatsAppClicked() {
    var whatsAppUrl = getWhatsAppUrl();
    launch(whatsAppUrl!);
  }

  @override
  Widget build(BuildContext context,) {
    return SafeArea(
        child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Pallet.colorBottomNav,
              title: Text(_title,
                  style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
              leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Pallet.colorSecondary,
                  ),
                  onPressed: () {
                    _openEndDrawer();
                  }),
              actions: [
                Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Pallet.colorBottomNav,
                    ),
                    child: Icon(Icons.search, color: Pallet.colorSecondary))
              ],
            ),
            body: Stack(
              children: [
                PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                children: [
                  AdvisedPage(),
                  TheAllPage(),
                  FlaggedDiariesPage(),
                  ChatRooms(),
                  ClaireLoves(),
                ],
              ),
          ]
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(color: Colors.black),
              height: 60,
              width: double.infinity,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true, backgroundColor: Pallet.colorBottomNav,
                selectedLabelStyle: TextStyle(color: Pallet.colorWhite),
                unselectedLabelStyle: TextStyle(color: Pallet.colorWhite),
                currentIndex: currentIndex,
                selectedItemColor: Pallet.colorWhite,
                showUnselectedLabels: false,
                onTap: (int index) => setTabIndex(index),
                // A6A6B1
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite,
                        color: currentIndex == 0
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Advising',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_rounded,
                        color: currentIndex == 1
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'All',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.flag_circle_rounded,
                        color: currentIndex == 2
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Flagged',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.message_rounded,
                        color: currentIndex == 3
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Rooms',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.attach_money_rounded,
                        color: currentIndex == 4
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Loves',
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: "newSessionFromAEM",
              backgroundColor: Pallet.colorSecondary,
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
              },
              tooltip: 'Claire',
              child: RotateImage(45, 45),
            ),
            drawer: Drawer(
              child: Container(
                width: 200.w,
                color: Pallet.colorSecondaryDark,
                child: Column(
                  children: [
                    UserAccountsDrawerHeader(
                      decoration: BoxDecoration(color: Pallet.colorPrimary,
                      ),
                      accountEmail: Text(
                        "Influence the world positively.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      accountName: Text(userType == 'REGULAR'? 'Ego' :
                      userType == 'ADMIN'? 'Alter Ego' :
                      userType == 'SUPER_ADMIN'? 'Super Ego' :
                      'Ego',
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
                                  child: RotateImage(75.h, 75.w)),
                                );
                          }

                          return CircularProgressIndicator();
                        },
                      ),

                      otherAccountsPictures: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.home);
                          },
                          child: CachedNetworkImage(
                              width: 60,
                              height: 60,
                              imageUrl: avatarUrl,
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

                        GestureDetector(
                          onTap: () async {
                            lockAlertDialog(context);
                          },
                          child: Text(
                            "LOCK-OUT",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Pallet.colorSecondaryDark,
                            ),
                          ),
                        ),
                      ],

                    ),
                    //SizedBox(height: 30.h,),
                    ListTile(
                      title: Text("Settings",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () {

                      },
                      leading: Icon(Icons.settings, color: Pallet.colorWhite),
                    ),
                    ListTile(
                      title: Text("How Claire Works",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () {
                        Navigator. pop(context);
                        Navigator.of(context).pushNamed(AppRoutes.howClaireWorks);
                      },
                      leading: Icon(Icons.info_rounded,
                          color: Pallet.colorWhite),
                    ),
                    ListTile(
                      title: Text("Send Claire to Someone",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: ()=>sendClaireToSomeone(),
                      leading: Icon(Icons.share, color: Pallet.colorWhite),
                    ),
                    SizedBox(height: 18,),
                    ListTile(
                      title: Text("Contact Us",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () =>onContinueToWhatsAppClicked(),
                      leading: Icon(Icons.email, color: Pallet.colorWhite),
                    ),
                  ],
                ),
              ),
            )
        )
    );
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  lockAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No, Wait."),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Yes, Lock Out."),
      onPressed:  () {
        firebaseServices.logUserOut(context);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Close and Lock Your Diary?"),
      content: Text(AppString.lock_out_alert_note),
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
