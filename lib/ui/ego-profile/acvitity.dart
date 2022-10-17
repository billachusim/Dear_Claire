import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/services/user_activity_model.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/strings.dart';
import '../featured/notified_session_details.dart';

class ActivityWidget extends StatelessWidget {
ActivityWidget({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebaseServices.getActivityForUser(),
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
            NotifiedSessionDetails(sessionId: element.sessionId),
              context),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  AppImages.appChatBg,
                ),
                fit: BoxFit.fill,
              ),
                borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
              ClipOval(
                child: CachedNetworkImage(
                  width: 30,
                  height: 30,
                  imageUrl: element.userAvatarUrl.toString(),
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
                    "assets/images/Speak_No_Evil_Monkey_Emoji.png",
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
                    Text(element.activityMessage.toString(),
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Pallet.colorSecondaryDark)),
                    Text(timeConverter(element.dateCreated!),
                        style: TextStyle(fontSize: 11.sp, color: Pallet.colorTextGray)),
                  ],
                ),
              )
            ],),
          ),
        ),
      ),
    );
  }

}