import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/data/notification_model.dart' as push_notification;
import '../../../services/notification_service.dart';
import '../../../services/user_model.dart';
import '../../../utils/constant.dart';
import '../../../widgets/toast.dart';
import '../data/chats.dart';

class OnlineRoomOwnerWidget extends StatefulWidget {
  ChatRoomPodo roomData;
  ChatModel? chatModel;

  OnlineRoomOwnerWidget(
      {Key? key, required this.roomData, required this.chatModel})
      : super(key: key);

  @override
  State<OnlineRoomOwnerWidget> createState() => _OnlineRoomOwnerWidgetState();
}

class _OnlineRoomOwnerWidgetState extends State<OnlineRoomOwnerWidget> {
  String onlineUserAvatarUrl = "";

  late String visitedUsersID;

  late String visitedEgoName;

  bool _isAvatarLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      margin: EdgeInsets.all(3),
      child: Center(
        child: Stack(children: [
          FutureBuilder(
              future:
                  firebaseServices.getUserWithId(id: widget.chatModel!.userId),
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
                          final visitingUser =
                              await firebaseServices.getUserInfo();
                          final String visitedUserId = _user.userId!;
                          final String visitedEgoName = _user.nickname!;
                          const int visitCost = 1;

                          // --- 2. HANDLE SELF-VISIT, INSUFFICIENT LOVES & PERMISSIONS ---
                          if (visitingUser.userId == visitedUserId) {
                            // If visiting self, just navigate without a transaction.
                            PageRouter.gotoWidget(
                                VisitedUserEgoProfilePage(
                                    visitedUsersID: visitedUserId,
                                    visitedEgoName: visitedEgoName),
                                context);
                            return;
                          }

                          if (visitingUser.userType == "REGULAR" &&
                              visitingUser.currentLoveCount < 100) {
                            showToast(
                                "Need up to 500 Loves in Wallet or Alter Ego Access to view other Ego Profiles.");
                            return;
                          }

                          if (visitingUser.currentLoveCount < visitCost) {
                            showToast(
                                "You need at least 1 ❤️ to visit a profile.");
                            return;
                          }

                          // --- 3. PERFORM THE LOVE TRANSACTION ---
                          final bool success =
                              await firebaseServices.transferLoveBetweenUsers(
                            senderId: visitingUser.userId!,
                            receiverId: visitedUserId,
                            amountToSend: visitCost,
                            taxAmount: 0,
                            totalDebitAmount: visitCost,
                            senderTransactionDesc:
                                "1❤️ visiting ${visitedEgoName}'s Ego.",
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

                          // --- 4. NAVIGATE ON SUCCESS ---
                          if (success) {
                            showToast("You are visiting ${visitedEgoName} with a kola of 1❤️.");

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
                              width: 40,
                              height: 40,
                              imageUrl: _user!.avatarUrl ?? '',
                              imageBuilder: (context, imageProvider) =>
                                  Container(
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
                  ],
                );
              }),
        ]),
      ),
    );
  }
}
