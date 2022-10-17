import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/widget/diaryroom_online_users_stream.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () async {
        UserModel user = await firebaseServices.getUserInfo();
        if (widget.element.title != "One On One Room" && widget.element.title != "Five Aside Room") {
          PageRouter.gotoWidget(
              ChatScreen(chatRoomPodo: widget.element), context);
        }
        else if (user.currentLoveCount > 2000) {
          PageRouter.gotoWidget(
              ChatScreen(chatRoomPodo: widget.element), context);
        }
        else {
          showToast("You need up to 2000 Loves first");
        }
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

                    GestureDetector(
                      child: Container(
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
