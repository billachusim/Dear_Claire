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
import '../../services/user_model.dart';
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
    final bool isEavesdropRoom = widget.chatRoomPodo?.title == "Chat Or Eavesdrop Inside Claire's DM";
    final bool isCornerOwner = currentUser?.uid == widget.chatModel?.userId;
    // Admins in the Admin Portal (ID 5) should always have the field visible
    final bool canSendMessage = (widget.chatRoomPodo?.id == 5) || !isEavesdropRoom || isCornerOwner;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Pallet.colorSecondaryDark,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.chatModel!.colorHex!),
        title: Text(widget.chatModel!.userNickname ?? 'Diary Room'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firebaseServices.getAlterEgoSubMessages(
                  widget.documentID!,
                  widget.chatRoomPodo,
                  widget.chatModel!),
              builder: (context, snapShot) {
                if (!snapShot.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                // Reverse the docs if your stream isn't already handling the UI order
                final docs = snapShot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 160, top: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length + 1, // +1 for the header (InsideInsideAlterEgoChatWidget)
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header: The original corner message
                      return InsideInsideAlterEgoChatWidget(
                          documentID: widget.documentID,
                          chatModel: widget.chatModel,
                          chatRoomPodo: widget.chatRoomPodo);
                    }

                    // Replies
                    final doc = docs[index - 1];
                    final chatData = ChatModel.fromJson(doc.data());

                    return InsideInsideInsideAlterEgoChatWidget(
                      documentID: doc.id,
                      chatModel: chatData,
                      chatRoomPodo: widget.chatRoomPodo,
                    );
                  },
                );
              },
            ),

            // Banner Ad
            if (_bottomBannerAd != null && _isBannerAdInitialized)
              Positioned(
                bottom: 65,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    height: _bottomBannerAd!.size.height.toDouble(),
                    width: _bottomBannerAd!.size.width.toDouble(),
                    child: AdWidget(ad: _bottomBannerAd!),
                  ),
                ),
              ),

            // Input Field
            Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) {
                  // This is a chat room or room corner, so commenting should always be open for everyone
                  // who is not explicitly blocked (e.g., in an eavesdrop room and not the owner).
                  // The `canSendMessage` variable already correctly handles this logic.
                  // We pass its value directly to `canComment`.
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

            // Sending Overlay
            if (_isSending)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CupertinoActivityIndicator(color: Colors.white, radius: 15),
                  ),
                ),
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

      // Determine if we are in the Admin Portal room
      final bool isAdminPortal = widget.chatRoomPodo?.id == 5;

      final messageData = ChatModel(
        message: v,
        userId: _user.userId,
        timeLastActivity: Timestamp.now(),
        audioUrl: voiceNote,
        image1: image1,
        image2: image2,
        members: [_user.userId],
        userAvatarUrl: isAdminPortal ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
            : (_user.avatarUrl),
        userNickname: isAdminPortal ? "Claire" : (_user.alterEgoId ?? 'An Alter Ego'),
        userType: _user.userType,
        alterEgoId: _user.alterEgoId,
      );

      if (isAdminPortal) {
        // 1. Redirect to public sub-message method using the public room path (ID -1)
        firebaseServices.addSubMessage(
            widget.documentID!,
            ChatRoomPodo(id: -1, title: "Chat Or Eavesdrop Inside Claire's DM", image: ""),
            messageData
        );

        // 2. Update activity specifically for Admin action
        await firebaseServices.saveUserActivity(
          activityType: 'dm_reply',
          activityMessage: "You replied as Claire inside Claire's DM.",
          sessionId: "-1",
        );
      } else {
        // Standard Alter Ego behavior
        firebaseServices.addAlterEgoSubMessage(
            widget.documentID!,
            widget.chatRoomPodo!,
            messageData);

        await firebaseServices.saveUserActivity(
          activityType: 'room_join',
          activityMessage: "You messaged a corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}.",
          sessionId: widget.chatRoomPodo?.id.toString(),
        );
      }

      updateDiaryroomTimeLastActivity(widget.documentID!, widget.chatRoomPodo!);

      // --- NOTIFICATION LOGIC ---
      final visitorNickname = isAdminPortal ? "Claire" : _user.alterEgoId;
      final title = "Message from ${isAdminPortal ? 'Claire' : 'an Alter Ego'}!";
      final body = "${visitorNickname ?? 'An Ego'} dropped a message in a corner you're in.";

      final routeData = {
        'route': isAdminPortal ? 'diaryRooms' : 'alterEgoDiaryRooms',
        'roomId': isAdminPortal ? '-1' : widget.chatRoomPodo!.id.toString(),
        'cornerId': widget.documentID,
      };

      final memberIds = widget.chatModel?.members?.toSet() ?? {};
      if (widget.chatModel?.userId != null) {
        memberIds.add(widget.chatModel!.userId!);
      }

      for (String memberId in memberIds) {
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
          debugPrint("Error sending notification: $e");
        }
      }

      showToast(message: isAdminPortal ? 'Replied as Claire.' : 'Message Sent.');

    } catch (e) {
      debugPrint("Error in _sendMessage: $e");
      showToast(message: "Failed to send message.");
    } finally {
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
