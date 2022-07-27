import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/constant.dart';
import 'alter_ego_room_online_users_stream.dart';

class AlterEgoSubDiaryRoomWidget extends StatelessWidget {
  ChatRoomPodo element;

  AlterEgoSubDiaryRoomWidget({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
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
                    Text('Anonymous  Diaryroom',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 16.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 3,
                    ),
                    Text('By Claire 🌺',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 14.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ),

              StreamBuilder(
                  stream: firebaseServices
                      .getAlterEgoChats(element),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                    if (snapShot.hasError) {
                      return Container();
                    }
                    if (snapShot.hasData) {
                      return Text(
                        snapShot.data!.docs.length.toString() + " Live Rooms 🔥",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600
                        ),
                      );
                    }
                    return Container();
                  }),

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

          SizedBox(height: 4,),

          AlterEgoOnlineRoomOwnersStream(roomData: element)
        ],
      ),
    );
  }
}
