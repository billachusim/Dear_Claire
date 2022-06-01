import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/chats/widget/inside_inside_diaryrooms.dart';
import 'package:dear_claire/ui/chats/widget/inside_inside_inside_diaryroom.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widget/chat_widget.dart';

class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class SubChatScreen extends StatefulWidget {
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;
  String? documentID;

  SubChatScreen(
      {Key? key,
      required this.documentID,
      required this.chatRoomPodo,
      required this.chatModel})
      : super(key: key);

  @override
  _SubChatScreenState createState() => _SubChatScreenState();
}

class _SubChatScreenState extends State<SubChatScreen> {

  List<Temp> _chatList = [];

  @override
  void initState() {
    updateMembers(joining: true);
    super.initState();
  }

  @override
  void dispose() {
    updateMembers(joining: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
        title: Text(widget.chatModel!.message ?? ''),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Image.asset(
              AppImages.appChatBg,
              height: getDeviceHeight(context),
              width: getDeviceWidth(context),
              fit: BoxFit.cover,
            ),
            ListView(
              children: [
                StreamBuilder(
                    stream: firebaseServices.getSubMessages(
                        widget.documentID!, widget.chatRoomPodo, widget.chatModel!),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            snapShot) {
                      if (snapShot.hasData) {
                        if (_chatList.isNotEmpty) _chatList.clear();
                      snapShot.data!.docs
                          .map((e) => _chatList
                          .add(Temp(e.id, ChatModel.fromJson(e.data()))))
                          .toList();
                        return Column(
                          children: [
                            InsideInsideChatWidget(documentID: widget.documentID, chatModel: widget.chatModel, chatRoomPodo: widget.chatRoomPodo),

                            ..._chatList
                                .map((element) => InsideInsideInsideChatWidget(
                                      isSubChat: true,
                                      documentID: element.id,
                                      chatModel: element.chatModel,
                                      chatRoomPodo: widget.chatRoomPodo,
                                    ))
                                .toList(),
                          ],
                        );
                      }
                      return Container();
                    }),
                SizedBox(
                  height: 70,
                )
              ],
            ),
            ChatEditField(onTap: (v, voiceNote) => _sendMessage(v, voiceNote))
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v, String voiceNote) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addSubMessage(
        widget.documentID!,
        widget.chatRoomPodo!,
        ChatModel(
            message: v,
            userId: _user.userId,
            timeCreated: Timestamp.now(),
            members: [_user.userId]));
  }

  void updateMembers({required bool joining}) async {
    final userID = firebaseServices.getUsersId();
    if (joining) {
      widget.chatModel!.members!.add(userID);
    }
    if (!joining) {
      widget.chatModel!.members!.remove(userID);
    }
    firebaseServices.updateMembers(widget.documentID!, widget.chatRoomPodo, widget.chatModel!);
  }
}
