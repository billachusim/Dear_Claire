import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/alter_ego/advised_page.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_all_page.dart';
import 'package:clairediary/ui/alter_ego/chatrooms.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shake/shake.dart';
import 'package:vibration/vibration.dart';
import '../../utils/constant.dart';
import '../../utils/helper.dart';
import '../../utils/strings.dart';
import '../ego-profile/claire_loves.dart';
import 'alter_ego_calls_page.dart';
import 'flagged_sessions_page.dart';

class AlterEgoHomePage extends StatefulWidget {
  const AlterEgoHomePage({Key? key}) : super(key: key);

  @override
  _AlterEgoHomePageState createState() => _AlterEgoHomePageState();
}

class _AlterEgoHomePageState extends State<AlterEgoHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _callSubscription;
  StreamSubscription? _liveSessionSubscription;
  Stream<int>? _incomingCallCountStream;
  PageController? _pageController;
  int currentIndex = 0;
  late String _title;
  String userName = "";
  String userType = "";
  String avatarUrl = "";
  var currentUser = FirebaseAuth.instance.currentUser;

  late ShakeDetector detector;


  @override void initState() {
    super.initState();
    _title = "Alter Ego Mode";
    _pageController = PageController(keepPage: true);
    shakeDevice();

    final adminId = "claire_admin";
    List<String> activeStatuses = ['dialing', 'ringing', 'connecting'];

    Stream<int> audioCountStream = FirebaseFirestore.instance
        .collection('companion_calls')
        .where('receiverId', isEqualTo: adminId)
        .where('status', whereIn: activeStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    Stream<int> videoCountStream = FirebaseFirestore.instance
        .collection('live_sessions')
        .where('receiverId', isEqualTo: adminId)
        .where('status', whereIn: activeStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    _incomingCallCountStream = Rx.combineLatest2(
        audioCountStream, videoCountStream, (a, b) => a + b);
  }


  void setTabIndex(index) async {
    if (await firebaseServices.isUserSignIn(context))
      _pageController?.animateToPage(index,
          duration: Duration(milliseconds: 1500), curve: Curves.elasticOut);
    switch (index) {
      case 0:
        {
          _title = 'Incoming Calls';
        }
        break;
      case 1:
        {
          _title = 'Advising';
        }
        break;
      case 2:
        {
          _title = 'All';
        }
        break;
      case 3:
        {
          _title = 'Flagged';
        }
        break;
      case 4:
        {
          _title = 'Rooms';
        }
        break;
      case 5:
        {
          _title = 'Loves';
        }
        break;
    }
  }



  shakeDevice() {
    detector = ShakeDetector.autoStart(
      // 1. INCREASED SENSITIVITY: Higher value means a harder shake is needed.
      // Default is ~1.5. Let's try 2.5 or 3.0 for a more deliberate shake.
      shakeThresholdGravity: 5.5,

      onPhoneShake: (ShakeEvent event) {
        () async {
          if (!mounted) return;

          // Vibrate to give user feedback
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate();
          }

          Fluttertoast.showToast(
            toastLength: Toast.LENGTH_SHORT, // Shorter toast
            msg: "Returning to Ego...",
            textColor: Colors.white,
            backgroundColor: Pallet.colorSplashScreen,
          );

          // 2. CRITICAL FIX: Stop listening for shakes on THIS page FIRST.
          detector.stopListening();

          // Add a small delay to ensure the event loop is clear
          await Future.delayed(const Duration(milliseconds: 100));

          // 3. Navigate AFTER the detector is stopped.
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }();
      },
      minimumShakeCount: 1,
    );
  }

  dispose() {
    _pageController!.dispose();
    detector.stopListening();
    super.dispose();
  }

  String? getWhatsAppUrl() {
    return AppString.WHATSAPP_URL;
  }

  onContinueToWhatsAppClicked() {
    var whatsAppUrl = getWhatsAppUrl();
    launch(whatsAppUrl!);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
            body: Stack(children: [
              PageView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                children: [
                  AlterEgoCallsPage(),
                  AdvisedPage(),
                  TheAllPage(),
                  FlaggedDiariesPage(),
                  ChatRooms(),
                  ClaireLoves(),
                ],
              ),
            ]),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(color: Colors.black),
              height: 60,
              width: double.infinity,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                backgroundColor: Pallet.colorBottomNav,
                selectedLabelStyle: TextStyle(color: Pallet.colorWhite),
                unselectedLabelStyle: TextStyle(color: Pallet.colorWhite),
                currentIndex: currentIndex,
                selectedItemColor: Pallet.colorWhite,
                showUnselectedLabels: false,
                onTap: (int index) => setTabIndex(index),
                // A6A6B1
                items: [
                  // In build() -> BottomNavigationBar -> items
                  BottomNavigationBarItem(
                    icon: StreamBuilder<int>(
                      stream: _incomingCallCountStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        final hasCalls = count > 0;

                        // Use the Badge widget
                        return Badge(
                          label: Text(count.toString()),
                          isLabelVisible: hasCalls, // Only show badge if there are calls
                          child: Icon(Icons.call,
                              color: currentIndex == 0
                                  ? Pallet.colorWhite
                                  : Pallet.colorSecondary),
                        );
                      },
                    ),
                    label: 'Calls',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite,
                        color: currentIndex == 1
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Advising',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_rounded,
                        color: currentIndex == 2
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'All',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.flag_circle_rounded,
                        color: currentIndex == 3
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Flagged',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.message_rounded,
                        color: currentIndex == 4
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Rooms',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.attach_money_rounded,
                        color: currentIndex == 5
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
                      decoration: BoxDecoration(
                        color: Pallet.colorPrimary,
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
                      accountName: Text(
                          userType == 'REGULAR'
                              ? 'Ego'
                              : userType == 'ADMIN'
                                  ? 'Alter Ego'
                                  : userType == 'SUPER_ADMIN'
                                      ? 'Super Ego'
                                      : 'Ego',
                          style: TextStyle(
                            color: Pallet.colorWhite,
                            fontSize: 19.0,
                            fontWeight: FontWeight.w700,
                          )),
                      currentAccountPicture:
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                            return Container(
                              decoration: BoxDecoration(
                                color: userType == 'REGULAR'
                                    ? Pallet.colorPrimary
                                    : userType == 'ADMIN'
                                        ? Pallet.colorSecondary
                                        : userType == 'SUPER_ADMIN'
                                            ? Pallet.colorSecondary
                                            : Pallet.colorBlue,
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
                            Navigator.of(context).pushNamed(AppRoutes.home);
                          },
                          child: CachedNetworkImage(
                              width: 60,
                              height: 60,
                              imageUrl: avatarUrl,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
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
                                    "assets/images/Speak_No_Evil_Monkey_Emoji.png",
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
                      onTap: () {},
                      leading: Icon(Icons.settings, color: Pallet.colorWhite),
                    ),
                    ListTile(
                      title: Text("How Claire Works",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context)
                            .pushNamed(AppRoutes.howClaireWorks);
                      },
                      leading:
                          Icon(Icons.info_rounded, color: Pallet.colorWhite),
                    ),
                    ListTile(
                      title: Text("Send Claire to Someone",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () => sendClaireToSomeone(),
                      leading: Icon(Icons.share, color: Pallet.colorWhite),
                    ),
                    SizedBox(
                      height: 18,
                    ),
                    ListTile(
                      title: Text("Contact Us",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () => onContinueToWhatsAppClicked(),
                      leading: Icon(Icons.email, color: Pallet.colorWhite),
                    ),
                  ],
                ),
              ),
            )));
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  lockAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No, Wait."),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Yes, Lock Out."),
      onPressed: () {
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
