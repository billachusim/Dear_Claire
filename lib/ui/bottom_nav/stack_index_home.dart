import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
import 'package:dear_claire/ui/dairy/diary.dart';
import 'package:dear_claire/ui/ego-profile/profile.dart';
import 'package:dear_claire/ui/followed/followed.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/featured/featured_session_screen.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/helper.dart';
import '../splash_screen/custom_rotate_bacground.dart';
import 'destination.dart';

class HomePage extends StatefulWidget {
  @override
  _HomeDashboardPageState createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomePage>
    with TickerProviderStateMixin<HomePage> {
  var currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  PageController _pageController = PageController(initialPage: 0);

  List<Widget> _body = [
    FeaturedPage(title: 'Dear Claire'),
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


  void _launchInstagram() async =>
      await canLaunch("https://instgram.com/socialfaculty")
          ? await launch("https://instgram.com/socialfaculty")
          : throw 'Could not launch Instagram';

  void _launchShareClaire() async =>
      await canLaunch(shareClaireUrl)
          ? await launch(shareClaireUrl)
          : throw 'Could not launch PlayStore';


  String? getWhatsAppUrl(){
    return AppString.WHATSAPP_URL;
  }

  onContinueToWhatsAppClicked() {
    var whatsAppUrl = getWhatsAppUrl();
    launch(whatsAppUrl!);
  }

  static const String phoneNumber = "+2348188578955";
  static const String claireEmailAddress = "thesocialfaculty@gmail.com";
  static const String shareClaireUrl = "https://play.google.com/store/apps/details?id=com.mobymagic.clairediary";


  void setTabIndex(index) async {
    if (await firebaseServices.isUserSignIn(context))
      // setState(() => _currentIndex = index);
      _pageController.animateToPage(index, duration: Duration(milliseconds: 200), curve: Curves.bounceIn);
  }

  @override
  void initState() {
    clairNotification.triggerNotifications();
    clairNotification.triggerReminder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Pallet.colorPrimary,
          centerTitle: false,
          title: Text(AppString.appTitle,
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
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Pallet.colorPrimary,
                  ),
                  accountEmail: Text("Secret Diary Chat",
                      style: TextStyle(color: Pallet.colorWhite, fontWeight: FontWeight.w600,
                      fontSize: 12.0, fontStyle: FontStyle.italic
                      )),
                  accountName: Text("Dear Claire",
                      style: TextStyle(color: Pallet.colorWhite,
                          fontSize: 21.0, fontWeight: FontWeight.w700,)),
                  currentAccountPicture: InkWell(
                      onTap: () async {
                        String id = await sharedPreference.getAlterEgoId();
                        String accessCode = await sharedPreference.getAlterEgoAccessCode();
                        print("Show Alter details:: $id || $accessCode");
                        id.isNotEmpty && accessCode.isNotEmpty ? await firebaseServices.getUserAlterEgo(context,id, accessCode)
                            : Navigator.of(context)
                            .pushNamed(AppRoutes.alterEgoLogin);
                      },
                      child: RotateImage(72.h, 72.w,)),
                ),

                SizedBox(height: 28,),
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
                SizedBox(height: 18,),
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
                  onTap: () =>launchEmailApp(),
                  leading: Icon(Icons.email, color: Pallet.colorWhite),
                ),
              ],
            ),
          ),
        )
    );
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }
}
