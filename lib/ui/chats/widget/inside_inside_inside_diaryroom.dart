import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/firebase_services.dart';
import '../../../utils/strings.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class InsideInsideInsideChatWidget extends StatefulWidget {
  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;

  InsideInsideInsideChatWidget(
      {Key? key,
        required this.documentID,
        required this.chatModel,
        required this.chatRoomPodo,
        this.isSubChat = false})
      : super(key: key);

  @override
  State<InsideInsideInsideChatWidget> createState() => _InsideInsideInsideChatWidgetState();
}

class _InsideInsideInsideChatWidgetState extends State<InsideInsideInsideChatWidget> {
  TextEditingController editChatController = TextEditingController();

  late String visitedUsersID;

  late String visitedEgoName;

  String? _commentTime;

  String timeAgo() {
    final commentTime = widget.chatModel?.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    _commentTime = _time;
    return _commentTime.toString();
  }

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
              future: firebaseServices.getUserWithId(id: widget.chatModel!.userId),
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
            widget.chatModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 14.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          Visibility(
            visible: widget.chatModel?.audioUrl != '',
            child: Container(
              alignment: Alignment.topLeft,
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    PlayAdviseVoiceNote(filePath: widget.chatModel!.audioUrl)
                  ],
                ),
              ),
            ),
          ),


          Container(
            margin: EdgeInsets.only(bottom: 1, top: 8),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Visibility(
                      visible: widget.chatModel!.image1 != '',
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: widget.chatModel!.image1.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 85,
                            width: 70,
                            imageUrl: widget.chatModel!.image1.toString(),
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
                      widget.chatModel!.image2 != '',
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: widget.chatModel!.image2.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 85,
                            width: 70,
                            imageUrl: widget.chatModel!.image2.toString(),
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



          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection("users")
                .doc(currentUser?.uid)
                .get(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                var data = snapshot.data!.data();
                var userType = data?["userType"] ?? "0";
                debugPrint(
                    " This is the actual userType of this user ${userType.toString()}");
                return
                  Visibility(
                    visible: userType == "SUPER_ADMIN",
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (userType == "SUPER_ADMIN")
                              showCustomDialog(context,
                                  message: AppString.delete_advise_alert_note,
                                  onPressed: () {
                                    PageRouter.goBack(context);
                                    deleteSubChat();
                                  });
                          },
                          child: Row(
                            children: [

                              Text(
                                'Mod',
                                style: GoogleFonts.lato(
                                    fontSize: 13.0,
                                    color: Pallet.colorSecondary,
                                    fontWeight: FontWeight.w800),
                              ),


                              Visibility(
                                visible: userType == "SUPER_ADMIN",
                                child: GestureDetector(
                                  onTap: () {
                                    if (userType == "SUPER_ADMIN")
                                      showCustomDialog(context,
                                          message: AppString.delete_advise_alert_note,
                                          onPressed: () {
                                            PageRouter.goBack(context);
                                            deleteSubChat();
                                          });
                                  },
                                  child: Icon(
                                    Icons.delete_forever_rounded,
                                    color: Pallet.colorPrimaryDark,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
              }

              return Center(child: CircularProgressIndicator());
            },
          ),

        ],
      ),
    );
  }


  /// Delete a chat

  Future<void> deleteSubChat() async {
    final collection = FirebaseFirestore.instance
        .collection(AppString.appChats)
        .doc(widget.chatRoomPodo!.id.toString())
        .collection(widget.chatRoomPodo!.title!)
        .doc(widget.chatModel!.userId.toString())
        .collection(widget.chatModel!.userId.toString());
    await collection.doc(currentUser!.uid.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(widget.chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }
}
