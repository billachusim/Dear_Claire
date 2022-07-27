import 'package:flutter/material.dart';

import '../../utils/helper.dart';
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