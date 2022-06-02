import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/chats/widget/inside_inside_diaryrooms.dart';
import 'package:dear_claire/ui/chats/widget/inside_inside_inside_diaryroom.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_services.dart';
import '../../services/user_model.dart';
import '../../widgets/toast.dart';
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

  User? currentUser = FirebaseAuth.instance.currentUser;
  UserModel? _visitingUser = UserModel();

  @override
  void initState() {
    //updateMembers(joining: true);
    super.initState();
  }

  @override
  void dispose() {
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
    updateDiaryroomTimeLastActivity(_user.userId.toString(), widget.chatRoomPodo!);
  }

  void updateMembers({required bool joining}) async {
    final userID = currentUser!.uid.toString();
    if (joining) {
      widget.chatModel!.members!.add(userID);
    }
    if (!joining) {
      widget.chatModel!.members!.remove(userID);
    }
    firebaseServices.updateMembers(widget.documentID!, widget.chatRoomPodo, widget.chatModel!);
  }


  /// Update a session's timeLastActivity when new comment is made.

  Future<void> updateDiaryroomTimeLastActivity(String key, ChatRoomPodo chatRoomPodo) async {
    FirebaseFirestore.instance
        .collection(AppString.appChats)
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key)
        .update({
      'timeLastActivity': FieldValue.serverTimestamp(),
    },
    );
    logger.d('Successfully updated time of last activity');
  }

  /// Get Visiting Ego User info
  Future<UserModel> getVisitingUserInfo() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(currentUser?.uid)
        .get();

    var visitingUser = UserModel.fromFirestore(response.data() as Map<String, dynamic>);
    _visitingUser = visitingUser;
    logger.d('Successfully got the visiting user model');
    return visitingUser;
  }


}
