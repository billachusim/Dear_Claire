import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:flutter/material.dart';
import '../../../services/user_model.dart';
import '../../../utils/constant.dart';
import '../../../widgets/toast.dart';
import '../data/chats.dart';


class OnlineRoomOwnerWidget extends StatelessWidget {
  ChatRoomPodo roomData;
  ChatModel? chatModel;


  OnlineRoomOwnerWidget({Key? key, required this.roomData, required this.chatModel}) : super(key: key);
  String onlineUserAvatarUrl = "";
  late String visitedUsersID;
  late String visitedEgoName;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      margin: EdgeInsets.all(3),
      child: Center(
        child: Stack(
            children: [

              FutureBuilder(
                  future: firebaseServices.getUserWithId(id: chatModel!.userId),
                  builder: (_, AsyncSnapshot<UserModel> snap) {
                    if (!snap.hasData) {
                      return Container();
                    }
                    UserModel? _user = snap.data;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            visitedUsersID = _user.userId ?? '';
                            visitedEgoName = _user.nickname ?? 'Chatter';
                            String thisEgoName = visitedEgoName;
                            String thisUser = visitedUsersID;
                            UserModel user = await firebaseServices.getUserInfo();
                            if (user.userType != "REGULAR") {
                              PageRouter.gotoWidget(
                                  VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                                  context);
                            }
                            else if (user.currentLoveCount > 500) {
                              PageRouter.gotoWidget(
                                  VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                                  context);
                            }
                            else {
                              showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                            }
                            print("Visited User ID::: $visitedUsersID");
                          },
                          child: CachedNetworkImage(
                              width: 45,
                              height: 45,
                              imageUrl: _user!.avatarUrl ?? '',
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 35,
                                height: 35,
                              ) //Icon(Icons.error),
                          ),
                        ),
                      ],
                    );
                  }),
            ]
        ),
      ),
    );
  }
}
