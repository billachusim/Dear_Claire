import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/transaction_model.dart' as t_model;
import '../../../services/user_model.dart';
import '../../../utils/constant.dart';
import 'alter_ego_room_online_users_stream.dart';
import 'inside_alter_ego_diaryroom.dart';

class AlterEgoChatRoomWidget extends StatefulWidget {
  ChatRoomPodo element;

  AlterEgoChatRoomWidget({Key? key, required this.element}) : super(key: key);

  @override
  State<AlterEgoChatRoomWidget> createState() => _AlterEgoChatRoomWidgetState();
}

class _AlterEgoChatRoomWidgetState extends State<AlterEgoChatRoomWidget> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () async {
        // --- 1. PREVENT DOUBLE TAPS & SHOW LOADER ---
        if (isLoading) return;
        setState(() {
          isLoading = true;
        });

        try {
          // --- 2. FETCH USER DATA ---
          UserModel user = await firebaseServices.getUserInfo();

          // --- 3. HANDLE SPECIAL ROOM CONDITIONS ---
          if (widget.element.title == "Band Of Super Egos" && user.userType != "SUPER_ADMIN") {
            showToast("You have to be a super ego first.");
            return; // Exit early
          }

          // --- 4. DEFINE COSTS & CHECK REQUIREMENTS (for all other rooms) ---
          const int roomEntryCost = 1;

          // Check if the user can afford the basic entry cost
          if (user.currentLoveCount < roomEntryCost) {
            showToast("You need at least $roomEntryCost❤️ to enter this Alter Ego room.");
            return; // Exit early
          }

          // --- 5. PERFORM TRANSACTION ---
          final bool transactionSuccess = await firebaseServices.updateTreasuryAndUser(
            userId: user.userId!,
            amount: roomEntryCost,
            type: t_model.TransactionType.debit,
            userTransactionDescription: "$roomEntryCost❤️ to enter Alter Ego room: ${widget.element.title}.",
            forRoomVisits: roomEntryCost,
            metadata: {
              'room_id': widget.element.id,
              'room_title': widget.element.title,
              'context': 'alter_ego_room_entry'
            },
          );

          // --- 6. PROCEED ONLY IF TRANSACTION IS SUCCESSFUL ---
          if (transactionSuccess) {
            showToast("Welcome to ${widget.element.title}! Behave yourself.");

            await firebaseServices.saveUserActivity(
              activityType: 'room_join',
              activityMessage: "You entered the Alter Ego room: ${widget.element.title}.",
              sessionId: widget.element.id.toString(),
            );

            if (!mounted) return;
            PageRouter.gotoWidget(
                AlterEgoChatScreen(chatRoomPodo: widget.element), context);
          } else {
            showToast("Could not process entry. Please try again.");
          }
        } finally {
          // --- 7. HIDE THE LOADER (GUARANTEED) ---
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      },
      padding: EdgeInsets.zero,
      child: Container(
        // ... your existing Container styling ...
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: HexColor.fromHex(widget.element.hex!)),
        child: Column(
          // ... all your existing Column children ...
          children: [
            // ... (Container for image, Text for title, etc.)
            Container(
              height: 70,
              width: getDeviceWidth(context),
              margin: EdgeInsets.only(top: 6, bottom: 4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(image: AssetImage(widget.element.image.toString()),
                      fit: BoxFit.fill)
              ),
              child: Container(),
            ),
            SizedBox(
              height: 6,
            ),
            Center(
              child: Text(widget.element.title!,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  style: GoogleFonts.lato(
                      fontSize: 28.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 9,
            ),
            Text(
              widget.element.text!,
              textAlign: TextAlign.start,
              style: GoogleFonts.lato(
                  fontSize: 23.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.normal),
            ),
            SizedBox(height: 8,),
            Row(
              children: [
                SizedBox(
                    width: 220,
                    child:
                    AlterEgoOnlineRoomOwnersStream(roomData: widget.element,)
                ),
                Spacer(flex: 1,),
                Column(
                  children: [
                    StreamBuilder(
                      //... stream builder for live rooms count
                        stream: firebaseServices
                            .getAlterEgoChats(widget.element),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                          if (snapShot.hasError) {
                            return Container();
                          }
                          if (snapShot.hasData) {
                            return Text(
                              snapShot.data!.docs.length.toString() + " Live Rooms 🔥",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600
                              ),
                            );
                          }
                          return Container();
                        }),
                    SizedBox(height: 4,),
                    // --- MODIFICATION FOR LOADING INDICATOR ---
                    Container(
                      margin: EdgeInsets.only(bottom: 6),
                      padding: EdgeInsets.all(5),
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment(-0.37857140550652835, -1.9473685559777252),
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
                        child: isLoading
                            ? CupertinoActivityIndicator(color: Pallet.colorSecondaryDark)
                            : Text(
                          'O P E N',
                          style: GoogleFonts.lato(
                              fontSize: 16.0,
                              color: Pallet.colorSecondaryDark,
                              fontWeight: FontWeight.w700),
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
    );

  }
}
