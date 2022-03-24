import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptySessionWidget extends StatelessWidget {
  const EmptySessionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/diary_icon.png",
              height: 70.h,
              width: 70.w,
            ),

            SizedBox(height: 10.h,),
            Text("Your diary is empty. Use the button below to create a new Session", textAlign: TextAlign.center,),
            SizedBox(height: 10.h,),
            Text("If you had diary sessions in the previous version, please don't panic, your old diary sessions with Claire are gradually being restored", textAlign: TextAlign.center,),
            SizedBox(height: 10.h,),

            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Pallet.colorPrimary, // background
                  onPrimary: Colors.yellow, // foreground
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
                },
                child: Text("START SESSION", style: TextStyle(color: Pallet.colorWhite),)
            )
          ],
        ),
      ),
    );
  }
}
