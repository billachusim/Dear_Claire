import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
import 'package:dear_claire/ui/dairy/dairy.dart';
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

  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _body = [
    FeaturedPage(title: 'Dear Claire'),
    FollowedPage(title: 'Dear Claire'),
    DairyPage(title: 'Dear Claire'),
    ChatRoomsPage(),
    EgoProfilePage(),
  ];

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  void setTabIndex(index) async {
    if (await firebaseServices.isUserSignIn(context)) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.bounceIn);
    }
  }

  @override
  void initState() {
    clairNotification.triggerNotifications();
    clairNotification.triggerReminder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                child: const Icon(
                  Icons.search,
                  color: Pallet.colorWhite,
                ),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AppRoutes.searchPage);
                })
          ],
          leading: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Pallet.colorWhite,
              ),
              onPressed: () {
                _openEndDrawer();
              }),
        ),
        body: Stack(
          children: [
            RotateImage(screenHeight, screenWidth),
            PageView(
            controller: _pageController,
            onPageChanged: (index){
              setState(() {
                _currentIndex  = index;
              });
            },
            children: _body,
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
            width: screenWidth * 0.7,
            color: Pallet.colorSecondaryDark,
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Pallet.colorPrimary,
                  ),
                  accountEmail: const Text("Secret Diary Chat",
                      style: TextStyle(color: Pallet.colorWhite, fontWeight: FontWeight.w600,
                      fontSize: 12.0, fontStyle: FontStyle.italic
                      )),
                  accountName: const Text("Dear Claire",
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
                      child: RotateImage(72, 72)),
                ),
                const SizedBox(height: 15,),
                ListTile(
                  title: const Text("Settings",
                      style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () {

                  },
                  leading: const Icon(Icons.settings, color: Pallet.colorWhite),
                ),
                const SizedBox(height: 18,),
                ListTile(
                  title: const Text("How Claire Works",
                      style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () {
                    Navigator. pop(context);
                    Navigator.of(context).pushNamed(AppRoutes.howClaireWorks);
                  },
                  leading: const Icon(Icons.info_rounded,
                      color: Pallet.colorWhite),
                ),
                const SizedBox(height: 18,),
                ListTile(
                  title: const Text("Send Claire to Someone",
                      style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () => _launchUrl(StringConstants.shareClaireUrl),
                  leading: const Icon(Icons.share, color: Pallet.colorWhite),
                ),
                const SizedBox(height: 18,),
                ListTile(
                  title: const Text("Contact us via Instagram",
                      style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () => _launchUrl("https://instgram.com/socialfaculty"),
                  leading: const Icon(Icons.email, color: Pallet.colorWhite),
                ),
                ListTile(
                  title: const Text("Contact us via Whatsapp",
                      style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () => _launchUrl("https://wa.me/${StringConstants.phoneNumber}"),
                  leading: const Icon(Icons.email, color: Pallet.colorWhite),
                ),
                ListTile(
                  title: const Text("Contact us via Email",
                      style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () => _launchUrl("mailto:${StringConstants.claireEmailAddress}?subject=Inquiry&body=Hello%Claire"),
                  leading: const Icon(Icons.email, color: Pallet.colorWhite),
                )
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
