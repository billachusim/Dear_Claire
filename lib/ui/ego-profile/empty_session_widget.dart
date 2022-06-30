import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/helper.dart';
import '../../utils/strings.dart';

class EmptySessionWidget extends StatelessWidget {
  const EmptySessionWidget({
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
            Row(
              children: [

                Container(
                    height: 100.h,
                    width: 100.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 80,
                        color: Pallet.colorSecondary,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
                      },
                    )),

                Container(
                    height: 100.h,
                    width: 100.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.mic_rounded,
                        size: 80,
                        color: Pallet.colorPrimaryDark,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
                      },
                    )),

                Container(
                    height: 100.h,
                    width: 100.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        size: 80,
                        color: Pallet.deepGreen,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
                      },
                    )),
              ],
            ),

            SizedBox(height: 10.h,),
            Text("Eeyaa. Your diary is empty. Tap any button to start a new diary session.\n"
                "You can make the session public or keep it between you and Claire; either way, you remain completely anonymous.", textAlign: TextAlign.left,),
            SizedBox(height: 10.h,),
            Text("If you have some diary sessions already, they should appear here pending your internet network.\n\n"
                "Use the spinning icon anywhere you are in the app to quickly start a new diary session.", textAlign: TextAlign.left,),
            SizedBox(height: 10.h,),

          ],
        ),
      ),
    );
  }
}
