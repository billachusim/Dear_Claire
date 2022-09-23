import 'package:dear_claire/ui/chats/widget/chat_room_widget.dart';
import 'package:flutter/material.dart';

import '../../widgets/toast.dart';
import '../routes/routes.dart';
import 'data/roomdata.dart';

class ChatRoomsPage extends StatelessWidget {
  final String title;
  const ChatRoomsPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          showToast("Press back again to exit.");
          return Future.value(false);
        },
        child: Scaffold(
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