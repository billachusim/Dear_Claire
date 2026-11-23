import 'dart:ui'; // Required for ImageFilter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/widget/diaryroom_online_users_stream.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Haptics
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/transaction_model.dart' as t_model;
import '../../../services/user_model.dart';
import '../../../utils/constant.dart';
import '../../../widgets/toast.dart';
import '../../ego-profile/top_up_loves_page.dart';
import '../inside_chatroom.dart';

class ChatRoomWidget extends StatefulWidget {
  final ChatRoomPodo element; // Added final for best practice

  ChatRoomWidget({Key? key, required this.element}) : super(key: key);

  @override
  State<ChatRoomWidget> createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Color roomBaseColor = HexColor.fromHex(widget.element.hex!);

    return CupertinoButton(
      onPressed: () async {
        if (isLoading) return;
        HapticFeedback.mediumImpact();
        setState(() => isLoading = true);

        try {
          UserModel user = await firebaseServices.getUserInfo();
          const int roomEntryCost = 1;
          const int specialRoomLoveRequirement = 2000;

          final isSpecialRoom = widget.element.title == "One On One Room" ||
              widget.element.title == "Five Aside Room" || widget.element.title == "Eleven Aside Room" ||
              widget.element.title == "Chat Or Eavesdrop Inside Claire's DM";

          if (isSpecialRoom && user.currentLoveCount <= specialRoomLoveRequirement) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => TopUpLovesPage(feature: 'diary_rooms'),
            ));
            return;
          }

          if (user.currentLoveCount < roomEntryCost) {
            showToast("You need at least $roomEntryCost❤️ to enter.");
            return;
          }

          final bool transactionSuccess = await firebaseServices.updateTreasuryAndUser(
            userId: user.userId!,
            amount: roomEntryCost,
            type: t_model.TransactionType.debit,
            userTransactionDescription: "$roomEntryCost❤️ to enter ${widget.element.title}.",
            forRoomVisits: roomEntryCost,
            metadata: {'room_id': widget.element.id, 'room_title': widget.element.title},
          );

          if (transactionSuccess) {
            showToast("Welcome to ${widget.element.title}! Positive vibes only");
            await firebaseServices.saveUserActivity(
              activityType: 'room_join',
              activityMessage: "You entered Claire's room: ${widget.element.title}.",
              sessionId: widget.element.id.toString(),
            );
            if (!mounted) return;
            PageRouter.gotoWidget(ChatScreen(chatRoomPodo: widget.element), context);
          }
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      },
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    roomBaseColor,
                    Pallet.colorSecondaryDark,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Image.asset("assets/images/claire_icon.png", height: 45, width: 45),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ANONYMOUS DIARYROOM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'By Claire 🌺',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.element.title!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.element.text!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Participants Stream
                      SizedBox(
                        width: 180,
                        child: OnlineRoomOwnersStream(roomData: widget.element),
                      ),
                      const Spacer(),
                      // Action/Live Indicator Area
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StreamBuilder(
                            stream: firebaseServices.getChats(widget.element),
                            builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                              if (!snapShot.hasData) return const SizedBox();
                              return Row(
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${snapShot.data!.docs.length} LIVE",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          isLoading
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              'ENTER',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
