import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../helpers/toast_helper.dart';
import '../../../services/firebase_services.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';
import 'chat_message_bubble.dart';

class InsideInsideInsideChatWidget extends StatefulWidget {
  final String? documentID;
  final ChatModel? chatModel;
  final ChatRoomPodo? chatRoomPodo;

  const InsideInsideInsideChatWidget(
      {Key? key,
        required this.documentID,
        required this.chatModel,
        required this.chatRoomPodo})
      : super(key: key);

  @override
  State<InsideInsideInsideChatWidget> createState() =>
      _InsideInsideInsideChatWidgetState();
}

class _InsideInsideInsideChatWidgetState
    extends State<InsideInsideInsideChatWidget> {
  // We no longer need the local _isAvatarLoading state here,
  // as the avatar tap logic is simplified.

  @override
  Widget build(BuildContext context) {
    // Get the current user to determine if the message is "isMe"
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMe = currentUser?.uid == widget.chatModel?.userId;

    // Use a FutureBuilder to get the sender's user info just once.
    return FutureBuilder<UserModel?>(
      future: firebaseServices.getUserWithId(id: widget.chatModel!.userId),
      builder: (_, AsyncSnapshot<UserModel?> snapshot) {
        // While waiting for user data, show a simple placeholder
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: CupertinoActivityIndicator(),
          );
        }
        // If there's an error or no data, show an empty container.
        if (!snapshot.hasData || snapshot.data == null) {
          return Container();
        }

        final sender = snapshot.data!;
        final timeAgo = widget.chatModel?.timeCreated?.toDate() != null
            ? timeago.format(widget.chatModel!.timeCreated!.toDate())
            : 'just now';

        // --- THE UI TRANSFORMATION ---
        return ChatMessageBubble(
          chatModel: widget.chatModel!, // <<< THE FIX: Pass the entire model
          senderName: sender.nickname ?? 'An Ego',
          senderAvatarUrl: sender.avatarUrl ?? '',
          timeAgo: timeAgo,
          isMe: isMe,
          onAvatarTap: () {
            _handleAvatarTap(context, sender);
          },
        );

      },
    );
  }

  // --- This logic is extracted for clarity and re-use ---
  void _handleAvatarTap(BuildContext context, UserModel visitedUser) async {
    // This is the clean profile visit logic from your other files.
    showCupertinoDialog(
      context: context,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 20, color: Colors.white),
      ),
      barrierDismissible: false,
    );

    try {
      final visitingUser = await firebaseServices.getUserInfo();
      const int visitCost = 1;

      if (visitingUser.userId == visitedUser.userId) {
        Navigator.pop(context); // Close loader
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: visitedUser.userId!,
                visitedEgoName: visitedUser.nickname!),
            context);
        return;
      }

      if (visitingUser.currentLoveCount < visitCost) {
        Navigator.pop(context); // Close loader
        showToast(message: "You need at least 1 ❤️ to visit a profile.");
        return;
      }

      final bool success = await firebaseServices.transferLoveBetweenUsers(
        senderId: visitingUser.userId!,
        receiverId: visitedUser.userId!,
        amountToSend: visitCost,
        taxAmount: 0,
        totalDebitAmount: visitCost,
        senderTransactionDesc: "1❤️ visiting ${visitedUser.nickname}'s Ego.",
        receiverTransactionDesc: "1❤️ from ${visitingUser.nickname} visiting your Ego.",
        claireTransactionDesc: "Tax from a profile visit.",
        forProfileVisits: 1,
        fromProfileVisits: 1,
      );

      Navigator.pop(context); // Close loader

      if (success) {
        // Send notification logic can be added here if desired, following the pattern.
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: visitedUser.userId!,
                visitedEgoName: visitedUser.nickname!),
            context);
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      print("Error during avatar tap: $e");
      showToast(message: "An error occurred.");
    }
  }
}
