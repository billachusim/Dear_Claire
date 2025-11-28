import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:flutter/material.dart';
import '../../../services/data/notification_model.dart' as push_notification;
import '../../../services/notification_service.dart';
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
