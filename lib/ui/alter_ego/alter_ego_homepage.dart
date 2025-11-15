import 'package:dear_claire/ui/alter_ego/advised_page.dart';
import 'package:dear_claire/ui/alter_ego/all_page.dart';
import 'package:dear_claire/ui/alter_ego/new_diaries_page.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:dear_claire/utils/helper.dart';
import '../splash_screen/custom_rotate_bacground.dart';
import 'chatrooms.dart';

class AlterEgoHomePage extends StatefulWidget {
  const AlterEgoHomePage({super.key});

  @override
  _AlterEgoHomePageState createState() => _AlterEgoHomePageState();
}

class _AlterEgoHomePageState extends State<AlterEgoHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController? _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
  }

  @override
  void dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = getDeviceHeight(context);
    final deviceWidth = getDeviceWidth(context);

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Pallet.colorBottomNav,
          title: const Text(
            "Alter Ego Mode",
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Pallet.colorSecondary,
            ),
            onPressed: _openEndDrawer,
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: Pallet.colorBottomNav,
              ),
              child: const Icon(Icons.search, color: Pallet.colorSecondary),
            ),
          ],
        ),
        body: Stack(
          children: [
            CustomRotateImage(deviceHeight, deviceWidth),
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: const [
                AdvisedPage(),
                NewDiariesPage(),
                AllDiariesPage(),
                ChatRooms(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          backgroundColor: Pallet.colorBottomNav,
          selectedLabelStyle: const TextStyle(color: Pallet.colorWhite),
          unselectedLabelStyle: const TextStyle(color: Pallet.colorWhite),
          currentIndex: _currentIndex,
          selectedItemColor: Pallet.colorWhite,
          showUnselectedLabels: false,
          onTap: (index) {
            _pageController!.jumpToPage(index);
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.favorite_border,
                color: _currentIndex == 0 ? Pallet.colorWhite : Pallet.colorSecondary,
              ),
              label: 'Advising',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_today_outlined,
                color: _currentIndex == 1 ? Pallet.colorWhite : Pallet.colorSecondary,
              ),
              label: 'New Sessions',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.access_time_rounded,
                color: _currentIndex == 2 ? Pallet.colorWhite : Pallet.colorSecondary,
              ),
              label: 'All Sessions',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.messenger,
                color: _currentIndex == 3 ? Pallet.colorWhite : Pallet.colorSecondary,
              ),
              label: 'Rooms',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Pallet.colorSecondary,
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
          },
          tooltip: 'Claire',
          child: const RotateImage(45, 45),
        ),
        drawer: Drawer(
          child: Container(
            color: Pallet.colorSecondaryDark,
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Pallet.colorSecondary),
                  accountEmail: const Text(
                    "Secret Diary Chat",
                    style: TextStyle(
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  accountName: const Text(
                    "Dear Claire",
                    style: TextStyle(
                      color: Pallet.colorWhite,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  currentAccountPicture: InkWell(
                    onTap: () async {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                    },
                    child: const RotateImage(75, 75),
                  ),
                ),
                ListTile(
                  title: const Text("Settings", style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () {},
                  leading: const Icon(Icons.settings, color: Pallet.colorWhite),
                ),
                ListTile(
                  title: const Text("How Claire Works", style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(AppRoutes.howClaireWorks);
                  },
                  leading: const Icon(Icons.info_rounded, color: Pallet.colorWhite),
                ),
                ListTile(
                  title: const Text("Send Claire to Someone", style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () {},
                  leading: const Icon(Icons.share, color: Pallet.colorWhite),
                ),
                ListTile(
                  title: const Text("Contact Us", style: TextStyle(color: Pallet.colorWhite)),
                  onTap: () {},
                  leading: const Icon(Icons.email, color: Pallet.colorWhite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
