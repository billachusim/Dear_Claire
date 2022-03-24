import 'package:dear_claire/ui/alter_ego/alter_ego_login.dart';
import 'package:dear_claire/ui/menu_items/how_claire_works.dart';
import 'package:dear_claire/ui/menu_items/view_model.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';
import 'package:swipedetector/swipedetector.dart';
import 'package:provider/provider.dart';

class HowAlterEgoWorks extends StatefulWidget {
  const HowAlterEgoWorks({Key? key}) : super(key: key);

  @override
  _HowAlterEgoWorksState createState() => _HowAlterEgoWorksState();
}

class _HowAlterEgoWorksState extends State<HowAlterEgoWorks> {
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Pallet.colorSecondary,
          centerTitle: false,
          automaticallyImplyLeading: true,
          title: Text('About Alter Ego Mode',
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
                              onSwipeLeft: () {
                                provider
                                    .increaseIndex(provider.imageSliderIndex);
                              },
                              onSwipeRight: () {
                                provider
                                    .decreaseIndex(provider.imageSliderIndex);
                              },
                              swipeConfiguration: SwipeConfiguration(
                                  verticalSwipeMinVelocity: 100.0,
                                  verticalSwipeMinDisplacement: 50.0,
                                  verticalSwipeMaxWidthThreshold: 100.0,
                                  horizontalSwipeMaxHeightThreshold: 50.0,
                                  horizontalSwipeMinDisplacement: 50.0,
                                  horizontalSwipeMinVelocity: 200.0),
                            )),
                    // imageSliderWidget(),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(AppString.what_is_alter_ego_header,
                          style: GoogleFonts.lato(
                              fontSize: 15.0, fontWeight: FontWeight.w700, color: Pallet.colorSecondary)),
                    ),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text(AppString.what_is_alter_ego_paragraph,
                            style: GoogleFonts.lato(
                              fontSize: 15.0,
                            ))),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(AppString.what_is_alter_ego_mode_header,
                          style: GoogleFonts.lato(
                              fontSize: 15.0, fontWeight: FontWeight.w700, color: Pallet.colorSecondary)),
                    ),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text(AppString.what_is_alter_ego_mode_paragraph,
                            style: GoogleFonts.lato(
                              fontSize: 15.0,
                            ))),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(AppString.how_does_it_work,
                          style: GoogleFonts.lato(
                              fontSize: 15.0, fontWeight: FontWeight.w700, color: Pallet.colorSecondary)),
                    ),
                    Align(
                        alignment: Alignment.topLeft,
                        child: Text(AppString.how_does_it_work_paragraph,
                            style: GoogleFonts.lato(
                              fontSize: 15.0,
                            ))),
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
                      onTap: () {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.donate,);
                      },
                        child: Container(
                            padding: EdgeInsets.all(20),
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
                      onPressed: (){
                        Navigator.pushNamed(context, AppRoutes.alterEgoRegistration);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Pallet.colorSecondary,
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(AppString.request_access,
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

  Widget imageSliderWidget() {
    return Consumer<HowClaireWorksProvider>(
        builder: (context, provider, child) => SwipeDetector(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 1500),
                transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation, child: SizedBox.expand(child: child)),
                child: singleImageWidget(index: provider.imageSliderIndex),
              ),
              onSwipeLeft: () {
                provider.decreaseIndex(provider.imageSliderIndex);
              },
              onSwipeRight: () {
                provider.increaseIndex(provider.imageSliderIndex);
              },
              swipeConfiguration: SwipeConfiguration(
                  verticalSwipeMinVelocity: 100.0,
                  verticalSwipeMinDisplacement: 50.0,
                  verticalSwipeMaxWidthThreshold: 100.0,
                  horizontalSwipeMaxHeightThreshold: 50.0,
                  horizontalSwipeMinDisplacement: 50.0,
                  horizontalSwipeMinVelocity: 200.0),
            ));
  }
}
