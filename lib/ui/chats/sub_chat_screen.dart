import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/chats/widget/inside_inside_diaryrooms.dart';
import 'package:clairediary/ui/chats/widget/inside_inside_inside_diaryroom.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
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

const int maxFailedLoadAttempts = 3;


class _SubChatScreenState extends State<SubChatScreen> {

  List<Temp> _chatList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;

  // --- ADMOB COMPLIANCE FIX 1: Add new ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;


  @override
  void initState() {
    super.initState();
    _createSubChatInterstitialAd();
  }



  @override
  void dispose() {
    // --- ADMOB COMPLIANCE FIX 2: Show interstitial on exit and dispose all ads ---
    _showSubChatInterstitialAd();
    _interstitialAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }


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

  // --- ADMOB COMPLIANCE FIX 3: Add the show interstitial method ---
  void _showSubChatInterstitialAd() {
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


  // --- ADMOB COMPLIANCE FIX 4: Clean up banner ad loading logic ---
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
                adUnitId: adState.insideInsideChatroomBottomBannerAdUnitId,
                request: AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) => print('Sub-chat banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print('Sub-chat banner failed to load: $error');
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
      backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
        title: Text(widget.chatModel!.message ?? 'Diary Room'),
        elevation: 0,
      ),
      body: SafeArea(
        // --- ADMOB COMPLIANCE FIX 5: Ensure body is a Stack ---
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
                                stream: firebaseServices.getSubMessages(
                                    widget.documentID!, widget.chatRoomPodo, widget.chatModel!),
                                builder: (context,
                                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                                    snapShot) {
                                  if (snapShot.hasData) {
                                    _chatList.clear(); // Clear list before populating
                                    snapShot.data!.docs
                                        .map((e) => _chatList
                                        .add(Temp(e.id, ChatModel.fromJson(e.data() as Map<String, dynamic>))))
                                        .toList();
                                    // --- ADMOB COMPLIANCE FIX 6: Remove ads from Column ---
                                    return Column(
                                      children: [
                                        InsideInsideChatWidget(documentID: widget.documentID, chatModel: widget.chatModel, chatRoomPodo: widget.chatRoomPodo),
                                        // Top ad unit REMOVED
                                        ..._chatList
                                            .map((element) => InsideInsideInsideChatWidget(
                                          isSubChat: true,
                                          documentID: element.id,
                                          chatModel: element.chatModel,
                                          chatRoomPodo: widget.chatRoomPodo,
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
            ChatEditField(onTap: (v, voiceNote, image1, image2) => _sendMessage(v, voiceNote, image1, image2)),
            // --- ADMOB COMPLIANCE FIX 7: Place a single, compliant banner ad ---
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

  void _sendMessage(String v, String voiceNote, String image1, String image2) async {
    final _user = await firebaseServices.getUserInfo();
    firebaseServices.addSubMessage(
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
}
