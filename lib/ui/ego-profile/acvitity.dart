import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/services/user_activity_model.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/featured/ego_mode_session_detail.dart';
import 'package:dear_claire/ui/featured/widget/post_details_widget.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../featured/widget/custom_post_details_screen.dart';

class ActivityWidget extends StatelessWidget {
ActivityWidget({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebaseServices.getActivityByUser(),
      builder: (context, AsyncSnapshot<List<UserActivityModel>> userActivity) {
        if (userActivity.connectionState == ConnectionState.waiting) {
          return RotateImage(70, 70);
        }
        if (!userActivity.hasData) {
          return Center(
            child: Text("There are no activities yet",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorBlack,
                    //fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600)),
          );
        }

        if (userActivity.hasError) {
          return Container(
            child: Text(userActivity.error.toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorBlack,
                    //fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600)),
          );
        }

        if (userActivity.hasData) {
          return ListView(
            children: [
              ...userActivity.data!
                  .map((element) => UserActivityCard(element: element,)
              )
                  .toList(),
            ],
          );
        }
        return Container();
      }
    );
  }
}

class UserActivityCard extends StatelessWidget {
  UserActivityModel element;
  UserModel userModel = UserModel();
  User? currentUser = FirebaseAuth.instance.currentUser;


  UserActivityCard({Key? key, required this.element}) : super(key: key);

  getUser() async{
    userModel = await firebaseServices.getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    getUser();
    return Container(
      margin: EdgeInsets.all(5),
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(35)),
        elevation: 20,
        child: GestureDetector(
          onTap: () => PageRouter.gotoWidget(
            CustomPostDetailsWidget(sessionId: element.sessionId),
              context),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
              ClipOval(
                child: CachedNetworkImage(
                  width: 30,
                  height: 30,
                  imageUrl: element.clientAvatarUrl ?? "",
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  placeholder: (context, url) =>
                      CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Image.asset(
                    "assets/images/brown_boy_mask.png",
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              SizedBox(width: 4.w,),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    element.userId == currentUser?.uid && element.clientId == currentUser?.uid ?
                    Text("You ${element.activityType}ed a session",
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Pallet.colorSecondaryDark))
                    : element.userId == userModel.userId && element.clientId == userModel.userId ?
                    Text("Someone ${element.activityType}ed your session",
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Pallet.colorSecondaryDark))
                    : Text("${element.clientNickname} ${element.activityType}ed on this session",
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Pallet.colorSecondaryDark)),
                    Text(timeConverter(element.dateCreated!),
                        style: TextStyle(fontSize: 11.sp, color: Pallet.colorTextGray)),
                  ],),
              )
            ],),
          ),
        ),
      ),
    );
  }

}