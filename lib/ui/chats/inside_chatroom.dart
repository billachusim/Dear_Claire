import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/Admob/ad_state.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/dairy/diary_details_widget.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/featured/model/featured_session_model.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/widgets/comment_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../splash_screen/custom_rotate_bacground.dart';
import '../splash_screen/rotate_logo.dart';
import 'widget/chat_widget.dart';

class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class ChatScreen extends StatefulWidget {
  ChatRoomPodo? chatRoomPodo;

  ChatScreen({Key? key, required this.chatRoomPodo}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(chatRoomPodo);
}

class _ChatScreenState extends State<ChatScreen> {
  ChatRoomPodo? chatRoomPodo;

  _ChatScreenState(this.chatRoomPodo);

  List<Temp> _chatList = [];

  // Admob Ad Units.
  late BannerAd insideChatroomTopBanner;
  late BannerAd insideChatroomBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        insideChatroomTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.insideChatroomTopBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener()
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        insideChatroomBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.insideChatroomBottomBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener()
        )..load();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(chatRoomPodo!.hex!),
        title: Text(chatRoomPodo!.title!),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
            ListView(
              children: [
                StreamBuilder(
                    stream: firebaseServices.getChats(chatRoomPodo),
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

                            // Top ad unit is here
                            if(insideChatroomTopBanner == null)
                              SizedBox(height: 70)
                            else
                              Container(
                                height: 60,
                                child: AdWidget(ad: insideChatroomTopBanner),
                              ),
                            ..._chatList
                                .map((element) => ChatWidget(
                                      documentID: element.id,
                                      chatModel: element.chatModel,
                                      chatRoomPodo: chatRoomPodo,
                                    ))
                                .toList(),

                            // Bottom ad unit is here
                            if(insideChatroomBottomBanner == null)
                              SizedBox(height: 70)
                            else
                              Container(
                                height: 60,
                                child: AdWidget(ad: insideChatroomBottomBanner),
                              ),
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
            ChatEditField(
              onTap: (v) => _sendMessage(v),
            )
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addMessage(
        chatRoomPodo!,
        ChatModel(
            message: v,
            colorHex: chatRoomPodo!.hex,
            userId: _user.userId,
            timeCreated: Timestamp.now(),
            members: [_user.userId]));
  }
}
