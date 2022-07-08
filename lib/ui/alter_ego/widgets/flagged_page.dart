import 'package:dear_claire/ui/alter_ego/widgets/all_activities_tab.dart';
import 'package:flutter/material.dart';
import '../../../utils/color.dart';
import '../../../utils/helper.dart';
import '../../ego-profile/archive.dart';
import '../../routes/routes.dart';
import '../../splash_screen/custom_rotate_bacground.dart';
import '../flagged_sessions_page.dart';

class FlaggedPage extends StatefulWidget {
  const FlaggedPage({Key? key}) : super(key: key);

  @override
  _FlaggedPageState createState() => _FlaggedPageState();
}



class _FlaggedPageState extends State<FlaggedPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  int currentTabIndex = 0;




  @override
  void initState() {
    super.initState();
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


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(

        onWillPop: (){
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.alterEgoHomepage);
          return Future.value(false);
        },
        child: Scaffold(
          body: Stack(
              children: [
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),


                /// The three Ego page tabs are here
                /// First tab is Activity Tab

                Expanded(
                    child: DefaultTabController(
                      length: 3, child: Column(children: [
                      SizedBox(height: 7),
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
                                            : Pallet.colorWhite),
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



                              /// Second tab is Claire Love Tab

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
                                            "Loves",
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
                                          SizedBox(width: 14),
                                          currentTabIndex != 1
                                              ? SizedBox.shrink()
                                              : Icon(Icons.monetization_on_rounded,
                                              color: Pallet.colorSecondary)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),


                              /// Third tab is Archive Tab

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
                                            "Archive",
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
                                          SizedBox(width: 14),
                                          currentTabIndex != 2
                                              ? SizedBox.shrink()
                                              : Icon(Icons.archive_rounded,
                                              color: Pallet.deepGreen)
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
                          physics: NeverScrollableScrollPhysics(),
                          controller: _tabController,
                          children: [
                            FlaggedDiariesPage(),
                            AllActivitiesTab(),
                            ArchiveWidget(),
                          ],
                        ),
                      )
                    ]),
                    ))

              ]
          ),
        ),
      ),
    );
  }
}
