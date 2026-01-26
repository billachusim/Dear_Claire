import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/Admob/ad_state.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/chats/widget/sub_diaryroom_widget.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../helpers/toast_helper.dart';
import '../../services/notification_service.dart';
import 'widget/chat_widget.dart';

class Temp {
  String id;
  ChatModel chatModel;
  Temp(this.id, this.chatModel);
}

class ChatScreen extends StatefulWidget {
  ChatRoomPodo chatRoomPodo;
  final String? cornerId;
  ChatScreen({
    Key? key,
    required this.chatRoomPodo,
    this.cornerId,
  }) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState(chatRoomPodo);
}

const int maxFailedLoadAttempts = 3;


class _ChatScreenState extends State<ChatScreen> {
  ChatRoomPodo? chatRoomPodo;
  User? currentUser = FirebaseAuth.instance.currentUser;

  _ChatScreenState(this.chatRoomPodo);
  bool _isSending = false;
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
      resizeToAvoidBottomInset: true,
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
                    physics: BouncingScrollPhysics(
                        parent: NeverScrollableScrollPhysics()),
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
                              builder: (context, AsyncSnapshot<
                                  QuerySnapshot<Map<String, dynamic>>> snapShot) {
                                if (snapShot.hasError) {
                                  return Center(
                                      child: Text("Something went wrong"));
                                }
                                if (snapShot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                if (snapShot.hasData) {
                                  // --- THIS IS THE CRITICAL FIX ---
                                  // Clear the list to prevent duplicates on each rebuild
                                  _chatList.clear();
                                  // Process the snapshot and populate the _chatList
                                  snapShot.data!.docs.map((e) {
                                    _chatList.add(
                                        Temp(e.id, ChatModel.fromJson(e.data())));
                                  }).toList();
                                  // --- END OF FIX ---

                                  return Column(
                                    children: [
                                      SubDiaryRoomWidget(
                                          element: widget.chatRoomPodo),
                                      ..._chatList.map((element) =>
                                          ChatWidget(
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

            // --- BANNER AD PLACEMENT ---
            // Positioned above the ChatEditField
            if (insideChatroomBottomBanner != null && _isBannerAdInitialized)
              Positioned(
                bottom: 60, // Position it 60 pixels from the bottom.
                left: 0,
                right: 0,
                child: Container(
                  height: insideChatroomBottomBanner!.size.height.toDouble(),
                  width: insideChatroomBottomBanner!.size.width.toDouble(),
                  child: AdWidget(ad: insideChatroomBottomBanner!),
                  alignment: Alignment.center,
                ),
              ),

            // --- CHAT INPUT FIELD ---
            Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ChatEditField(
                    // This is a chat room, so commenting is always open for everyone.
                    canComment: true,onTap: (v, voiceNote, image1, image2) =>
                      _sendMessage(v, voiceNote, image1, image2),
                  ),
                ),
                // The overlay that shows only when sending
                if (_isSending)
                  Positioned.fill(
                    child: Container(
                      color:Colors.black.withValues(alpha: 0.5), // Semi-transparent overlay
                      child: const Center(
                        child: CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _sendMessage(String v, String voiceNote, String image1, String image2) async {
    // --- Prevent sending if already processing or if content is empty ---
    if (_isSending || (v.isEmpty && voiceNote.isEmpty && image1.isEmpty && image2.isEmpty)) {
      return;
    }

    // --- Show loader ---
    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      final _user = await firebaseServices.getUserWithId(id: currentUser!.uid);

      firebaseServices.addMessage(
          widget.chatRoomPodo,
          ChatModel(
            message: v,
            colorHex: widget.chatRoomPodo.hex,
            userId: _user.userId,
            userNickname: _user.nickname,
            userAvatarUrl: _user.avatarUrl,
            timeLastActivity: Timestamp.now(),
            audioUrl: voiceNote,
            image1: image1,
            image2: image2,
            members: [_user.userId],
            userType: _user.userType,
            alterEgoId: _user.alterEgoId,
          )
      );

      await firebaseServices.saveUserActivity(
        activityType: 'room_join',
        activityMessage: "You started your own corner inside ${chatRoomPodo!.title ?? 'Chatrooms'}'.",
        sessionId: chatRoomPodo!.id.toString(),
      );

      await notificationService.sendNotification({
        "token": _user.fcmId,
        "notification": {
          "title": "You started your own corner!",
          "body": "Darlings will join your corner soon. Behave.",
        },
        "data": {
          'route': 'diaryRooms',
          'roomId': widget.chatRoomPodo.id,
        },
      });

    } catch (e) {
      // Handle any potential errors
      print("Error creating Ego corner: $e");
      showToast(message: "Failed to start corner. Please try again.");
    } finally {
      // --- HIDE LOADER (GUARANTEED) ---
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }



}
