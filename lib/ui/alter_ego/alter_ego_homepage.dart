import 'package:dear_claire/data/repository/post_repository_impl.dart';
import 'package:dear_claire/ui/alter_ego/advised_page.dart';
import 'package:dear_claire/ui/alter_ego/all_page.dart';
import 'package:dear_claire/ui/alter_ego/new_diaries_page.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../utils/helper.dart';
import '../splash_screen/custom_rotate_bacground.dart';
import 'chatrooms.dart';

class AlterEgoHomePage extends StatefulWidget {
  const AlterEgoHomePage({Key? key}) : super(key: key);

  @override
  _AlterEgoHomePageState createState() => _AlterEgoHomePageState();
}

class _AlterEgoHomePageState extends State<AlterEgoHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController? _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
  }

  dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Pallet.colorBottomNav,
              title: Text("Alter Ego Mode",
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
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
                PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                children: [
                  AdvisedPage(),
                  NewDiariesPage(),
                  AllDiariesPage(),
                  ChatRooms()
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
                onTap: (index) {
                  _pageController!.jumpToPage(index);
                  setState(() {
                    currentIndex = index;
                  });
                },
                // A6A6B1
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border,
                        color: currentIndex == 0
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Advising',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined,
                        color: currentIndex == 1
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'New Sessions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.access_time_rounded,
                        color: currentIndex == 2
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'All Sessions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.messenger,
                        color: currentIndex == 3
                            ? Pallet.colorWhite
                            : Pallet.colorSecondary),
                    label: 'Rooms',
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
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
                      decoration: BoxDecoration(color: Pallet.colorSecondary,

                      ),
                      accountEmail: Text("Secret Diary Chat",
                          style: TextStyle(color: Pallet.colorWhite, fontWeight: FontWeight.w600,
                              fontSize: 12.0, fontStyle: FontStyle.italic
                          )),
                      accountName: Text("Dear Claire",
                          style: TextStyle(color: Pallet.colorWhite,
                            fontSize: 22.0, fontWeight: FontWeight.w700,)),
                      currentAccountPicture: InkWell(
                          onTap: () async {
                            Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.home);
                          },
                          child: RotateImage(75.h, 75.w)),
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
                      onTap: () {},
                      leading: Icon(Icons.share, color: Pallet.colorWhite),
                    ),
                    ListTile(
                      title: Text("Contact Us",
                          style: TextStyle(color: Pallet.colorWhite)),
                      onTap: () {},
                      leading: Icon(Icons.email, color: Pallet.colorWhite),
                    )
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
}
