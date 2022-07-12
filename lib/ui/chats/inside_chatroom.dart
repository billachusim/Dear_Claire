import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/Admob/ad_state.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/chats/widget/sub_diaryroom_widget.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../utils/color.dart';
import 'widget/chat_widget.dart';

class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class ChatScreen extends StatefulWidget {
  ChatRoomPodo chatRoomPodo;

  ChatScreen({Key? key, required this.chatRoomPodo}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(chatRoomPodo);
}

const int maxFailedLoadAttempts = 3;


class _ChatScreenState extends State<ChatScreen> {
  ChatRoomPodo? chatRoomPodo;

  _ChatScreenState(this.chatRoomPodo);

  List<Temp> _chatList = [];

  @override
  void initState() {
    super.initState();
    _createNewChatInterstitialAd();
  }



  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }


  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  // Create interstitial ad.

  void _createNewChatInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/9695244155" :
      Platform.isIOS? "ca-app-pub-2404156870680632/6685937430" :
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
            _createNewChatInterstitialAd();
          }
        },
      ),
    );
  }

  void _showNewChatInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createNewChatInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createNewChatInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }


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
      backgroundColor: Pallet.colorSecondaryDark,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(chatRoomPodo!.hex!),
        title: Text(chatRoomPodo!.title!),
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
                                        SubDiaryRoomWidget(element: widget.chatRoomPodo),

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
            ChatEditField(
              onTap: (v, voiceNote, image1, image2) => _sendMessage(v, voiceNote, image1, image2),
            )
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v, voiceNote, String image1, String image2) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addMessage(
        chatRoomPodo!,
        ChatModel(
            message: v,
            colorHex: chatRoomPodo!.hex,
            userId: _user.userId,
            timeCreated: Timestamp.now(),
            audioUrl: voiceNote,
            image1: image1,
            image2: image2,
            members: [_user.userId]));
    Future.delayed(Duration(seconds: 4), () {
      _showNewChatInterstitialAd();
    });
  }
}
