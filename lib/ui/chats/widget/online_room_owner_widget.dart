import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/inside_chatroom.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:dear_claire/utils/helper.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/firebase_services.dart';
import '../../../utils/constant.dart';
import '../../../utils/strings.dart';
import '../../visited_user_ego_page/visited_user_model.dart';
import '../data/chats.dart';


class OnlineRoomOwnerWidget extends StatefulWidget {
  ChatRoomPodo roomData;
  ChatModel? chatModel;



  OnlineRoomOwnerWidget({Key? key, required this.roomData, required this.chatModel}) : super(key: key);

  @override
  State<OnlineRoomOwnerWidget> createState() => _OnlineRoomOwnerWidgetState();
}

class _OnlineRoomOwnerWidgetState extends State<OnlineRoomOwnerWidget> {
  String onlineUserAvatarUrl = "";
  late String visitedUsersID;
  late String visitedEgoName;

  @override
  void initState() {
    super.initState();
    getVisitedUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getVisitedUser() async {
    visitedUserModel = await getVisitedUserInfo();
  }


  /// Get Visited Ego User info
  Future<VisitedUserModel> getVisitedUserInfo() async {
    final String _userId = widget.chatModel!.userId.toString();
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(_userId)
        .get();

    var visitedUser = VisitedUserModel.fromFirestore(response.data() as Map<String, dynamic>);
    onlineUserAvatarUrl = visitedUser.avatarUrl.toString();
    logger.d('Successfully got the visited user model');
    return visitedUser;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.all(1),
      child: Center(
        child: Stack(
            children: [

              GestureDetector(
                onTap: (){
                  visitedUsersID = widget.chatModel!.userId.toString();
                  visitedEgoName = widget.chatModel!.userNickname.toString();
                  String thisEgoName = visitedEgoName;
                  String thisUser = visitedUsersID;
                  PageRouter.gotoWidget(
                      VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                      context);
                  print("Visited User ID::: $visitedUsersID");
                },
                child: CachedNetworkImage(
                    width: 50,
                    height: 50,
                    imageUrl: onlineUserAvatarUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Image.asset(
                      "assets/images/brown_boy_mask.png",
                      width: 20,
                      height: 20,
                    ) //Icon(Icons.error),
                ),
              ),

            ]
        ),
      ),
    );
  }
}
