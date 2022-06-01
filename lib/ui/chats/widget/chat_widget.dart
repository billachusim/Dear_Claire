import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/chats/sub_chat_screen.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/enums.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:dear_claire/widgets/thanks_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatWidget extends StatelessWidget {

  UserModel userModel = UserModel();
  User? currentUser = FirebaseAuth.instance.currentUser;

  getUser() async {
    userModel = await firebaseServices.getUserInfo();
  }

  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;
  late String visitedUsersID;
  late String visitedEgoName;
  late UserModel _userModel;

  ChatWidget(
      {Key? key,
      required this.documentID,
      required this.chatModel,
      required this.chatRoomPodo,
      this.isSubChat = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), color: Pallet.colorWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder(
              future: firebaseServices.getUserWithId(id: chatModel!.userId),
              builder: (_, AsyncSnapshot<UserModel> snap) {
                if (!snap.hasData) {
                  return Container();
                }
                UserModel? _user = snap.data;
                _userModel = snap.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        visitedUsersID = _user?.userId ?? '';
                        visitedEgoName = _user?.nickname ?? 'Chatter';
                        String thisEgoName = visitedEgoName;
                        String thisUser = visitedUsersID;
                        PageRouter.gotoWidget(
                            VisitedUserEgoProfilePage(
                                visitedUsersID: thisUser,
                                visitedEgoName: thisEgoName),
                            context);
                        print("Visited User ID::: $visitedUsersID");
                      },
                      child: CachedNetworkImage(
                          width: 35,
                          height: 35,
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
                                "assets/images/brown_boy_mask.png",
                                width: 35,
                                height: 35,
                              ) //Icon(Icons.error),
                          ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          visitedUsersID = _user.userId ?? '';
                          visitedEgoName = _user.nickname ?? 'Chatter';
                          String thisEgoName = visitedEgoName;
                          String thisUser = visitedUsersID;
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: thisUser,
                                  visitedEgoName: thisEgoName),
                              context);
                          print("Visited User ID::: $visitedUsersID");
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user.nickname ?? '',
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 13.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(
                              height: 2,
                            ),
                            Text(
                                timeConverter(chatModel!.timeCreated!,
                                    time: TimeConverterEnum.Comment),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 11.0,
                                    color: Pallet.colorGrey,
                                    fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
          SizedBox(
            height: 6,
          ),
          Text(
            chatModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 14.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: InkWell(
              onTap: () {

                visitedUsersID = _userModel.userId ?? '';
                String thisUser = visitedUsersID;

                if (!_isCompleted(chatModel, chatRoomPodo))
                  PageRouter.gotoWidget(
                      SubChatScreen(
                          documentID: thisUser,
                          chatModel: chatModel,
                          chatRoomPodo: chatRoomPodo,
                      ),
                      context);
              },
              child: Container(
                  padding: EdgeInsets.all(5),
                  width: 110,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                        color: _isCompleted(chatModel, chatRoomPodo)
                            ? Pallet.blueGreyBgColor
                            : Pallet.colorSplashScreen),
                    gradient: LinearGradient(
                      begin: Alignment(
                          -0.37857140550652835, -1.9473685559777252),
                      end: Alignment(1.2428571464417884, 2.526316110739735),
                      stops: [0.0, 0.856177031993866, 1.0],
                      colors: [
                        Colors.white70,
                        Pallet.colorPrimary,
                        Pallet.colorSecondaryDark,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${chatModel!.members!.length} Join chat',
                      style: TextStyle(
                          color: _isCompleted(chatModel, chatRoomPodo)
                              ? Pallet.blueGreyBgColor
                              : Pallet.colorSplashScreen),
                    ),
                  )),
            ),
          )
        ],
      ),
    );
  }

  bool _isCompleted(ChatModel? chatModel, ChatRoomPodo? chatRoomPodo) {
    return chatModel!.members!.length == chatRoomPodo?.numberOfParticipants;
  }
}
