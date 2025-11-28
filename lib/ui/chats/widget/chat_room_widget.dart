import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/widget/diaryroom_online_users_stream.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/transaction_model.dart' as t_model;
import '../../../services/user_model.dart';
import '../../../utils/constant.dart';
import '../../../widgets/toast.dart';
import '../inside_chatroom.dart';

class ChatRoomWidget extends StatefulWidget {
  ChatRoomPodo element;

  ChatRoomWidget({Key? key, required this.element}) : super(key: key);

  @override
  State<ChatRoomWidget> createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () async {
        setState(() {
          isLoading = true;
        });

        UserModel user = await firebaseServices.getUserInfo();

        // Define the cost and check if the user can afford it
        const int roomEntryCost = 1;
        if (user.currentLoveCount < roomEntryCost) {
          showToast("You need at least 1 ❤️ to enter a room.");
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Check for room-specific requirements (like the 2000 loves for certain rooms)
        if ((widget.element.title == "One On One Room" ||
            widget.element.title == "Five Aside Room") &&
            user.currentLoveCount <= 2000) {
          showToast("You need more than 2000 Loves for this room.");
          setState(() {
            isLoading = false;
          });
          return;
        }

        // --- TRANSACTION LOGIC ---
        // If all checks pass, deduct the love for entering the room.
        await firebaseServices.updateTreasuryAndUser(
          userId: user.userId!,
          amount: roomEntryCost,
          type: t_model.TransactionType.debit,
          // User is spending
          userTransactionDescription: "1❤️ to enter ${widget.element
              .title}.",
          forRoomVisits: roomEntryCost,
          // Increment the 'forRoomVisits' stat
          metadata: {
            'room_id': widget.element.id,
            'room_title': widget.element.title
          },
        );
        // --- ADD THIS LINE TO SAVE THE JOIN ROOM ACTIVITY ---
        await firebaseServices.saveUserActivity(
          activityType: 'room_join',
          activityMessage: "You joined the room: ${widget.element.title}.",
          // We will use the 'sessionId' field to store the room's ID.
          sessionId: widget.element.id.toString(),
        );

        // Navigate to the chat screen after the transaction
        PageRouter.gotoWidget(
            ChatScreen(chatRoomPodo: widget.element), context);

        setState(() {
          isLoading = false;
        });
      },
      padding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: HexColor.fromHex(widget.element.hex!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/claire_icon.png",
                  height: 50,
                  width: 50,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Anonymous  Diaryroom',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 17.0,
                              color: Pallet.colorWhite,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 3,
                      ),
                      Text('By Claire 🌺',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 15.0,
                              color: Pallet.colorWhite,
                              fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
                height: 7,
            ),
            Center(
              child: Text(widget.element.title!,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  style: GoogleFonts.lato(
                      fontSize: 23.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 9,
            ),
            Text(
              widget.element.text!,
              textAlign: TextAlign.justify,
              style: GoogleFonts.lato(
                  fontSize: 20.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 8,),


            Row(
              children: [
                SizedBox(
                  width: 220,
                    child:
                    OnlineRoomOwnersStream(roomData: widget.element,)
                ),

                Spacer(flex: 1,),

                Column(
                  children: [
                    StreamBuilder(
                        stream: firebaseServices
                            .getChats(widget.element),
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

                    isLoading != true?
                    Container(
                      margin: EdgeInsets.only(bottom: 6),
                      padding: EdgeInsets.all(5),
                      width: 115,
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
                        child: Text('O P E N',
                          style: GoogleFonts.lato(
                              fontSize: 15.0,
                              color: Pallet.colorSecondaryDark,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ):
                        CircularProgressIndicator()
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
