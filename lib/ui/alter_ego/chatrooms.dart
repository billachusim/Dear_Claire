import 'package:clairediary/ui/chats/widget/inside_alter_ego_diaryroom.dart';
import 'package:flutter/material.dart';

import '../../utils/helper.dart';
import '../chats/data/chatroompodo.dart';
import '../chats/widget/alter_ego_diaryrooms_widget.dart';
import '../routes/routes.dart';
import '../splash_screen/custom_rotate_bacground.dart';
import 'alter_ego_room_data.dart';

class ChatRooms extends StatefulWidget {
  const ChatRooms({ Key? key }) : super(key: key);

  @override
  _ChatRoomsState createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<ChatRooms> {
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

      final List<ChatRoomPodo> rooms = AlterEgoRoomData.room();
      final int roomIndex = rooms.indexWhere((room) => room.id.toString() == roomId);

      if (roomIndex != -1) {
        final ChatRoomPodo targetRoom = rooms[roomIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlterEgoChatScreen(
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
        onWillPop: (){
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.alterEgoHomepage);
          return Future.value(false);
        },
        child: Scaffold(
          body: Stack(
              children:[
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
                ListView(
                  children: AlterEgoRoomData.room().map((room) => AlterEgoChatRoomWidget(element: room)).toList(),
                ),
              ]
          ),
        ),
      ),
    );
  }
}
