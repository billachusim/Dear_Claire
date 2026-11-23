import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../services/notification_service.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';
import 'alter_ego_chat_message_bubble.dart';

class InsideInsideInsideAlterEgoChatWidget extends StatefulWidget {
  final String? documentID;
  final ChatModel? chatModel;
  final ChatRoomPodo? chatRoomPodo;
  final bool? isSubChat;

  const InsideInsideInsideAlterEgoChatWidget(
      {Key? key,
        required this.documentID,
        required this.chatModel,
        required this.chatRoomPodo,
        this.isSubChat = false})
      : super(key: key);

  @override
  State<InsideInsideInsideAlterEgoChatWidget> createState() =>
      _InsideInsideInsideAlterEgoChatWidgetState();
}

class _InsideInsideInsideAlterEgoChatWidgetState
    extends State<InsideInsideInsideAlterEgoChatWidget> {
  // A single Future to get all user data efficiently
  late Future<Map<String, UserModel?>> _userDataFuture;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Fetch both sender and current user data in one go
    _userDataFuture = _fetchUsers();
  }

  Future<Map<String, UserModel?>> _fetchUsers() async {
    final sender = await firebaseServices.getUserWithId(id: widget.chatModel!.userId);
    final me = await firebaseServices.getUserWithId(id: currentUser!.uid);
    return {'sender': sender, 'me': me};
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the message is from the current user
    final bool isMe = currentUser?.uid == widget.chatModel?.userId;

    // Use a FutureBuilder to get the sender's and current user's info
    return FutureBuilder<Map<String, UserModel?>>(
      future: _userDataFuture,
      builder: (_, AsyncSnapshot<Map<String, UserModel?>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data?['sender'] == null ||
            snapshot.data?['me'] == null) {
          return Container(); // Return empty container on error or no data
        }

        final sender = snapshot.data!['sender']!;
        final me = snapshot.data!['me']!;

        final timeAgo = widget.chatModel?.timeCreated?.toDate() != null
            ? timeago.format(widget.chatModel!.timeCreated!.toDate())
            : 'just now';

        // Check if the current user can delete the message
        final bool canDelete = me.userType == "SUPER_ADMIN";

        // --- IDENTITY LOGIC ---
        final bool isAdminPortal = widget.chatRoomPodo?.id == 5;

        // Check if the sender of THIS SPECIFIC MESSAGE is an admin
        final bool isMessageFromAdmin = widget.chatModel?.userType == "ADMIN" ||
            widget.chatModel?.userType == "SUPER_ADMIN";

        const String claireAvatar = "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691";

        // 1. Determine Display Name
        String displayName;
        if (isAdminPortal && isMessageFromAdmin) {
          displayName = 'Claire';
        } else {
          // Priority: 1. Stored Nickname (from Public side) -> 2. AlterEgoId -> 3. Fallback
          displayName = widget.chatModel?.userNickname ??
              sender.alterEgoId ??
              sender.nickname ??
              'An Ego';
        }

        // 2. Determine Display Avatar
        String displayAvatar;
        if (isAdminPortal && isMessageFromAdmin) {
          displayAvatar = claireAvatar;
        } else {
          // Use stored avatar if available, otherwise fallback to live profile
          displayAvatar = widget.chatModel?.userAvatarUrl ??
              sender.avatarUrl ??
              '';
        }
        return AlterEgoChatMessageBubble(
          chatModel: widget.chatModel!,
          senderName: displayName,
          senderAvatarUrl: displayAvatar,
          timeAgo: timeAgo,
          isMe: isMe,
          showId: isAdminPortal,
          onAvatarTap: () => _handleAvatarTap(context, sender, me),
          onDelete: canDelete
              ? () => showCustomDialog(context,
              message: "Are you sure you want to delete this message?",
              onPressed: () {
                PageRouter.goBack(context);
                deleteAlterEgoSubChat();
              })
              : null,
        );


      },
    );
  }

  // --- AVATAR TAP LOGIC ---
  void _handleAvatarTap(BuildContext context, UserModel visitedUser, UserModel visitingUser) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 20, color: Colors.white),
      ),
      barrierDismissible: false,
    );

    try {
      const int visitCost = 1;

      if (visitingUser.userId == visitedUser.userId) {
        Navigator.pop(context); // Close loader
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: visitedUser.userId!,
                visitedEgoName: visitedUser.alterEgoId!),
            context);
        return;
      }

      if (visitingUser.currentLoveCount < visitCost) {
        Navigator.pop(context); // Close loader
        showToast("You need at least 1❤️ to visit an Alter Ego's profile.");
        return;
      }

      final bool success = await firebaseServices.transferLoveBetweenUsers(
        senderId: visitingUser.userId!,
        receiverId: visitedUser.userId!,
        amountToSend: visitCost,
        taxAmount: 0,
        totalDebitAmount: visitCost,
        senderTransactionDesc: "1❤️ visiting ${visitedUser.alterEgoId}'s Alter Ego.",
        receiverTransactionDesc: "1❤️ from ${visitingUser.alterEgoId} visiting your Alter Ego.",
        claireTransactionDesc: "Tax from an Alter Ego profile visit.",
        forProfileVisits: 1,
        fromProfileVisits: 1,
      );

      Navigator.pop(context); // Close loader

      if (success) {
        if (visitedUser.fcmId != null && visitedUser.fcmId!.isNotEmpty) {
          notificationService.sendNotification({
            "token": visitedUser.fcmId,
            "notification": {
              "title": "Your Alter Ego profile has a visitor!",
              "body": "${visitingUser.alterEgoId ?? 'An Alter Ego'} just visited your profile with a kola of 1❤️."
            },
            "data": {"route": "egoPage"}
          });
        }
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: visitedUser.userId!,
                visitedEgoName: visitedUser.alterEgoId!),
            context);
      } else {
        showToast("Profile visit failed. Please try again.");
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      print("Error during avatar tap: $e");
      showToast("An error occurred.");
    }
  }

  // --- DELETE CHAT LOGIC ---
  Future<void> deleteAlterEgoSubChat() async {
    try {
      final collection = FirebaseFirestore.instance
          .collection("alterEgoChats")
          .doc(widget.chatRoomPodo!.id.toString())
          .collection(widget.chatModel!.sessionId!);
      await collection.doc(widget.documentID).delete();
      showToast('Message deleted by Mod.');
    } catch (e) {
      print('Error deleting Alter Ego sub-chat: $e');
      showToast('Failed to delete message.');
    }
  }
}
