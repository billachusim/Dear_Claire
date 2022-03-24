import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widget/chat_widget.dart';

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
  _SubChatScreenState createState() =>
      _SubChatScreenState(documentID, chatRoomPodo, chatModel);
}

class _SubChatScreenState extends State<SubChatScreen> {
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;
  String? documentID;

  _SubChatScreenState(this.documentID, this.chatRoomPodo, this.chatModel);

  List<ChatModel> _chatList = [];

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
        backgroundColor: HexColor.fromHex(chatModel!.colorHex!),
        title: Text(chatModel!.message ?? ''),
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
                        documentID!, chatRoomPodo, chatModel!),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            snapShot) {
                      if (snapShot.hasData) {
                        if (_chatList.isNotEmpty) _chatList.clear();
                        snapShot.data!.docs
                            .map((e) =>
                                _chatList.add(ChatModel.fromJson(e.data())))
                            .toList();
                        return Column(
                          children: [
                            ..._chatList
                                .map((element) => ChatWidget(
                                      isSubChat: true,
                                      documentID: '',
                                      chatModel: element,
                                      chatRoomPodo: chatRoomPodo,
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
            ChatEditField(onTap: (v) => _sendMessage(v))
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addSubMessage(
        documentID!,
        chatRoomPodo!,
        ChatModel(
            message: v,
            userId: _user.userId,
            timeCreated: Timestamp.now(),
            members: [_user.userId]));
  }

  void updateMembers({required bool joining}) async {
    final userID = firebaseServices.getUsersId();
    if (joining) {
      chatModel!.members!.add(userID);
    }
    if (!joining) {
      chatModel!.members!.remove(userID);
    }
    firebaseServices.updateMembers(documentID!, chatRoomPodo, chatModel!);
  }
}
