import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/Categories/category_streams.dart';
import 'package:dear_claire/ui/Categories/category_streams2.dart';
import 'package:dear_claire/ui/alter_ego/alter_ego_homepage.dart';
import 'package:dear_claire/ui/alter_ego/new_diary_details.dart';
import 'package:dear_claire/ui/featured/ego_stream.dart';
import 'package:dear_claire/ui/featured/model/featured_session_model.dart';
import 'package:dear_claire/ui/featured/public_sessions.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/splash_screen/custom_rotate_bacground.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shake/shake.dart';

import '../../utils/helper.dart';
import 'model/session.dart';
import '../../widgets/ego_mode_session_card.dart';

class FeaturedPage extends StatefulWidget {
  FeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {
  List<Session>? _sessionList = [];

  @override
  void initState() {
    super.initState();
    ShakeDetector detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        PageRouter.gotoWidget(AlterEgoHomePage(), context);
      },
    );

    // To close: detector.stopListening();
    // ShakeDetector.waitForStart() waits for user to call detector.startListening();
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
                CategoryStreams(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
