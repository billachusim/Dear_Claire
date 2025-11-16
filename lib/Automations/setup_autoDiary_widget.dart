import 'package:clairediary/ui/menu_items/view_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import '../widgets/toast.dart';


class SetupAutoDiary extends StatefulWidget {
  const SetupAutoDiary({Key? key}) : super(key: key);

  @override
  _SetupAutoDiaryState createState() => _SetupAutoDiaryState();
}

class _SetupAutoDiaryState extends State<SetupAutoDiary> {
  static List<String> imageSliderList = [
    "assets/images/alter_ego_slide_1.png",
    "assets/images/alter_ego_slide_2.png",
    "assets/images/alter_ego_slide_3.png",
    "assets/images/alter_ego_slide_4.png",
  ];

  static List<String> imageSliderDescriptionList = [
    AppString.about_alter_ego_slide1,
    AppString.about_alter_ego_slide2,
    AppString.about_alter_ego_slide3,
    AppString.about_alter_ego_slide4,
  ];

  List<Widget> widgetsList = [
    singleImageWidget(index: 0),
    singleImageWidget(index: 1),
    singleImageWidget(index: 2),
    singleImageWidget(index: 3),
  ];


  Future<void> checkMicPermissions() async {
    PermissionStatus micStatus = await Permission.microphone.status;

    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }

    if (!micStatus.isGranted) {
      // permission permanently denied
      openAppSettings();
    }
  }




  @override
  void initState() {
    super.initState();
    checkMicPermissions();
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
          title: Text('Auto Diary Mode',
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
                                        fontWeight: FontWeight.w700))))),
                    SizedBox(
                      height: 20,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final _user = await firebaseServices.getUserInfo();
                        final String uniqueName = DateTime.now().second.toString();
                        final String taskName = "autoDiary";
                        if (_user.currentLoveCount > 200) {
                          await Workmanager().registerOneOffTask(uniqueName, taskName,
                              tag: taskName,
                              initialDelay: Duration(seconds: _user.claireminderDelay!),
                              constraints: Constraints(networkType: NetworkType.connected)
                          );
                          Navigator.of(context).pop();
                          showToast("Auto Diary Started.");
                        }
                        else showToast("You need up to 2000 Loves.");
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Pallet.colorSecondary,
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text("ACTIVATE  🌺",
                          style: GoogleFonts.lato(
                              fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final _user = await firebaseServices.getUserInfo();
                        final String uniqueName = DateTime.now().second.toString();
                        final String taskName = "autoDiary";
                        if (_user.currentLoveCount > 200) {
                          await Workmanager().registerPeriodicTask(uniqueName, taskName,
                              tag: taskName,
                              frequency: Duration(days: _user.claireminderDelay!),
                              initialDelay: Duration(seconds: 15),
                              constraints: Constraints(networkType: NetworkType.connected)
                          );
                          Navigator.of(context).pop();
                          showToast("Auto Diary Scheduled...");
                        }
                        else showToast("You need up to 2000 Loves.");
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Pallet.colorSecondary,
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text("SCHEDULE...",
                          style: GoogleFonts.lato(
                              fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    SizedBox(
                      height: 20,
                    ),
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
                  ],
                ))));
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
            count: 4,
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

}
