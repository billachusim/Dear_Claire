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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../helpers/toast_helper.dart';
import '../../services/firebase_services.dart';
import '../../services/notification_service.dart';

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
  bool _isSending = false;
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
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    if (currentUser == null) return;

    try {
      final user = await firebaseServices.getUserWithId(id: currentUser!.uid);
      if (mounted) {
        setState(() {
        });
      }
    } catch (e) {
      debugPrint("Error checking admin status: $e");
    }
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
    // --- LOGIC FOR HIDING CHAT FIELD ---
    // 1. Check if this is the special "Eavesdrop" room.
    final bool isEavesdropRoom =
        widget.chatRoomPodo?.title == "Chat Or Eavesdrop Inside Claire's DM";

    // 2. Check if the current user is the owner of this corner.
    final bool isCornerOwner = currentUser?.uid == widget.chatModel?.userId;

    // The user can send messages if it's NOT an eavesdrop room,
    // OR if they ARE the corner owner,
    final bool canSendMessage = !isEavesdropRoom || isCornerOwner;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
        title: Text(widget.chatModel!.userNickname ?? 'Room Corner'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firebaseServices.getSubMessages(
                  widget.documentID!,
                  widget.chatRoomPodo,
                  widget.chatModel!),
              builder: (context, snapShot) {
                if (!snapShot.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                final docs = snapShot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 150), // Space for ads/input
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length + 1, // +1 for the header corner
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // The original corner message
                      return InsideInsideChatWidget(
                          documentID: widget.documentID,
                          chatModel: widget.chatModel,
                          chatRoomPodo: widget.chatRoomPodo);
                    }

                    // The replies
                    final doc = docs[index - 1];
                    final chatData = ChatModel.fromJson(doc.data());

                    return InsideInsideInsideChatWidget(
                      documentID: doc.id,
                      chatModel: chatData,
                      chatRoomPodo: widget.chatRoomPodo,
                    );
                  },
                );
              },
            ),

            // --- Banner Ads and Input Field remain in the Stack ---
            if (_bottomBannerAd != null && _isBannerAdInitialized)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: _bottomBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bottomBannerAd!),
                ),
              ),

            // Input Field
            Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) {
                  // This is a chat room or room corner.
                  // The`canSendMessage` variable already correctly determines if the user
                  // should be able to type (e.g., not in an eavesdrop room unless they are the owner).
                  // We pass its value directly to `canComment` to either show the text field or
                  // a disabled state (like SizedBox.shrink from your original code).
                  // Since this is a chat room, we don't need to check for 'alter' roles here.
                  return ChatEditField(
                    canComment: canSendMessage,
                    onTap: (v, voiceNote, image1, image2) {
                      if (canSendMessage) {
                        _sendMessage(v, voiceNote, image1, image2);
                      }
                    },
                  );
                },
              ),
            ),

            if (_isSending)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CupertinoActivityIndicator(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),

    );
  }




  void _sendMessage(String v, String voiceNote, String image1, String image2) async {
    if (_isSending || (v.isEmpty && voiceNote.isEmpty && image1.isEmpty && image2.isEmpty)) return;

    if (mounted) setState(() => _isSending = true);

    try {
      final _user = await firebaseServices.getUserWithId(id: currentUser!.uid);

      final newChatMessage = ChatModel(
        message: v,
        userId: _user.userId,
        userNickname: _user.nickname,
        userAvatarUrl: _user.avatarUrl,
        timeCreated: Timestamp.now(),
        audioUrl: voiceNote,
        image1: image1,
        image2: image2,
        members: [_user.userId],
        userType: _user.userType,
        alterEgoId: _user.alterEgoId,
      );


      firebaseServices.addSubMessage(
          widget.documentID!,
          widget.chatRoomPodo!,
          newChatMessage);

      // Update the last activity time for sorting purposes
      updateDiaryroomTimeLastActivity(widget.documentID!, widget.chatRoomPodo!);

      await firebaseServices.saveUserActivity(
        activityType: 'room_join',
        activityMessage: "You messaged a corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}'.",
        sessionId: widget.chatRoomPodo?.id.toString(),
      );

      // --- 3. NOTIFY ALL MEMBERS IN THE CORNER ---
      final visitorNickname = _user.nickname;
      final title = "New Message in ${widget.chatModel?.message ?? 'a Corner'}!";
      final body = "${visitorNickname ?? 'An Ego'} dropped a message in a corner you're in.";
      final routeData = {
        'route': 'diaryRooms',
        'roomId': widget.chatRoomPodo!.id.toString(),
        'cornerId': widget.documentID,
      };

      // Use a Set to avoid duplicate notifications
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
