import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/helper.dart';
import '../../utils/strings.dart';

class EmptyFollowedSessionWidget extends StatelessWidget {
  const EmptyFollowedSessionWidget({
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
              "assets/images/alter_ego_slide_2.png",
              height: 150.h,
              width: 150.w,
            ),

            SizedBox(height: 10.h,),
            Text("So, you are currently not following any diary session.", textAlign: TextAlign.left,),
            SizedBox(height: 10.h,),
            Text("Browse the Featured Sessions Tab and follow diary sessions of your choice to give real support to strangers and earn Love Points that you can cash out monthly.", textAlign: TextAlign.left,),
            SizedBox(height: 10.h,),

          ],
        ),
      ),
    );
  }
}
