import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/data/notification_model.dart' as push_notification;
import '../../../services/firebase_services.dart';
import '../../../services/notification_service.dart';
import '../../../utils/strings.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../../widgets/toast.dart';
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
  bool _isAvatarLoading = false;


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
                      onTap: () async {
                        setState(() {
                          _isAvatarLoading = true;
                        });
                        try {
                        // --- 1. SETUP TRANSACTION DETAILS ---
                        final visitingUser = await firebaseServices.getUserInfo();
                        final String visitedUserId = _user.userId!;
                        final String visitedEgoName = _user.nickname!;
                        const int visitCost = 1;
                        // --- 2. HANDLE SELF-VISIT ---
                        if (visitingUser.userId == visitedUserId) {
                          // If visiting self, just navigate without a transaction.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: visitedUserId,
                                  visitedEgoName: visitedEgoName),
                              context);
                          return;
                        }

                        // --- 3. CHECK PERMISSIONS & SUFFICIENT LOVES ---
                        // Note: The permission message was slightly different, so I've used the more descriptive one from the avatar's logic.
                        if (visitingUser.userType == "REGULAR" &&
                            visitingUser.currentLoveCount < 500) { // Changed from 50 to 500 for consistency
                          showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                          return;
                        }

                        if (visitingUser.currentLoveCount < visitCost) {
                          showToast("You need at least 1 ❤️ to visit a profile.");
                          return;
                        }

                        // --- 4. PERFORM THE LOVE TRANSACTION ---
                        final bool success =
                        await firebaseServices.transferLoveBetweenUsers(
                          senderId: visitingUser.userId!,
                          receiverId: visitedUserId,
                          amountToSend: visitCost,
                          taxAmount: 0,
                          totalDebitAmount: visitCost,
                          senderTransactionDesc:
                          "1❤️ for visiting ${visitedEgoName}'s Ego.",
                          receiverTransactionDesc:
                          "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                          claireTransactionDesc:
                          "Tax from a profile visit.", // Will be 0, but required
                          forProfileVisits: 1, // Stat for the sender
                          fromProfileVisits: 1, // Stat for the receiver
                          metadata: {
                            'reason': 'profile_visit',
                            'visitedUserId': visitedUserId
                          },
                        );

                        // --- 5. NAVIGATE ON SUCCESS ---
                        if (success) {
                          // --- SEND NOTIFICATION ---
                          try {
                            await notificationService.sendNotification(
                                push_notification.NotificationModel(
                                    topic: visitedUserId,
                                    data: push_notification.Data(id: visitedUserId, route: 'wallet'),
                                    notification: push_notification.Notification(
                                        title: "Someone Visited Your Ego!",
                                        body: "${visitingUser.nickname} visited your Ego Profile with a kola of 1❤️."
                                    )
                                ).toJson()
                            );
                          } catch (e) {
                            print("Failed to send profile visit notification: $e");
                            // Do not block navigation if notification fails
                          }

                          // --- NAVIGATE ---
                          // Only navigate to the profile if the transaction was successful.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: visitedUserId,
                                  visitedEgoName: visitedEgoName),
                              context);
                        }
                        } finally {
                          // --- 3. HIDE THE LOADER (GUARANTEED) ---
                          // This runs no matter how the try block exits.
                          if (mounted) {
                            setState(() {
                              _isAvatarLoading = false;
                            });
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          CachedNetworkImage(
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
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 35,
                                height: 35,
                              ) //Icon(Icons.error),
                          ),
                          // --- 2. ADD THE OVERLAY LOADER ---
                          if (_isAvatarLoading)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
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
                            onTap: () async {
                              // --- 1. SETUP TRANSACTION DETAILS ---
                              final visitingUser = await firebaseServices.getUserInfo();
                              final String visitedUserId = _user.userId!;
                              final String visitedEgoName = _user.nickname!;
                              const int visitCost = 1;
                              // --- 2. HANDLE SELF-VISIT ---
                              if (visitingUser.userId == visitedUserId) {
                                // If visiting self, just navigate without a transaction.
                                PageRouter.gotoWidget(
                                    VisitedUserEgoProfilePage(
                                        visitedUsersID: visitedUserId,
                                        visitedEgoName: visitedEgoName),
                                    context);
                                return;
                              }

                              // --- 3. CHECK PERMISSIONS & SUFFICIENT LOVES ---
                              // Note: The permission message was slightly different, so I've used the more descriptive one from the avatar's logic.
                              if (visitingUser.userType == "REGULAR" &&
                                  visitingUser.currentLoveCount < 500) { // Changed from 50 to 500 for consistency
                                showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                                return;
                              }

                              if (visitingUser.currentLoveCount < visitCost) {
                                showToast("You need at least 1 ❤️ to visit a profile.");
                                return;
                              }

                              // --- 4. PERFORM THE LOVE TRANSACTION ---
                              final bool success =
                              await firebaseServices.transferLoveBetweenUsers(
                                senderId: visitingUser.userId!,
                                receiverId: visitedUserId,
                                amountToSend: visitCost,
                                taxAmount: 0,
                                totalDebitAmount: visitCost,
                                senderTransactionDesc:
                                "1❤️for visiting ${visitedEgoName}'s Ego.",
                                receiverTransactionDesc:
                                "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                                claireTransactionDesc:
                                "Tax from a profile visit.", // Will be 0, but required
                                forProfileVisits: 1, // Stat for the sender
                                fromProfileVisits: 1, // Stat for the receiver
                                metadata: {
                                  'reason': 'profile_visit',
                                  'visitedUserId': visitedUserId
                                },
                              );

                              // --- 5. NAVIGATE ON SUCCESS ---
                              if (success) {
                                // --- SEND NOTIFICATION ---
                                try {
                                  await notificationService.sendNotification(
                                      push_notification.NotificationModel(
                                          topic: visitedUserId,
                                          data: push_notification.Data(id: visitedUserId, route: 'wallet'),
                                          notification: push_notification.Notification(
                                              title: "Someone Visited Your Ego!",
                                              body: "${visitingUser.nickname} visited your Ego Profile with a kola of 1❤️."
                                          )
                                      ).toJson()
                                  );
                                } catch (e) {
                                  print("Failed to send profile visit notification: $e");
                                  // Do not block navigation if notification fails
                                }

                                // --- NAVIGATE ---
                                // Only navigate to the profile if the transaction was successful.
                                PageRouter.gotoWidget(
                                    VisitedUserEgoProfilePage(
                                        visitedUsersID: visitedUserId,
                                        visitedEgoName: visitedEgoName),
                                    context);
                              }
                            },
                            child: Text(_user.nickname ?? '',
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 14.0,
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
          SelectableLinkify(
            onOpen: (link) async {
              final Uri url = Uri.parse("${link.url}");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                throw 'Could not launch $link';
              }
            },
            linkStyle: TextStyle(color: Colors.blue),
            text: widget.chatModel!.message!,
            textAlign: TextAlign.justify,
            style: GoogleFonts.lato(
                fontSize: 15.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          Visibility(
            visible: widget.chatModel?.audioUrl != '',
            child: Container(
              child: PlayAdviseVoiceNote(filePath: widget.chatModel!.audioUrl),
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



          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection("users")
                .doc(currentUser?.uid)
                .get(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                var data = snapshot.data!.data();
                var userType = data?["userType"];

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

              return Container();
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
