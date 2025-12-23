import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/chats/widget/inside_inside_alter_ego_rooms.dart';
import 'package:clairediary/ui/chats/widget/inside_inside_inside_alter_ego_rooms.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../helpers/toast_helper.dart';
import '../../services/firebase_services.dart';
import '../../services/notification_service.dart';
import '../../utils/strings.dart';

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

  // --- ADMOB COMPLIANCE FIX 1: Add new ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  bool _isSending = false;


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
    // --- LOGIC FOR HIDING CHAT FIELD (REPLICATED FOR ALTER EGO) ---
    // 1. Check if this is the special "Eavesdrop" room.
    final bool isEavesdropRoom =
        widget.chatRoomPodo?.title == "One On One Eavedrop With ClAIre";

    // 2. Check if the current user is the owner of this Alter Ego corner.
    final bool isCornerOwner = currentUser?.uid == widget.chatModel?.userId;

    // 3. The user can send messages if it's NOT an eavesdrop room, OR if they ARE the corner owner.
    final bool canSendMessage = !isEavesdropRoom || isCornerOwner;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                                    widget.documentID!, widget.chatRoomPodo,
                                    widget.chatModel!),
                                builder: (context,
                                    AsyncSnapshot<
                                        QuerySnapshot<Map<String, dynamic>>>
                                    snapShot) {
                                  if (snapShot.hasData) {
                                    _chatList
                                        .clear(); // Clear list before populating
                                    snapShot.data!.docs
                                        .map((e) =>
                                        _chatList
                                            .add(Temp(e.id, ChatModel.fromJson(
                                            e.data() as Map<String, dynamic>))))
                                        .toList();
                                    return Column(
                                      children: [
                                        InsideInsideAlterEgoChatWidget(
                                            documentID: widget.documentID,
                                            chatModel: widget.chatModel,
                                            chatRoomPodo: widget.chatRoomPodo),
                                        ..._chatList
                                            .map((element) =>
                                            InsideInsideInsideAlterEgoChatWidget(
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

            // --- BANNER AD PLACEMENT ---
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

            // --- MODIFICATION: Conditionally display the chat field ---
            if (canSendMessage)
              Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ChatEditField(
                      onTap: (v, voiceNote, image1, image2) =>
                          _sendMessage(v, voiceNote, image1, image2),
                    ),
                  ),
                  // The overlay that shows only when sending
                  if (_isSending)
                    Positioned.fill(
                      child: Container(
                        color:Colors.black.withOpacity(0.5), // Semi-transparent overlay
                        child: Center(
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
      updateDiaryroomTimeLastActivity(widget.documentID!, widget.chatRoomPodo!);

      await firebaseServices.saveUserActivity(
        activityType: 'room_join',
        activityMessage: "You messaged a corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}'.",
        sessionId: widget.chatRoomPodo?.id.toString(),
      );

      // --- NOTIFY ALL MEMBERS IN THE ALTER EGO CORNER ---
      final visitorNickname = _user.alterEgoId;
      final title = "New Message in ${widget.chatModel?.message ?? 'an Alter Ego Corner'}!";
      final body = "${visitorNickname ?? 'An Alter Ego'} dropped a message in a corner you're in.";
      final routeData = {
        'route': 'alterEgoDiaryRooms',
        'roomId': widget.chatRoomPodo!.id.toString(),
        'cornerId': widget.documentID,
      };

      // Use a Set to gather unique member IDs
      final memberIds = widget.chatModel?.members?.toSet() ?? {};
      // Also include the corner owner if they are not already in members list
      if (widget.chatModel?.userId != null) {
        memberIds.add(widget.chatModel!.userId!);
      }

      for (String memberId in memberIds) {
        // Don't send a notification to the user who sent the message
        if (memberId == _user.userId) continue;

        try {
          final member = await firebaseServices.getUserWithId(id: memberId);
          final fcmId = member.fcmId;
          if (fcmId != null && fcmId.isNotEmpty) {
            await notificationService.sendNotification({
              "token": fcmId,
              "notification": {"title": title, "body": body},
              "data": routeData,
            });
          }
        } catch (e) {
          print("Error sending notification to member $memberId: $e");
        }
      }
      showToast(message: 'Message Sent. Remember, positive vibes only.');

    } catch (e) {
      // Handle any potential errors
      print("Error sending message in Alter Ego corner: $e");
      showToast(message: "Failed to send message. Please try again.");
    } finally {
      // --- HIDE LOADER (GUARANTEED) ---
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Update a session's timeLastActivity when new comment is made.
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
    logger.d('Successfully updated time of last activity for Alter Ego');
  }
}
