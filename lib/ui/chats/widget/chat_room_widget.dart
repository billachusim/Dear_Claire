import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../inside_chatroom.dart';

class ChatRoomWidget extends StatelessWidget {
  ChatRoomPodo element;

  ChatRoomWidget({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () =>
          PageRouter.gotoWidget(ChatScreen(chatRoomPodo: element), context),
      padding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: HexColor.fromHex(element.hex!)),
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
                      Text('Anonymous Chatroom',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 16.0,
                              color: Pallet.colorWhite,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 3,
                      ),
                      Text('By Claire🌺',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: Pallet.colorWhite,
                              fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
                height: 6,
            ),
            Center(
              child: Text(element.title!,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  style: GoogleFonts.lato(
                      fontSize: 19.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 9,
            ),
            Text(
              element.text!,
              textAlign: TextAlign.start,
              style: GoogleFonts.lato(
                  fontSize: 16.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.normal),
            ),

            SizedBox(height: 8,),


            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(5),
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    gradient: LinearGradient(
                      begin: Alignment(-0.37857140550652835, -1.9473685559777252),
                      end: Alignment(1.2428571464417884, 2.526316110739735),
                      stops: [0.0, 0.856177031993866, 1.0],
                      colors: [
                        Pallet.colorWhite,
                        Pallet.colorSecondary,
                        Pallet.colorSecondaryDark,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text('ENTER',
                      style: GoogleFonts.lato(
                          fontSize: 15.0,
                          color: Pallet.colorSecondaryDark,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
