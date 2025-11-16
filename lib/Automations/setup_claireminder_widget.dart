import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/menu_items/view_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import '../services/firebase_services.dart';
import '../widgets/toast.dart';


class SetupClaireminder extends StatefulWidget {
  const SetupClaireminder({Key? key}) : super(key: key);

  @override
  _SetupClaireminderState createState() => _SetupClaireminderState();
}

class _SetupClaireminderState extends State<SetupClaireminder> {
  late int theClaireminderDelay;
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

  TextEditingController claireminderTitleController = TextEditingController();
  TextEditingController claireminderMessageController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;




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
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: claireminderTitleController,
                          decoration: InputDecoration(
                            //border: InputBorder,
                            hintText: "Reminder",
                            labelText: "Title"
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: claireminderMessageController,
                          decoration: InputDecoration(
                            //border: InputBorder,
                            hintText: "Remind me to start a new diary session.",
                            labelText: "Message (Optional)"
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: getDeviceWidth(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          OutlinedButton(
                            onPressed: () async {
                              final _claireminderDelay = 18;
                              theClaireminderDelay = _claireminderDelay;
                              await addClaireminderData();
                              _showCardDialog();
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Pallet.colorBlue,
                              padding: EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text("DAY",
                                style: GoogleFonts.lato(
                                    fontSize: 18.0, fontWeight: FontWeight.w700, color: Colors.green)),
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

                        ],
                      ),
                    ),

                    SizedBox(height: 12,),

                    Container(
                      width: getDeviceWidth(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [

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
                      ),
                    ),

                    SizedBox(height: 8,),

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


  /// Add claireminder info to user's firestore.

  Future<void> addClaireminderData() async {
    final int claireminderDelay = theClaireminderDelay;
    final String claireminderTitle = claireminderTitleController.text;
    final String claireminderMessage = claireminderMessageController.text;
    FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set(
      {
        'claireminderDelay': claireminderDelay,
        'claireminderTitle': claireminderTitle,
        'claireminderMessage': claireminderMessage,
      },
      SetOptions(merge: true),

    );
    logger.d('Successfully added claireminder data.');
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
              child: Text(claireminderTitleController.text,
                  textAlign: TextAlign.center),
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
                child: Text("ACTIVATE", style: TextStyle(color: Pallet.colorSecondary, fontSize: 18)),
                onPressed: () async {
                  final _user = await firebaseServices.getUserInfo();
                  final int claireminderFrequency = _user.claireminderDelay!;
                  final String uniqueName = DateTime.now().second.toString();
                  final String taskName = "claireminder";
                  if (_user.currentLoveCount > 200) {
                    await Workmanager().registerPeriodicTask(uniqueName, taskName,
                        tag: taskName,
                        frequency: Duration(seconds: claireminderFrequency),
                        initialDelay: Duration(seconds: 15),
                        constraints: Constraints(networkType: NetworkType.connected)
                    );
                    Navigator.of(context).pop();
                    showToast("Claireminder Scheduled...once a week");
                  }
                  else showToast("You need up to 2000 Loves.");
                },
              ),
            ],
          ),
        );
      },
    );
  }



}
