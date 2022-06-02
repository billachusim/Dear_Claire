import 'package:dear_claire/ui/featured/public_sessions.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shake/shake.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

import '../../utils/constant.dart';

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
    ShakeDevice();
  }

  ShakeDevice() async {
    ShakeDetector detector = ShakeDetector.autoStart(
      onPhoneShake: () async {

      var _type = FeedbackType.error;
      Vibrate.feedback(_type);
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: "Switching Ego",
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );
        String id = await sharedPreference.getAlterEgoId();
                    String accessCode = await sharedPreference.getAlterEgoAccessCode();
                    print("Show Alter details:: $id || $accessCode");
                    id.isNotEmpty && accessCode.isNotEmpty ? await firebaseServices.getUserAlterEgo(context,id, accessCode)
                        : Navigator.of(context)
                        .pushNamed(AppRoutes.alterEgoLogin);
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
