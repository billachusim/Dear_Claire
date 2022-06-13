import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/user_activity_model.dart';
import '../../../services/user_model.dart';
import '../../../utils/color.dart';
import '../../../utils/constant.dart';
import '../../../utils/helper.dart';
import '../../featured/widget/custom_post_details_screen.dart';
import '../../routes/page_router_animation.dart';
import '../../routes/routes.dart';
import '../../splash_screen/custom_rotate_bacground.dart';
import '../../splash_screen/rotate_logo.dart';

class AllActivitiesTab extends StatefulWidget {
  const AllActivitiesTab({ Key? key }) : super(key: key);

  @override
  _AllActivitiesTabState createState() => _AllActivitiesTabState();
}

class _AllActivitiesTabState extends State<AllActivitiesTab> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(

        onWillPop: (){
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.alterEgoHomepage);
          return Future.value(false);
        },
        child: Scaffold(
          body: Stack(
              children:[
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

                FutureBuilder(
                    future: firebaseServices.getAllUsersActivities(),
                    builder: (context, AsyncSnapshot<List<UserActivityModel>> userActivity) {
                      if (userActivity.connectionState == ConnectionState.waiting) {
                        return RotateImage(50, 50);
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
                                .map((element) => AllActivitiesCard(element: element,)
                            )
                                .toList(),
                          ],
                        );
                      }
                      return Container();
                    }
                ),

                Container(

                ),
              ]
          ),
        ),
      ),
    );
  }
}



class AllActivitiesCard extends StatelessWidget {
  UserActivityModel element;
  UserModel userModel = UserModel();
  User? currentUser = FirebaseAuth.instance.currentUser;


  AllActivitiesCard({Key? key, required this.element}) : super(key: key);

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