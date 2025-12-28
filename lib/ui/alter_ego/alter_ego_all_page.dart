import 'package:clairediary/ui/alter_ego/all_page.dart';
import 'package:clairediary/ui/alter_ego/widgets/all_activities_tab.dart';
import 'package:clairediary/ui/alter_ego/widgets/all_mantra_tab.dart';
import 'package:flutter/material.dart';
import '../../../utils/color.dart';
import '../../../utils/helper.dart';
import '../../widgets/toast.dart';
import '../routes/routes.dart';
import '../splash_screen/custom_rotate_bacground.dart';

class TheAllPage extends StatefulWidget {
  const TheAllPage({Key? key}) : super(key: key);

  @override
  _TheAllPageState createState() => _TheAllPageState();
}



class _TheAllPageState extends State<TheAllPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  late TabController _tabController;
  int currentTabIndex = 0;


  bool get wantKeepAlive => true;

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
    super.build(context);
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.alterEgoHomepage);
          showToast("Press back again to exit alter ego home.");
        },
        child: Scaffold(
          body: Stack(
              fit: StackFit.expand,
              children: [
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

                /// The three All page tabs are here
                /// First tab is Sessions Tab

                Column(children: [
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



                        /// Second tab is the all mantras chats Tab

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
                                      "Mantras",
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


                        /// Third tab is the all activities Tab

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
                                      "Activities",
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
                                        : Icon(Icons.local_activity_rounded,
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
                    physics: AlwaysScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      AllDiariesPage(),
                      AllMantraTab(),
                      AllActivitiesTab(),
                    ],
                  ),
                )
                                ])

              ]
          ),
        ),
      ),
    );
  }
}
