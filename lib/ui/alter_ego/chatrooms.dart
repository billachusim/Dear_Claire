import 'package:flutter/material.dart';

import '../routes/routes.dart';

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
          body: Container(

          ),
        ),
      ),
    );
  }
}