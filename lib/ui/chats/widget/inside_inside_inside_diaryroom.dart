import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/enums.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/strings.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class InsideInsideInsideChatWidget extends StatelessWidget {
  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;

  late String visitedUsersID;
  late String visitedEgoName;

  String? _commentTime;

  String timeAgo() {
    final commentTime = chatModel?.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    _commentTime = _time;
    return _commentTime.toString();
  }

  InsideInsideInsideChatWidget(
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
          image: DecorationImage(
            image: AssetImage(
              AppImages.appChatBg,
            ),
            fit: BoxFit.fill,
          ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
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
                            child: Text(_user.nickname ?? '',
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 13.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w800)),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                              timeAgo(),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: GoogleFonts.lato(
                                  fontSize: 11.0,
                                  color: Pallet.colorGrey,
                                  fontWeight: FontWeight.normal)),
                        ],
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

          Visibility(
            visible: chatModel?.audioUrl != '',
            child: Container(
              alignment: Alignment.topLeft,
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    PlayAdviseVoiceNote(filePath: chatModel!.audioUrl)
                  ],
                ),
              ),
            ),
          ),


          Container(
            margin: EdgeInsets.only(bottom: 10, top: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Visibility(
                      visible: chatModel!.image1 != '',
                      child: FullScreenWidget(
                        child: CachedNetworkImage(
                            height: 75,
                            width: 75,
                            imageUrl: chatModel!.image1.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
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
                              width: 48,
                              height: 48,
                            ) //Icon(Icons.error),
                        ),
                      )),
                  SizedBox(
                    width: 5,
                  ),
                  Visibility(
                      visible:
                      chatModel!.image2 != '',
                      child: FullScreenWidget(
                        child: CachedNetworkImage(
                            height: 75,
                            width: 75,
                            imageUrl: chatModel!.image2.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
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
                              width: 48,
                              height: 48,
                            ) //Icon(Icons.error),
                        ),
                      )),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
