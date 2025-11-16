import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import 'alter_ego_sub_room_online_users_stream.dart';

class InsideInsideAlterEgoChatWidget extends StatelessWidget {
  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;

  late String visitedUsersID;
  late String visitedEgoName;

  InsideInsideAlterEgoChatWidget(
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
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CachedNetworkImage(
                        width: 55,
                        height: 55,
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
                    SizedBox(
                      width: 6,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_user.alterEgoId ?? '',
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: GoogleFonts.lato(
                                  fontSize: 18.0,
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
                                  fontSize: 12.0,
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
                fontSize: 17.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.bold),
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
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: chatModel!.image1.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 120,
                            width: 100,
                            imageUrl: chatModel!.image1.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                image: DecorationImage(
                                  image: imageProvider,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
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
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: chatModel!.image2.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 120,
                            width: 100,
                            imageUrl: chatModel!.image2.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                image: DecorationImage(
                                  image: imageProvider,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                              width: 48,
                              height: 48,
                            ) //Icon(Icons.error),
                        ),
                      )),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 2,
          ),

          Row(
            children: [

              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AlterEgoOnlineRoomVisitorsStream(roomData: chatRoomPodo!, roomModel: chatModel!, docId: documentID!,)),

              Spacer(flex: 1,),

              Align(
                alignment: Alignment.bottomRight,
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
                        '${chatModel!.members!.length} Online',
                        style: TextStyle(
                            color: _isCompleted(chatModel, chatRoomPodo)
                                ? Pallet.blueGreyBgColor
                                : Pallet.colorSplashScreen),
                      ),
                    )),
              ),
            ],
          )
        ],
      ),
    );
  }

  bool _isCompleted(ChatModel? chatModel, ChatRoomPodo? chatRoomPodo) {
    return chatModel!.members!.length == chatRoomPodo?.numberOfParticipants;
  }
}
