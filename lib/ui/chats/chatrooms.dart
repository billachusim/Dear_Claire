import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/widget/chat_room_widget.dart';
import 'package:flutter/material.dart';

import '../../widgets/toast.dart';
import '../routes/routes.dart';
import 'data/roomdata.dart';
import 'inside_chatroom.dart';

class ChatRoomsPage extends StatefulWidget {
  final String title;
  const ChatRoomsPage({Key? key, required this.title}) : super(key: key);

  @override
  _ChatRoomsPageState createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink();
    });
  }

  void _handleDeepLink() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['roomId'] != null) {
      final String roomId = args['roomId'];

      final List<ChatRoomPodo> rooms = RoomData.room();
      final int roomIndex = rooms.indexWhere((room) => room.id.toString() == roomId);

      if (roomIndex != -1) {
        final ChatRoomPodo targetRoom = rooms[roomIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomPodo: targetRoom,
              cornerId: args['cornerId'],
            ),
          ),
        );
      }
    }
  }

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
