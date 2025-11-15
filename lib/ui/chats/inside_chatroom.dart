import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:flutter/material.dart';

import '../splash_screen/custom_rotate_bacground.dart';
import 'widget/chat_widget.dart';

class Temp {
  final String id;
  final ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class ChatScreen extends StatefulWidget {
  final ChatRoomPodo? chatRoomPodo;

  const ChatScreen({super.key, required this.chatRoomPodo});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Temp> _chatList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.chatRoomPodo!.hex!),
        title: Text(widget.chatRoomPodo!.title!),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
            ListView(
              children: [
                StreamBuilder(
                  stream: firebaseServices.getChats(widget.chatRoomPodo),
                  builder: (context,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapShot) {
                    if (snapShot.hasData) {
                      _chatList = snapShot.data!.docs
                          .map((e) => Temp(e.id, ChatModel.fromJson(e.data())))
                          .toList();

                      return Column(
                        children: _chatList
                            .map((element) => ChatWidget(
                                  documentID: element.id,
                                  chatModel: element.chatModel,
                                  chatRoomPodo: widget.chatRoomPodo,
                                ))
                            .toList(),
                      );
                    }
                    return Container();
                  },
                ),
                const SizedBox(
                  height: 70,
                )
              ],
            ),
            ChatEditField(
              onTap: _sendMessage,
            )
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addMessage(
      widget.chatRoomPodo!,
      ChatModel(
        message: v,
        colorHex: widget.chatRoomPodo!.hex,
        userId: _user.userId,
        timeCreated: Timestamp.now(),
        members: [_user.userId!],
      ),
    );
  }
}
