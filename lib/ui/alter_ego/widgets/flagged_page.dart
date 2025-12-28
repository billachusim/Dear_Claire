import 'package:flutter/material.dart';
import '../../../helpers/toast_helper.dart';
import '../../../utils/color.dart';
import '../../../utils/helper.dart';
import '../../ego-profile/archive.dart';
import '../../routes/routes.dart';
import '../../splash_screen/custom_rotate_bacground.dart';
import '../flagged_sessions_page.dart';
import 'flagged_advises_tab.dart';

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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.alterEgoHomepage);
        },
        child: Scaffold(
          body: Stack(
              fit: StackFit.expand,
              children: [
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

                /// The three Flagged page tabs are here
                /// First tab is Sessions Tab

                DefaultTabController(
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
                                          : Icon(Icons.crisis_alert_rounded,
                                          color: Pallet.colorPrimary)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),



                          /// Second tab is flagged chats Tab

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
                                        "Advises",
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
                                          : Icon(Icons.message_outlined,
                                          color: Pallet.colorSecondary)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),


                          /// Third tab is the flagged chats Tab

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
                                        "Chats",
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
                                          : Icon(Icons.wechat_sharp,
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
                        FlaggedAdvisesTab(),
                        ArchiveWidget(),
                      ],
                    ),
                  )
                ]),
                )

              ]
          ),
        ),
      ),
    );
  }
}
