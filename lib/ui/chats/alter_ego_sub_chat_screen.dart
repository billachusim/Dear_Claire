import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/chats/widget/inside_inside_alter_ego_rooms.dart';
import 'package:dear_claire/ui/chats/widget/inside_inside_inside_alter_ego_rooms.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../services/firebase_services.dart';

class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class AlterEgoSubChatScreen extends StatefulWidget {
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;
  String? documentID;

  AlterEgoSubChatScreen(
      {Key? key,
        required this.documentID,
        required this.chatRoomPodo,
        required this.chatModel})
      : super(key: key);

  @override
  _AlterEgoSubChatScreenState createState() => _AlterEgoSubChatScreenState();
}

const int maxFailedLoadAttempts = 3;


class _AlterEgoSubChatScreenState extends State<AlterEgoSubChatScreen> {

  List<Temp> _chatList = [];

  User? currentUser = FirebaseAuth.instance.currentUser;



  @override
  void initState() {
    super.initState();
    _createSubChatInterstitialAd();
  }



  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }


  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  /// Create new sub chat interstitial ad.

  void _createSubChatInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/9839548530" :
      Platform.isIOS? "ca-app-pub-2404156870680632/8291211887" :
      '',      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createSubChatInterstitialAd();
          }
        },
      ),
    );
  }



  // Admob Ad Units.
  late BannerAd insideInsideChatroomTopBanner;
  late BannerAd insideInsideChatroomBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        insideInsideChatroomTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.insideInsideChatroomTopBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener()
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        insideInsideChatroomBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.insideInsideChatroomBottomBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener()
        )..load();
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
        title: Text(widget.chatModel!.message ?? 'Diary Room'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              children: [


                AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
                    //padding: EdgeInsets.all(15),
                    physics:
                    BouncingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                    itemCount: 1,
                    itemBuilder: (BuildContext c, int i) {
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        delay: Duration(milliseconds: 500),
                        child: SlideAnimation(
                          duration: Duration(milliseconds: 2500),
                          curve: Curves.fastLinearToSlowEaseIn,
                          horizontalOffset: 30,
                          verticalOffset: 300.0,
                          child: FlipAnimation(
                            duration: Duration(milliseconds: 3000),
                            curve: Curves.fastLinearToSlowEaseIn,
                            flipAxis: FlipAxis.y,

                            child: StreamBuilder(
                                stream: firebaseServices.getAlterEgoSubMessages(
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
                                        InsideInsideAlterEgoChatWidget(documentID: widget.documentID, chatModel: widget.chatModel, chatRoomPodo: widget.chatRoomPodo),

                                        // Top ad unit is here
                                        Container(
                                          height: 60,
                                          child: AdWidget(ad: insideInsideChatroomTopBanner),
                                        ),


                                        ..._chatList
                                            .map((element) => InsideInsideInsideAlterEgoChatWidget(
                                          isSubChat: true,
                                          documentID: element.id,
                                          chatModel: element.chatModel,
                                          chatRoomPodo: widget.chatRoomPodo,
                                        ))
                                            .toList(),

                                        // Bottom ad unit is here
                                        Container(
                                          height: 60,
                                          child: AdWidget(ad: insideInsideChatroomBottomBanner),
                                        ),
                                      ],
                                    );
                                  }
                                  return Container();
                                }),
                          ),
                        ),
                      );
                    },
                  ),
                ),


                SizedBox(
                  height: 70,
                )
              ],
            ),
            ChatEditField(onTap: (v, voiceNote, image1, image2) => _sendMessage(v, voiceNote, image1, image2))
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v, String voiceNote, String image1, String image2) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addAlterEgoSubMessage(
        widget.documentID!,
        widget.chatRoomPodo!,
        ChatModel(
            message: v,
            userId: _user.userId,
            timeCreated: Timestamp.now(),
            audioUrl: voiceNote,
            image1: image1,
            image2: image2,
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
    firebaseServices.updateAlterEgoMembers(widget.documentID!, widget.chatRoomPodo, widget.chatModel!);
  }


  /// Update a session's timeLastActivity when new chat is made.

  Future<void> updateDiaryroomTimeLastActivity(String key, ChatRoomPodo chatRoomPodo) async {
    FirebaseFirestore.instance
        .collection("alterEgoChats")
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key)
        .update({
      'timeLastActivity': FieldValue.serverTimestamp(),
    },
    );
    logger.d('Successfully updated time of last activity');
  }


}
