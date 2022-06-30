import 'package:dear_claire/ui/chats/widget/chat_room_widget.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/helper.dart';
import '../routes/routes.dart';
import '../splash_screen/custom_rotate_bacground.dart';
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
          showToast("Press back again to exit.");
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: Pallet.colorSecondaryDark,
          body: Stack(
            children: [

              ListView(
              children: RoomData.room().map((room) => ChatRoomWidget(element: room)).toList(),
            ),
        ]
          ),
        ),
      ),
    );
  }
}