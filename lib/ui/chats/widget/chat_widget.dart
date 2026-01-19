import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/chats/sub_chat_screen.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/data/notification_model.dart' as push_notification;
import '../../../services/notification_service.dart';
import '../../../utils/strings.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../../widgets/toast.dart';
import '../../ego-profile/top_up_loves_page.dart';

class ChatWidget extends StatefulWidget {

  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;

  ChatWidget(
      {Key? key,
      required this.documentID,
      required this.chatModel,
      required this.chatRoomPodo,
      this.isSubChat = false})
      : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  UserModel userModel = UserModel();

  User? currentUser = FirebaseAuth.instance.currentUser;

  int maxFailedLoadAttempts = 3;

  getUser() async {
    var info = await firebaseServices.getUserInfo();
    if (mounted) {
      setState(() {
        userModel = info;
      });
    }
  }

  late String visitedUsersID;

  late String visitedEgoName;

  late UserModel _userModel;

  // Ad-related variables remain the same
  InterstitialAd? _joinChatInterstitialAd;
  int _joinChatInterstitialLoadAttempts = 0;
  InterstitialAd? _leaveChatInterstitialAd;
  int _leaveChatInterstitialLoadAttempts = 0;
  InterstitialAd? _contChatInterstitialAd;
  int _contChatInterstitialLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    getUser();
    _createJoinChatInterstitialAd();
    _createLeaveChatInterstitialAd();
    _createContChatInterstitialAd();
  }

  @override
  void dispose() {
    _joinChatInterstitialAd?.dispose();
    _leaveChatInterstitialAd?.dispose();
    _contChatInterstitialAd?.dispose();
    super.dispose();
  }

  bool _isAvatarLoading = false;
  bool _isProcessing = false;


  /// Create and show Join Chat interstitial ad.

  void _createJoinChatInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/7417113912" :
      Platform.isIOS? "ca-app-pub-2404156870680632/7030101104" :
      '',      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _joinChatInterstitialAd = ad;
          _joinChatInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _joinChatInterstitialLoadAttempts += 1;
          _joinChatInterstitialAd = null;
          if (_joinChatInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createJoinChatInterstitialAd();
          }
        },
      ),
    );
  }

  void _showJoinChatInterstitialAd() {
    if (_joinChatInterstitialAd != null) {
      _joinChatInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createJoinChatInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createJoinChatInterstitialAd();
        },
      );
      _joinChatInterstitialAd!.show();
    }
  }


  /// Create Leave Chat interstitial ad.

  void _createLeaveChatInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/3286297210" :
      Platform.isIOS? "ca-app-pub-2404156870680632/1011487667" :
      '',      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _leaveChatInterstitialAd = ad;
          _leaveChatInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _leaveChatInterstitialLoadAttempts += 1;
          _leaveChatInterstitialAd = null;
          if (_leaveChatInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createLeaveChatInterstitialAd();
          }
        },
      ),
    );
  }

  void _showLeaveChatInterstitialAd() {
    if (_leaveChatInterstitialAd != null) {
      _leaveChatInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createLeaveChatInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createLeaveChatInterstitialAd();
        },
      );
      _leaveChatInterstitialAd!.show();
    }
  }

  /// Create and show Continue Chat interstitial ad.

  void _createContChatInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/2293350565" :
      Platform.isIOS? "ca-app-pub-2404156870680632/3728601600" :
      '',      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _contChatInterstitialAd = ad;
          _contChatInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _contChatInterstitialLoadAttempts += 1;
          _contChatInterstitialAd = null;
          if (_contChatInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createContChatInterstitialAd();
          }
        },
      ),
    );
  }

  void _showContChatInterstitialAd() {
    if (_contChatInterstitialAd != null) {
      _contChatInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createContChatInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createContChatInterstitialAd();
        },
      );
      _contChatInterstitialAd!.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              AppImages.appChatBg,
            ),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(25), color: Pallet.colorWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder(
              future: firebaseServices.getUserWithId(id: widget.chatModel!.userId),
              builder: (_, AsyncSnapshot<UserModel> snap) {
                if (!snap.hasData) {
                  return Container();
                }
                UserModel? _user = snap.data;
                _userModel = snap.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          _isAvatarLoading = true;
                        });
                        try {
                        // --- 1. SETUP TRANSACTION DETAILS ---
                        final visitingUser = await firebaseServices.getUserInfo();
                        final String visitedUserId = _user.userId!;
                        final String visitedEgoName = _user.nickname!;
                        const int visitCost = 1;

                        // --- 2. HANDLE SELF-VISIT, INSUFFICIENT LOVES & PERMISSIONS ---
                        if (visitingUser.userId == visitedUserId) {
                          // If visiting self, just navigate without a transaction.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: visitedUserId,
                                  visitedEgoName: visitedEgoName),
                              context);
                          return;
                        }

                        if (visitingUser.userType == "REGULAR" &&
                            visitingUser.currentLoveCount < 100) {
                          showToast("Need up to 500 Loves in Wallet or Alter Ego Access to view other Ego Profiles.");
                          return;
                        }

                        if (visitingUser.currentLoveCount < visitCost) {
                          showToast("You need at least 1 ❤️ to visit a profile.");
                          return;
                        }

                        // --- 3. PERFORM THE LOVE TRANSACTION ---
                        final bool success =
                        await firebaseServices.transferLoveBetweenUsers(
                          senderId: visitingUser.userId!,
                          receiverId: visitedUserId,
                          amountToSend: visitCost,
                          taxAmount: 0,
                          totalDebitAmount: visitCost,
                          senderTransactionDesc:
                          "1❤️ visiting ${visitedEgoName}'s Ego.",
                          receiverTransactionDesc:
                          "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                          claireTransactionDesc:
                          "Tax from a profile visit.", // Will be 0, but required
                          forProfileVisits: 1, // Stat for the sender
                          fromProfileVisits: 1, // Stat for the receiver
                          metadata: {
                            'reason': 'profile_visit',
                            'visitedUserId': visitedUserId
                          },
                        );

                        // --- 4. NAVIGATE ON SUCCESS ---
                        if (success) {
                          showToast("You are visiting ${visitedEgoName} with a kola of 1❤️.");

                          // --- START TARGETED NOTIFICATION LOGIC ---
                          try {
                            // We already have the visiting user's info, now get the visited user's token.
                            final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(visitedUserId).get();
                            if (receiverDoc.exists) {
                              final receiverToken = receiverDoc.data()?['fcmId'] as String?;
                              final senderName = visitingUser.nickname ?? 'A user';

                              if (receiverToken != null && receiverToken.isNotEmpty) {
                                await notificationService.sendNotification({
                                  "token": receiverToken,
                                  "notification": {
                                    "title": "Your Ego profile has a visitor!",
                                    "body": "$senderName just visited your profile with a kola of 1❤️."
                                  },
                                  "data": {
                                    // Navigate the user to their own profile page to see the updated stats.
                                    "route": "egoPage"
                                  }
                                });
                              }
                            }
                          } catch (e) {
                            print("Error sending profile visit notification: $e");
                            // Don't block the user flow if notifications fail.
                          }
                          // --- END TARGETED NOTIFICATION LOGIC ---

                          // --- NAVIGATE ---
                          // Only navigate to the profile if the transaction was successful.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: visitedUserId,
                                  visitedEgoName: visitedEgoName),
                              context);
                        }
                        } finally {
                          // --- 3. HIDE THE LOADER (GUARANTEED) ---
                          // This runs no matter how the try block exits.
                          if (mounted) {
                            setState(() {
                              _isAvatarLoading = false;
                            });
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                              width: 40,
                              height: 40,
                              imageUrl: _user!.avatarUrl ?? '',
                              imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                              placeholder: (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                    width: 35,
                                    height: 35,
                                  ) //Icon(Icons.error),
                              ),
                          // --- 2. ADD THE OVERLAY LOADER ---
                          if (_isAvatarLoading)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _isAvatarLoading = true;
                          });
                          try {
                          // --- 1. SETUP TRANSACTION DETAILS ---
                          final visitingUser = await firebaseServices.getUserInfo();
                          final String visitedUserId = _user.userId!;
                          final String visitedEgoName = _user.nickname!;
                          const int visitCost = 1;

                          // --- 2. HANDLE SELF-VISIT, INSUFFICIENT LOVES & PERMISSIONS ---
                          if (visitingUser.userId == visitedUserId) {
                            // If visiting self, just navigate without a transaction.
                            PageRouter.gotoWidget(
                                VisitedUserEgoProfilePage(
                                    visitedUsersID: visitedUserId,
                                    visitedEgoName: visitedEgoName),
                                context);
                            return;
                          }

                          if (visitingUser.userType == "REGULAR" &&
                              visitingUser.currentLoveCount < 100) {
                            showToast("Need up to 500 Loves in Wallet or Alter Ego Access to view other Ego Profiles.");
                            return;
                          }

                          if (visitingUser.currentLoveCount < visitCost) {
                            showToast("You need at least 1 ❤️ to visit a profile.");
                            return;
                          }

                          // --- 3. PERFORM THE LOVE TRANSACTION ---
                          final bool success =
                          await firebaseServices.transferLoveBetweenUsers(
                            senderId: visitingUser.userId!,
                            receiverId: visitedUserId,
                            amountToSend: visitCost,
                            taxAmount: 0,
                            totalDebitAmount: visitCost,
                            senderTransactionDesc:
                            "1❤️ for visiting ${visitedEgoName}'s Ego.",
                            receiverTransactionDesc:
                            "1❤️ from ${visitingUser.nickname} visiting your Ego.",
                            claireTransactionDesc:
                            "Tax from a profile visit.", // Will be 0, but required
                            forProfileVisits: 1, // Stat for the sender
                            fromProfileVisits: 1, // Stat for the receiver
                            metadata: {
                              'reason': 'profile_visit',
                              'visitedUserId': visitedUserId
                            },
                          );

                          // --- 4. NAVIGATE ON SUCCESS ---
                          if (success) {
                            showToast("You are visiting ${visitedEgoName} with a kola of 1❤️.");

                            // --- START TARGETED NOTIFICATION LOGIC ---
                            try {
                              // We already have the visiting user's info, now get the visited user's token.
                              final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(visitedUserId).get();
                              if (receiverDoc.exists) {
                                final receiverToken = receiverDoc.data()?['fcmId'] as String?;
                                final senderName = visitingUser.nickname ?? 'A user';

                                if (receiverToken != null && receiverToken.isNotEmpty) {
                                  await notificationService.sendNotification({
                                    "token": receiverToken,
                                    "notification": {
                                      "title": "Your Ego profile has a visitor!",
                                      "body": "$senderName just visited your profile with a kola of 1❤️."
                                    },
                                    "data": {
                                      // Navigate the user to their own profile page to see the updated stats.
                                      "route": "egoPage"
                                    }
                                  });
                                }
                              }
                            } catch (e) {
                              print("Error sending profile visit notification: $e");
                              // Don't block the user flow if notifications fail.
                            }
                            // --- END TARGETED NOTIFICATION LOGIC ---

                            // --- NAVIGATE ---
                            // Only navigate to the profile if the transaction was successful.
                            PageRouter.gotoWidget(
                                VisitedUserEgoProfilePage(
                                    visitedUsersID: visitedUserId,
                                    visitedEgoName: visitedEgoName),
                                context);
                          }
                          } finally {
                            // --- 3. HIDE THE LOADER (GUARANTEED) ---
                            // This runs no matter how the try block exits.
                            if (mounted) {
                              setState(() {
                                _isAvatarLoading = false;
                              });
                            }
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user.nickname.toString() ?? '',
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 16.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(
                              height: 2,
                            ),
                            Text(
                                timeConverter(widget.chatModel!.timeCreated!,
                                    time: TimeConverterEnum.Comment),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorGrey,
                                    fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),

                    Column(
                      children: [
                        Text(
                          widget.chatModel!.members!.length.toString() + " Joined",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,

                              color: _isCompleted(widget.chatModel, widget.chatRoomPodo)
                                  ? Pallet.colorPrimaryDark
                                  : Pallet.colorSplashScreen),
                        ),

                        SizedBox(height: 4,),

                        StreamBuilder(
                            stream: firebaseServices
                                .getSubMessages(widget.documentID!, widget.chatRoomPodo!, widget.chatModel!),
                            builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                              if (snapShot.hasError) {
                                return Container();
                              }
                              if (snapShot.hasData) {
                                return Text(
                                    snapShot.data!.docs.length <1?
                                  snapShot.data!.docs.length.toString() + " Online":
                                    snapShot.data!.docs.length.toString() + " Online 🟢",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600
                                  ),
                                );
                              }
                              return Container();
                            }),
                      ],
                    ),

                  ],
                );
              }),
          SizedBox(
            height: 6,
          ),
          Linkify(
            onOpen: (link) async {
              final Uri url = Uri.parse("${link.url}");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                throw 'Could not launch $link';
              }
            },
            linkStyle: TextStyle(color: Colors.blue),
            text: widget.chatModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 18.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          _buildImageGrid(context),

          Visibility(
            visible: widget.chatModel?.audioUrl != '',
            child: Container(
              child: PlayAdviseVoiceNote(filePath: widget.chatModel!.audioUrl),
            ),
          ),

          SizedBox(height: 8,),

          Row(
            children: [

              Visibility(
                visible: widget.chatModel!.userId == currentUser!.uid,
                child: GestureDetector(
                  onTap: () {
                    if (widget.chatModel!.userId == currentUser?.uid)
                      deletedRoomAlertDialog(context);
                  },
                  child: Visibility(
                    visible: widget.chatModel!.userId == currentUser?.uid,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                         ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever_rounded,
                            color: Pallet.colorPrimaryDark,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),


              if (widget.chatModel!.members!.contains(currentUser!.uid))
              Align(
                alignment: Alignment.bottomLeft,
                child: InkWell(
                  onTap: () {
                    visitedUsersID = _userModel.userId ?? '';
                      showToast('Thanks for your time. A short ad might show.');

                    deleteSubChat();
                    updateMembers(joining: false);
                    firebaseServices.unsubscribeToChatRoom(widget.chatModel!.userId.toString());
                    _showLeaveChatInterstitialAd(); // Show ad on leaving

                  },
                  child: Container(
                      padding: EdgeInsets.all(3),
                      width: 60,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment(
                              -0.37857140550652835, -1.9473685559777252),
                          end: Alignment(1.2428571464417884, 2.526316110739735),
                          stops: [0.0, 0.856177031993866, 1.0],
                          colors: [
                            Colors.white70,
                            Pallet.colorPrimary,
                            Pallet.colorPrimaryDark,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'LEAVE',
                          style: TextStyle(
                            fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _isCompleted(widget.chatModel, widget.chatRoomPodo)
                                  ? Pallet.colorPrimaryDark
                                  : Pallet.colorSplashScreen),
                        ),
                      )),
                ),
              ),

              SizedBox(width: 6,),


              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(currentUser?.uid)
                    .get(),
                builder: (_, snapshot) {
                  if (snapshot.hasData) {
                    var data = snapshot.data!.data();
                    var userType = data?["userType"];

                    return
                      Visibility(
                        visible: userType == "SUPER_ADMIN",
                        child: GestureDetector(
                          onTap: () {
                              deletedRoomAlertDialog(context);
                          },
                          child: Row(
                            children: [
                              Row(
                                children: [

                                  Text(
                                    'Mod',
                                    style: GoogleFonts.lato(
                                        fontSize: 13.0,
                                        color: Pallet.colorSecondary,
                                        fontWeight: FontWeight.w800),
                                  ),

                                  Visibility(
                                    visible: userType == "SUPER_ADMIN",
                                    child: Icon(
                                      Icons.delete_forever_rounded,
                                      color: Pallet.colorSecondary,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                  }

                  return Container();
                },
              ),


              Spacer(flex: 1,),


              if (widget.chatModel!.members!.contains(currentUser!.uid))
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () async {
                      // --- PREVENT DOUBLE TAPS & SHOW LOADER ---
                      if (_isProcessing) return;
                      setState(() {
                        _isProcessing = true;
                      });

                      try {
                        final String cornerOwnerId = widget.chatModel!.userId!;
                        final UserModel cornerOwner = await firebaseServices.getUserWithId(id: cornerOwnerId);
                        final String cornerOwnerNickname = cornerOwner.nickname.toString();
                        final String visitorId = currentUser!.uid;
                        final UserModel visitor = await firebaseServices.getUserWithId(id: visitorId);
                        final visitorNickname = visitor.nickname;
                        bool canProceed = false;

                        if (visitorId == cornerOwnerId) {
                          // User is entering their own room, no cost.
                          showToast('Welcome back to your corner.');
                          canProceed = true;
                        } else {
                          // A Visitor is re-entering another corner owner's corner.
                          const int entryCost = 1;
                          const int taxAmount = 1;
                          const int totalDebit = entryCost + taxAmount;

                          if (visitor.currentLoveCount < totalDebit) {
                            showToast("You need at least $totalDebit❤️ to continue chat in this corner.");
                            // canProceed remains false
                          } else {

                            // Perform the user-to-user transfer and capture the result
                            bool success = await firebaseServices.transferLoveBetweenUsers(
                              senderId: visitorId,
                              receiverId: cornerOwnerId,
                              amountToSend: entryCost,
                              taxAmount: taxAmount,
                              totalDebitAmount: totalDebit,
                              senderTransactionDesc: "$totalDebit❤️ for re-entering ${cornerOwnerNickname}'s corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                              receiverTransactionDesc: "$entryCost❤️ from ${visitorNickname} re-entering your corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                              claireTransactionDesc: "$taxAmount❤️ Tax from corner reentry.",
                              forRoomVisits: entryCost,
                              fromRoomVisits: entryCost,
                            );
                            canProceed = success; // Set canProceed based on transaction outcome
                          }
                        }

                        // --- EXECUTE SUBSEQUENT ACTIONS ONLY IF ALLOWED ---
                        if (canProceed) {
                          await firebaseServices.saveUserActivity(
                            activityType: 'room_join',
                            activityMessage: "You re-entered ${cornerOwnerNickname}'s corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}'.",
                            sessionId: widget.chatRoomPodo!.id.toString(),
                          );
                          _showContChatInterstitialAd(); // Show ad on successful continuation

                          // Safety check before navigating
                          if (!mounted) return;
                          PageRouter.gotoWidget(
                              SubChatScreen(
                                documentID: cornerOwnerId,
                                chatModel: widget.chatModel,
                                chatRoomPodo: widget.chatRoomPodo,
                              ),
                              context);

                          // Send notification only if it's not the owner re-entering
                          if (visitorId != cornerOwnerId) {
                            await notificationService.sendNotification({
                              "token": cornerOwner.fcmId,
                              "notification": {
                                "title": "Someone Entered Your Corner. Again!",
                                "body": "${visitorNickname ?? 'An Ego'} returned with 1❤️ to your corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}.",
                              },
                              "data": {
                                'route': 'diaryRooms',
                                'roomId': widget.chatRoomPodo!.id.toString(),
                              },
                            });
                          }
                          showToast('Welcome Back to this corner with 1❤️ and positive vibes only.');
                        }
                        // If canProceed is false for any reason, the code will skip to the finally block.

                      } finally {
                        // --- HIDE THE LOADER ---
                        if (mounted) {
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      }
                    },
                    child: Container(
                        padding: EdgeInsets.all(5),
                        width: 85,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          gradient: LinearGradient(
                            begin: Alignment(
                                -0.37857140550652835, -1.9473685559777252),
                            end: Alignment(1.2428571464417884, 2.526316110739735),
                            stops: [0.0, 0.856177031993866, 1.0],
                            colors: [
                              Colors.lightGreen,
                              Pallet.green,
                              Pallet.deepGreen,
                            ],
                          ),
                        ),
                        child: Center(
                          child: _isProcessing
                              ? CupertinoActivityIndicator(color: Pallet.colorPrimaryDark)
                              : Text(
                            'CONTINUE',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Pallet.colorPrimaryDark,
                            ),
                          ),
                        )),
                  ),
                ),



              Visibility(
                // Visible if:
                // 1. Not a member AND
                // 2. (Room is NOT full OR it is the Claire DM Room -1)
                visible: !widget.chatModel!.members!.contains(currentUser!.uid) &&
                    (!_isCompleted(widget.chatModel, widget.chatRoomPodo) || widget.chatRoomPodo?.id == -1),
                child: Align(
                alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () async {
                      if (_isProcessing) return;
                      setState(() {
                        _isProcessing = true;
                      });

                      try {
                        final String cornerOwnerId = widget.chatModel!.userId!;
                        final UserModel cornerOwner = await firebaseServices.getUserWithId(id: cornerOwnerId);
                        final String cornerOwnerNickname = cornerOwner.nickname.toString();
                        final String visitorId = currentUser!.uid;
                        final UserModel visitor = await firebaseServices.getUserWithId(id: visitorId);
                        final visitorNickname = visitor.nickname;

                        // Await the database update to ensure it completes before proceeding.
                        if (!_isCompleted(widget.chatModel, widget.chatRoomPodo)) {
                          await updateMembers(joining: true);
                        }
                        // PERFORM THE TRANSACTION FOR JOINING ---
                        const int entryCost = 3;
                        const int taxAmount = 2;
                        const int totalDebit = entryCost + taxAmount;

                        if (visitor.currentLoveCount < totalDebit) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => TopUpLovesPage(feature: 'diary_rooms'),
                          ));
                        }


                        if (visitor.currentLoveCount < totalDebit) {
                          showToast("You need at least $totalDebit❤️ to enter this corner.");
                        } else {
                          final bool transactionSuccess =
                          await firebaseServices.transferLoveBetweenUsers(
                            senderId: visitorId,
                            receiverId: cornerOwnerId,
                            amountToSend: entryCost,
                            taxAmount: taxAmount,
                            totalDebitAmount: totalDebit,
                            senderTransactionDesc:
                            "$totalDebit❤️ for ${cornerOwnerNickname} entering your corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                            receiverTransactionDesc:
                            "$entryCost❤️ from ${visitorNickname} entering your corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                            claireTransactionDesc: "$taxAmount❤️ Tax from corner join.",
                            forRoomVisits: entryCost,
                            fromRoomVisits: entryCost,
                          );

                          if (transactionSuccess) {
                            await firebaseServices.saveUserActivity(
                              activityType: 'room_join',
                              activityMessage:
                              "${visitorNickname} entered ${cornerOwnerNickname}'s corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}'.",
                              sessionId: widget.chatRoomPodo!.id.toString(),
                            );
                            _showJoinChatInterstitialAd();

                            if (!mounted) return;
                            PageRouter.gotoWidget(
                                SubChatScreen(
                                  documentID: cornerOwnerId,
                                  chatModel: widget.chatModel,
                                  chatRoomPodo: widget.chatRoomPodo,
                                ),
                                context);

                            await notificationService.sendNotification({
                              "token": cornerOwner.fcmId,
                              "notification": {
                                "title": "Someone Entered Your Corner!",
                                "body":
                                "${visitorNickname ?? 'An Ego'} entered with 3❤️ to your corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}.",
                              },
                              "data": {
                                'route': 'diaryRooms',
                                'roomId': widget.chatRoomPodo!.id.toString(),
                                'cornerId': widget.chatModel!.userId.toString(),
                              },
                            });

                            showToast('Welcome to this corner with 3❤️ and positive vibes only.');
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      }
                    },

                    child: Container(
                        padding: EdgeInsets.all(5),
                        width: 70,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          gradient: LinearGradient(
                            begin: Alignment(
                                -0.37857140550652835, -1.9473685559777252),
                            end: Alignment(1.2428571464417884, 2.526316110739735),
                            stops: [0.0, 0.856177031993866, 1.0],
                            colors: [
                              Colors.lightGreen,
                              Pallet.green,
                              Pallet.deepGreen,
                            ],
                          ),
                        ),
                        child: Center(
                          child: _isProcessing
                              ? CupertinoActivityIndicator(color: Pallet.colorSplashScreen)
                              : Text(
                            '${widget.chatModel!.members!.length} JOIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              // If it's Room -1, always show as active (colorSplashScreen)
                              color: (widget.chatRoomPodo?.id == -1)
                                  ? Pallet.colorSplashScreen
                                  : (_isCompleted(widget.chatModel, widget.chatRoomPodo)
                                  ? Pallet.blueGreyBgColor
                                  : Pallet.colorSplashScreen),
                            ),
                          ),
                        )),
                  ),
              ),
                ),

              // --- SUPER ADMIN MODERATION GATEWAY ---
              if (userModel.userType == "SUPER_ADMIN")
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () {
                      // Navigate quietly without updating members
                      PageRouter.gotoWidget(
                          SubChatScreen(
                            documentID: widget.chatModel!.userId!,
                            chatModel: widget.chatModel,
                            chatRoomPodo: widget.chatRoomPodo,
                          ),
                          context);
                      showToast("Entering as Super Admin (Quiet Mode)");
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      width: 60,
                      height: 25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Pallet.colorSecondaryDark,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.chatModel!.members!.length} MOD',
                          style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),

              // --- REGULAR CORNER FULL INDICATOR ---
              if (!widget.chatModel!.members!.contains(currentUser!.uid) &&
                  userModel.userType != "SUPER_ADMIN")
                Visibility(
                  visible: widget.chatRoomPodo?.id != -1 &&
                      _isCompleted(widget.chatModel, widget.chatRoomPodo),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () {
                        _createLeaveChatInterstitialAd();
                        showToast('Sorry, this corner is full.');
                        _showLeaveChatInterstitialAd();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        width: 100,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          gradient: LinearGradient(
                            colors: [Colors.black45, Pallet.grey, Pallet.deepGreen],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.chatModel!.members!.length} Corner Full',
                            style: TextStyle(
                                color: Pallet.blueGreyBgColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

            ],
          )
        ],
      ),
    );
  }

  bool _isCompleted(ChatModel? chatModel, ChatRoomPodo? chatRoomPodo) {
    // If the room is ID -1 (Claire DM), it's never full.
    if (chatRoomPodo?.id == -1) return false;
    // If user is Admin/Super Admin, they bypass the "Full" logic.
    if (userModel.userType == "SUPER_ADMIN") return false;

    return chatModel!.members!.length == chatRoomPodo?.numberOfParticipants;
  }

  Future<void> updateMembers({required bool joining}) async {
    final userID = currentUser!.uid.toString();
    if (joining) {
      // Add the user to the local model instance
      widget.chatModel!.members!.add(userID);
    } else {
      // Remove the user from the local model instance
      widget.chatModel!.members!.remove(userID);
    }
    // Perform the database update directly here and await it.
    await FirebaseFirestore.instance
        .collection(AppString.appChats)
        .doc(widget.chatRoomPodo!.id.toString())
        .collection(widget.chatRoomPodo!.title!)
        .doc(widget.chatModel!.userId.toString())
        .update(widget.chatModel!.toJson());
  }


  deletedRoomAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Wait First"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Delete Now"),
      onPressed:  () async {
        deleteChat();
        deleteSubChat();
        showToast("You have deleted the chat. Keep the aura clean!");
        firebaseServices.unsubscribeToChatRoom(widget.chatRoomPodo!.id.toString());
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("End And Delete Your Chat Corner?"),
      content: Text(AppString.delete_chat_alert_note),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  /// Delete an Advise

  Future<void> deleteChat() async {
    final collection = FirebaseFirestore.instance
        .collection(AppString.appChats)
        .doc(widget.chatRoomPodo!.id.toString())
        .collection(widget.chatRoomPodo!.title!);
    await collection.doc(widget.chatModel!.userId.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(widget.chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }

  Future<void> deleteSubChat() async {
    final collection = FirebaseFirestore.instance
        .collection(AppString.appChats)
        .doc(widget.chatRoomPodo!.id.toString())
        .collection(widget.chatRoomPodo!.title!)
        .doc(widget.chatModel!.userId.toString())
        .collection(widget.chatModel!.userId.toString());
    await collection.doc(widget.chatModel!.userId.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(widget.chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }


  // --- NEW: Helper widget to build the image display ---
  Widget _buildImageGrid(BuildContext context) {
    final bool hasImage1 = widget.chatModel!.image1 != null && widget.chatModel!.image1!.isNotEmpty;
    final bool hasImage2 = widget.chatModel!.image2 != null && widget.chatModel!.image2!.isNotEmpty;

    // Only build the grid if there is at least one image
    if (!hasImage1 && !hasImage2) {
      return const SizedBox.shrink(); // Return an empty widget if no images
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        // The children are expanded, so they will fill the row.
        // If there's only one image, it will take up the full width.
        children: [
          if (hasImage1)
            Expanded(child: _buildClickableImage(context, widget.chatModel!.image1!)),
          if (hasImage1 && hasImage2)
            const SizedBox(width: 8), // Spacer between images
          if (hasImage2)
            Expanded(child: _buildClickableImage(context, widget.chatModel!.image2!)),
        ],
      ),
    );
  }

  // --- NEW: Helper for a single clickable image with rounded corners ---
  Widget _buildClickableImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () {
        PageRouter.gotoWidget(CustomImageWidget(imageUrl: imageUrl), context);
      },
      // Constrain the height for a preview look
      child: SizedBox(
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0), // Consistent rounded corners
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CupertinoActivityIndicator()),
            errorWidget: (context, url, error) => Image.asset(
              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }


  }
