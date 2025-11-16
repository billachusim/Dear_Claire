import 'package:clairediary/ui/menu_items/view_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import '../widgets/toast.dart';


class SetupClairendar extends StatefulWidget {
  const SetupClairendar({Key? key}) : super(key: key);

  @override
  _SetupClairendarState createState() => _SetupClairendarState();
}

class _SetupClairendarState extends State<SetupClairendar> {
  static List<String> imageSliderList = [
    "assets/images/alter_ego_slide_1.png",
    "assets/images/alter_ego_slide_2.png",
  ];

  static List<String> imageSliderDescriptionList = [
    AppString.about_alter_ego_slide1,
    AppString.about_alter_ego_slide2,
  ];

  List<Widget> widgetsList = [
    singleImageWidget(index: 0),
    singleImageWidget(index: 1),
  ];

  TextEditingController sessionTitleController = TextEditingController();
  bool acceptReplies = false;
  bool followClaire = true;




  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Pallet.colorSecondary,
          centerTitle: false,
          automaticallyImplyLeading: true,
          title: Text('Claireminder',
              textAlign: TextAlign.start,
              maxLines: 1,
              style: GoogleFonts.lato(
                  fontSize: 24.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w600)),
        ),
        body: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Consumer<HowClaireWorksProvider>(
                        builder: (context, provider, child) => SwipeDetector(
                          child: Container(
                              height: 280,
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 3000),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                        scale: animation,
                                        child:
                                        SizedBox.expand(child: child)),
                                child:
                                widgetsList[provider.imageSliderIndex],
                              )),
                          onSwipeLeft: (offset) {
                            provider
                                .increaseIndex(provider.imageSliderIndex);
                          },
                          onSwipeRight: (offset) {
                            provider
                                .decreaseIndex(provider.imageSliderIndex);
                          },
                        )),
                    // imageSliderWidget(),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(AppString.autoDiaryHeader,
                          style: GoogleFonts.lato(
                              fontSize: 15.0, fontWeight: FontWeight.w700, color: Pallet.colorSecondary)),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(AppString.creators_quote,
                          style: GoogleFonts.lato(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Pallet.deepGreen
                          )),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(AppString.creators_quote_paragraph,
                          style: GoogleFonts.lato(
                            fontSize: 15.0,
                          )),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        OutlinedButton(
                          onPressed: () async {
                            final _user = await firebaseServices.getUserInfo();
                            final String uniqueName = DateTime.now().second.toString();
                            final String taskName = "claireminder";
                            if (_user.currentLoveCount > 200) {
                              await Workmanager().registerOneOffTask(uniqueName, taskName,
                                  tag: taskName,
                                  initialDelay: Duration(seconds: _user.claireminderDelay!),
                                  constraints: Constraints(networkType: NetworkType.connected)
                              );
                              Navigator.of(context).pop();
                              showToast("Claireminder Scheduled...once a day");
                            }
                            else showToast("You need up to 2000 Loves.");
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Pallet.colorSecondary,
                            padding: EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text("ONCE A DAY",
                              style: GoogleFonts.lato(
                                  fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),


                        OutlinedButton(
                          onPressed: () async {
                            final _user = await firebaseServices.getUserInfo();
                            final String uniqueName = DateTime.now().second.toString();
                            final String taskName = "claireminder";
                            if (_user.currentLoveCount > 200) {
                              await Workmanager().registerPeriodicTask(uniqueName, taskName,
                                  tag: taskName,
                                  frequency: Duration(days: _user.claireminderDelay!),
                                  initialDelay: Duration(seconds: 15),
                                  constraints: Constraints(networkType: NetworkType.connected)
                              );
                              Navigator.of(context).pop();
                              showToast("Claireminder Scheduled... thrice a week");
                            }
                            else showToast("You need up to 2000 Loves.");
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Pallet.colorSecondary,
                            padding: EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text("THRICE A WEEK",
                              style: GoogleFonts.lato(
                                  fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),


                        OutlinedButton(
                          onPressed: () async {
                            final _user = await firebaseServices.getUserInfo();
                            final String uniqueName = DateTime.now().second.toString();
                            final String taskName = "claireminder";
                            if (_user.currentLoveCount > 200) {
                              await Workmanager().registerPeriodicTask(uniqueName, taskName,
                                  tag: taskName,
                                  frequency: Duration(days: _user.claireminderDelay!),
                                  initialDelay: Duration(seconds: 15),
                                  constraints: Constraints(networkType: NetworkType.connected)
                              );
                              Navigator.of(context).pop();
                              showToast("Claireminder Scheduled...once a week");
                            }
                            else showToast("You need up to 2000 Loves.");
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Pallet.colorSecondary,
                            padding: EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text("ONCE A WEEK",
                              style: GoogleFonts.lato(
                                  fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),

                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final _user = await firebaseServices.getUserInfo();
                            //final String taskName = "autoDiary";
                            if (_user.currentLoveCount > 200) {
                              await Workmanager().cancelAll();
                            }
                            else showToast("You need up to 2000 Loves.");
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Pallet.colorSecondary,
                            padding: EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text("STOP ALL",
                              style: GoogleFonts.lato(
                                  fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),

                        InkWell(
                            onTap: onDonateClicked,
                            child: Container(
                                padding: EdgeInsets.all(12),
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: Pallet.colorPrimary,
                                ),
                                child: Center(
                                    child: Text(AppString.donate,
                                        style: GoogleFonts.lato(
                                            fontSize: 17.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700)
                                    )
                                )
                            )
                        ),
                      ],
                    ),
                  ],
                )
            )
        )
    );
  }

  static singleImageWidget({int? index}) {
    return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Pallet.colorSecondary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(children: [
          Image.asset(imageSliderList[index!]),
          SizedBox(
            height: 6,
          ),
          Text(imageSliderDescriptionList[index],style: TextStyle(color: Pallet.colorWhite),),
          SizedBox(height: 6),
          AnimatedSmoothIndicator(
            activeIndex: index,
            count: 2,
            effect: SlideEffect(
                spacing: 8.0,
                radius: 25,
                dotWidth: 10,
                dotHeight: 10,
                paintStyle: PaintingStyle.fill,
                strokeWidth: 1.5,
                dotColor: Pallet.colorPrimary,
                activeDotColor: Pallet.colorWhite),
          )
        ]));
  }

  String getDonateUrl(){
    return AppString.donate_url;
  }

  onDonateClicked() {
    Uri donateUrl = Uri.parse(getDonateUrl());
    launchUrl(donateUrl);
  }



  /// Shows up when user selects a claireminder option.
  Future<void> _showCardDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            title: Container(
              child: Text(AppString.save_or_share_title,
                  textAlign: TextAlign.center),
            ),
            content: SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: sessionTitleController,
                        decoration: InputDecoration(
                          //border: InputBorder,
                          hintText: AppString.whats_this_session_about,
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Container(
                          child: Row(
                            children: [
                              Icon(Icons.lock),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(AppString.do_you_want_other_users,
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              Obx(() => Switch(
                                value: acceptReplies,
                                onChanged: (value) {
                                  acceptReplies = value;
                                },
                                // activeTrackColor: Colors.lightGreenAccent,
                                // activeColor: Colors.green,
                              ))
                            ],
                          )),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                          child: Row(
                            children: [
                              Icon(Icons.lock),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                    "Do you want Claire to reply and follow this diary session?",
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              Obx(() => Switch(
                                value: followClaire,
                                onChanged: (value) {
                                  followClaire = value;
                                },
                                activeTrackColor: Colors.purpleAccent,
                                activeColor: Pallet.colorSecondary,
                              ))
                            ],
                          )),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Obx(
                      () => acceptReplies
                      ? Text("Share and Save",
                      style: TextStyle(color: Pallet.colorSecondary, fontSize: 18))
                      : Text('Save',
                      style: TextStyle(color: Pallet.colorSecondary, fontSize: 18)),
                ),
                onPressed: () {
                  if (sessionTitleController.text.isNotEmpty) {
                    Navigator.of(context).pop();
                    //createSession();
                    showToast(AppString.started_new_session);
                  } else {
                    //_interstitialAd?.dispose();
                    showToast(AppString.new_session_error);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }



}
