import 'package:dear_claire/ui/chats/widget/chat_room_widget.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/routes.dart';
import 'data/roomdata.dart';

class ChatRoomsPage extends StatelessWidget {
  const ChatRoomsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(

        onWillPop: (){
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.home);
          return Future.value(false);
        },
        child: Scaffold(
          body: ListView(
            children: RoomData.room().map((room) => ChatRoomWidget(element: room)).toList(),
          ),
        ),
      ),
    );
  }
}