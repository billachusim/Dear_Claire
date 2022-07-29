import 'dart:math';

import 'package:dear_claire/ui/featured/featured_categories.dart';
import 'package:dear_claire/ui/featured/featured_moods.dart';
import 'package:dear_claire/ui/featured/featured_session_screen.dart';
import 'package:flutter/material.dart';
import '../../../utils/color.dart';

class AllFeaturedPage extends StatefulWidget {
  const AllFeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _AllFeaturedPage createState() => _AllFeaturedPage();
}

class _AllFeaturedPage extends State<AllFeaturedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int currentTabIndex = 0;

  @override
  void initState() {
    randomiseTabs();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<int> randomiseTabs() async {
    Random random = new Random();
    int randomNumber = random.nextInt(3);
    currentTabIndex = randomNumber;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print(_tabController.index);
    });
    if (randomNumber == 1) {
      _tabController.animateTo(1);
      currentTabIndex = 1;
    }
    if (randomNumber == 2) {
      _tabController.animateTo(2);
      currentTabIndex = 2;
    }

    if (randomNumber == 0) {
      _tabController.animateTo(0);
      currentTabIndex = 0;
    }
    return randomNumber;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Pallet.colorSecondaryDark,
        body: Stack(
          fit: StackFit.expand,
            children: [

          /// The three Featured page tabs are here
          /// First tab is Sessions Tab

          DefaultTabController(
            length: 3,
            child: Column(children: [
          SizedBox(height: 7),
          Container(
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
                            : Pallet.colorWhite),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Sessions",
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
                          SizedBox(width: 10),
                          currentTabIndex != 0
                              ? SizedBox.shrink()
                              : Icon(Icons.lightbulb,
                                  color: Pallet.colorPrimary)
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Second tab is Categories Tab

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
                                color: Pallet.colorSecondary, width: 3)
                            : Border.all(
                                color: Pallet.colorSecondary, width: 6),
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
                            "Categories",
                            style: TextStyle(
                              color: currentTabIndex != 1
                                  ? Pallet.colorSecondary
                                  : Pallet.colorSecondary,
                              fontWeight: currentTabIndex != 1
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: currentTabIndex != 1 ? 14 : 14,
                            ),
                          ),
                          SizedBox(width: 10),
                          currentTabIndex != 1
                              ? SizedBox.shrink()
                              : Icon(Icons.category_rounded,
                                  color: Pallet.colorSecondary)
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Third tab is Moods Tab

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
                                color: Pallet.deepGreen, width: 3)
                            : Border.all(
                                color: Pallet.deepGreen, width: 6),
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
                            "Moods",
                            style: TextStyle(
                              color: currentTabIndex != 2
                                  ? Pallet.deepGreen
                                  : Pallet.deepGreen,
                              fontWeight: currentTabIndex != 2
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: currentTabIndex != 2 ? 14 : 14,
                            ),
                          ),
                          SizedBox(width: 10),
                          currentTabIndex != 2
                              ? SizedBox.shrink()
                              : Icon(Icons.emoji_emotions,
                                  color: Pallet.deepGreen)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(
              physics: AlwaysScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                FeaturedPage(title: 'Featured Sessions'),
                FeaturedCategories(),
                FeaturedMoods(),
              ],
            ),
          )
            ]),
          )
        ]),
      ),
    );
  }
}
