
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/constant.dart';
import '../data/chatroompodo.dart';
import '../data/chats.dart';
import 'alter_ego_online_room_owner_widget.dart';


class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}


/// This is a stream class showing room owners in a diary room.


class AlterEgoOnlineRoomVisitorsStream extends StatefulWidget {
  ChatRoomPodo roomData;
  ChatModel roomModel;
  String docId;

  AlterEgoOnlineRoomVisitorsStream({Key? key, required this.roomData, required this.roomModel, required this.docId}) : super(key: key);

  @override
  State<AlterEgoOnlineRoomVisitorsStream> createState() => _AlterEgoOnlineRoomVisitorsStreamState(roomData);
}

class _AlterEgoOnlineRoomVisitorsStreamState extends State<AlterEgoOnlineRoomVisitorsStream> {
  ChatRoomPodo? chatRoomPodo;
  _AlterEgoOnlineRoomVisitorsStreamState(this.chatRoomPodo);

  List<Temp> _chatList = [];

  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
                stream: firebaseServices.getAlterEgoSubMessages(
                    widget.docId, widget.roomData, widget.roomModel),
                builder: (context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                    snapShot) {
                  if (snapShot.hasData) {
                    if (_chatList.isNotEmpty) _chatList.clear();
                    snapShot.data!.docs
                        .map((e) => _chatList
                        .add(Temp(e.id, ChatModel.fromJson(e.data()))))
                        .toList();
                    return Scrollbar(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._chatList
                                .map((element) => AlterEgoOnlineRoomOwnerWidget(
                              roomData: widget.roomData,
                              chatModel: element.chatModel,
                            ))
                                .toList(),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container();
                }),
          ),
        ],
      );
  }
}
