import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/Admob/ad_state.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../../utils/color.dart';
import 'alter_ego_chat_widget.dart';
import 'alter_ego_sub_room_widget.dart';

class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class AlterEgoChatScreen extends StatefulWidget {
  ChatRoomPodo chatRoomPodo;

  AlterEgoChatScreen({Key? key, required this.chatRoomPodo}) : super(key: key);

  @override
  _AlterEgoChatScreenState createState() => _AlterEgoChatScreenState(chatRoomPodo);
}

const int maxFailedLoadAttempts = 3;


class _AlterEgoChatScreenState extends State<AlterEgoChatScreen> {
  ChatRoomPodo? chatRoomPodo;

  _AlterEgoChatScreenState(this.chatRoomPodo);

  List<Temp> _chatList = [];

  // --- ADMOB COMPLIANCE FIX 1: Add new ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;


  @override
  void initState() {
    super.initState();
    _createNewChatInterstitialAd();
  }



  @override
  void dispose() {
    // --- ADMOB COMPLIANCE FIX 2: Show interstitial on exit and dispose all ads ---
    _showNewChatInterstitialAd();
    _interstitialAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }


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
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; // Prevent showing the same ad twice
    }
  }


  // --- ADMOB COMPLIANCE FIX 3: Clean up banner ad loading logic ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerAdInitialized) {
      final adState = Provider.of<AdState>(context);
      adState.initialization.then((status) {
        if (mounted) {
          setState(() {
            _bottomBannerAd = BannerAd(
                size: AdSize.banner,
                // Using a unique ad unit ID for this page
                adUnitId: adState.insideChatroomBottomBannerAdUnitId,
                request: AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) => print('Alter Ego chat banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print('Alter Ego chat banner failed to load: $error');
                    ad.dispose();
                  },
                )
            )..load();
            _isBannerAdInitialized = true;
          });
        }
      });
    }
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
        // --- ADMOB COMPLIANCE FIX 4: Ensure body is a Stack ---
        child: Stack(
          children: [
            ListView(
              children: [
                AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
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
                                stream: firebaseServices.getAlterEgoChats(chatRoomPodo),
                                builder: (context,
                                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                                    snapShot) {
                                  if (snapShot.hasData) {
                                    _chatList.clear(); // Clear list before populating
                                    snapShot.data!.docs
                                        .map((e) => _chatList
                                        .add(Temp(e.id, ChatModel.fromJson(e.data()))))
                                        .toList();
                                    // --- ADMOB COMPLIANCE FIX 5: Remove ads from Column ---
                                    return Column(
                                      children: [
                                        AlterEgoSubDiaryRoomWidget(element: widget.chatRoomPodo),
                                        // Top ad unit REMOVED
                                        ..._chatList
                                            .map((element) => AlterEgoChatWidget(
                                          documentID: element.id,
                                          chatModel: element.chatModel,
                                          chatRoomPodo: chatRoomPodo,
                                        ))
                                            .toList(),
                                        // Bottom ad unit REMOVED
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
                // Adjust space for the input field AND the banner ad
                SizedBox(height: 120),
              ],
            ),
            // Your existing chat input field
            ChatEditField(
              onTap: (v, voiceNote, image1, image2) => _sendMessage(v, voiceNote, image1, image2),
            ),
            // --- ADMOB COMPLIANCE FIX 6: Place a single, compliant banner ad ---
            if (_bottomBannerAd != null && _isBannerAdInitialized)
              Positioned(
                bottom: 60, // Position above the ChatEditField
                left: 0,
                right: 0,
                child: Container(
                  height: _bottomBannerAd!.size.height.toDouble(),
                  width: _bottomBannerAd!.size.width.toDouble(),
                  child: AdWidget(ad: _bottomBannerAd!),
                  alignment: Alignment.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String v, voiceNote, String image1, String image2) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addAlterEgoMessage(
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
    // --- ADMOB COMPLIANCE FIX 7: Remove interstitial ad call from here ---
  }
}
