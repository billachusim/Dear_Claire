import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () async {
        UserModel user = await firebaseServices.getUserInfo();
        if (widget.element.title != "Band Of Super Egos") {
          PageRouter.gotoWidget(
              AlterEgoChatScreen(chatRoomPodo: widget.element), context);
        }
         else if (user.userType == "SUPER_ADMIN") {
          PageRouter.gotoWidget(
              AlterEgoChatScreen(chatRoomPodo: widget.element), context);
          }
        else {
          showToast("You have to be super ego first");
          }
      },
      padding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: HexColor.fromHex(widget.element.hex!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

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
                        child: Text('O P E N',
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
