import 'package:dear_claire/ui/alter_ego/alter_ego_homepage.dart';
import 'package:dear_claire/ui/featured/public_sessions.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';

class FeaturedPage extends StatefulWidget {
  FeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {

  @override
  void initState() {
    super.initState();
    ShakeDetector detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        PageRouter.gotoWidget(AlterEgoHomePage(), context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Pallet.colorSecondaryDark,
        body: Stack(
          children: [
            //CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

            Column(
            children: [

              FeaturedStatusStreams(),

              TheFeaturedSessions(),

              TrendingCategories(),

      ],
          ),
      ],
        ),
      ),
    );
  }
}
