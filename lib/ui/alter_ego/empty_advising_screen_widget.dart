import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/helper.dart';
import '../../utils/strings.dart';

class EmptyAdvisingSessionWidget extends StatelessWidget {
  const EmptyAdvisingSessionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      height: getDeviceHeight(context),
      width: getDeviceWidth(context),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            AppImages.appChatBg,
          ),
          fit: BoxFit.fill,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/alter_ego_slide_1.png",
              height: 150.h,
              width: 150.w,
            ),

            SizedBox(height: 10.h,),
            Text("So, you are currently not advising any darling.", textAlign: TextAlign.left,),
            SizedBox(height: 10.h,),
            Text("Check the All Tab and respond to diary sessions now.\n"
                "Remember your Alter Ego Pledge.", textAlign: TextAlign.left,),
            SizedBox(height: 10.h,),

          ],
        ),
      ),
    );
  }
}
