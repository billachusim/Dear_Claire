import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/Admob/ad_state.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/chats/widget/sub_diaryroom_widget.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
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
    // --- SHOW THE AD WHEN THE USER LEAVES THE SCREEN ---
    _showNewChatInterstitialAd();
    // The interstitial ad will be disposed inside the _showNewChatInterstitialAd callbacks,
    // so we don't need to call _interstitialAd?.dispose() here anymore.
    super.dispose();
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
// We only need one banner for this screen now.
  BannerAd? insideChatroomBottomBanner; // Make it nullable
  bool _isBannerAdInitialized = false; // Add this flag

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if ad is already initialized to avoid re-loading.
    if (!_isBannerAdInitialized) {
      final adState = Provider.of<AdState>(context);
      adState.initialization.then((status) {
        setState(() {
          insideChatroomBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.insideChatroomBottomBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (ad) => print('Banner ad loaded for chatroom.'),
              onAdFailedToLoad: (ad, error) {
                print('Banner ad failed to load for chatroom: $error');
                ad.dispose();
              },
            ),
          )..load();
          _isBannerAdInitialized = true;
        });
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor.fromHex(chatRoomPodo!.hex!),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(chatRoomPodo!.hex!),
        title: Text(chatRoomPodo!.title!),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // This ListView now contains only chat-related content
            ListView(
              children: [
                AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                    itemCount: 1,
                    itemBuilder: (BuildContext c, int i) {
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        delay: Duration(milliseconds: 500),
                        child: SlideAnimation(
                          //... (rest of your animation code)
                          child: FlipAnimation(
                            //... (rest of your animation code)
                            child: StreamBuilder(
                              stream: firebaseServices.getChats(chatRoomPodo),
                                //...
                                builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapShot) {
                                  if (snapShot.hasError) {
                                    return Center(child: Text("Something went wrong"));
                                  }
                                  if (snapShot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }

                                  if (snapShot.hasData) {
                                    // --- THIS IS THE CRITICAL FIX ---
                                    // Clear the list to prevent duplicates on each rebuild
                                    _chatList.clear();
                                    // Process the snapshot and populate the _chatList
                                    snapShot.data!.docs.map((e) {
                                      _chatList.add(Temp(e.id, ChatModel.fromJson(e.data())));
                                    }).toList();
                                    // --- END OF FIX ---

                                    return Column(
                                      children: [
                                        SubDiaryRoomWidget(element: widget.chatRoomPodo),
                                        ..._chatList.map((element) => ChatWidget(
                                          documentID: element.id,
                                          chatModel: element.chatModel,
                                          chatRoomPodo: chatRoomPodo,
                                        )).toList(),
                                      ],
                                    );
                                  }
                                  // Fallback for no data
                                  return Center(
                                    child: Text("No messages yet."),
                                  );
                                },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Adjust SizedBox to account for both the chat field and the banner
                SizedBox(height: 120),
              ],
            ),
            // Your existing chat input field
            ChatEditField(
              onTap: (v, voiceNote, image1, image2) => _sendMessage(v, voiceNote, image1, image2),
            ),
            // --- COMPLIANT BANNER AD PLACEMENT ---
            // Positioned at the bottom, above the navigation bar but below the ChatEditField
            if (insideChatroomBottomBanner != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: insideChatroomBottomBanner!.size.height.toDouble(),
                  width: insideChatroomBottomBanner!.size.width.toDouble(),
                  child: AdWidget(ad: insideChatroomBottomBanner!),
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
  }
}
