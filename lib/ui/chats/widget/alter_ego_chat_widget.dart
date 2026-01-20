import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/notification_service.dart';
import '../../../utils/strings.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../../widgets/toast.dart';
import '../alter_ego_sub_chat_screen.dart';

class AlterEgoChatWidget extends StatefulWidget {

  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;

  AlterEgoChatWidget(
      {Key? key,
        required this.documentID,
        required this.chatModel,
        required this.chatRoomPodo,
        this.isSubChat = false})
      : super(key: key);

  @override
  State<AlterEgoChatWidget> createState() => _AlterEgoChatWidgetState();
}

class _AlterEgoChatWidgetState extends State<AlterEgoChatWidget> {
  UserModel userModel = UserModel();
  UserModel? _currentUserModel;
  User? currentUser = FirebaseAuth.instance.currentUser;

  int maxFailedLoadAttempts = 3;
  bool _isProcessing = false;


  getUser() async {
    userModel = await firebaseServices.getUserInfo();
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
    _fetchCurrentUser();
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

  Future<void> _fetchCurrentUser() async {
    if (currentUser != null) {
      // 1. Fetch user data from Firestore
      var userModel = await firebaseServices.getUserInfo();

      // 2. Check if language preference is missing (for existing users)
      if (userModel.languagePreference == null || userModel.languagePreference!.isEmpty) {
        // Get device language
        final deviceLanguageCode = Platform.localeName.split('_').first;

        // Update the model in memory immediately for the UI
        userModel.languagePreference = deviceLanguageCode;

        // Asynchronously update Firestore in the background
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'languagePreference': deviceLanguageCode});

        logger.d("Updated language preference for existing user: $deviceLanguageCode");
      }

      // 3. Update the state to rebuild the widget with the correct language
      if (mounted) {
        setState(() {
          _currentUserModel = userModel;
          // Also update the existing userModel variable to ensure compatibility elsewhere in the widget
          this.userModel = userModel;
        });
      }
    }
  }


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
                    SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              widget.chatRoomPodo?.id == 5
                                  ? (_user.nickname ?? 'An Ego')
                                  : (_user.alterEgoId ?? 'An Alter Ego'),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: GoogleFonts.lato(
                                  fontSize: 15.0,
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
                                  fontSize: 11.0,
                                  color: Pallet.colorGrey,
                                  fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ),

                    StreamBuilder(
                        stream: firebaseServices
                            .getAlterEgoSubMessages(widget.documentID!, widget.chatRoomPodo!, widget.chatModel!),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                          if (snapShot.hasError) {
                            return Container();
                          }
                          if (snapShot.hasData) {
                            return Text(
                              snapShot.data!.docs.length.toString() + " Online 🟢",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600
                              ),
                            );
                          }
                          return Container();
                        }),

                  ],
                );
              }),
          SizedBox(
            height: 6,
          ),
          Text(
            (_currentUserModel?.languagePreference != null &&
                widget.chatModel?.translatedMessage != null &&
                widget.chatModel!.translatedMessage!
                    .containsKey(_currentUserModel!.languagePreference))
                ? widget.chatModel!.translatedMessage![_currentUserModel!.languagePreference]!
                : widget.chatModel!.message!,
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
                      _createLeaveChatInterstitialAd();
                      visitedUsersID = _userModel.userId ?? '';
                      showToast('Thanks for your time. Just a short ad please.');

                      deleteAlterEgoSubChat();
                      updateMembers(joining: false);
                      _showLeaveChatInterstitialAd(); // Show ad on leaving
                      firebaseServices.unsubscribeToChatRoom(widget.chatModel!.userId.toString());

                      Future.delayed(Duration(seconds: 4), () {
                        _showLeaveChatInterstitialAd();
                      });

                    },
                    child: Container(
                        padding: EdgeInsets.all(5),
                        width: 65,
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
                            '${widget.chatModel!.members!.length} LEAVE',
                            style: TextStyle(
                                fontSize: 12,
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

                      // WRONG: _showContChatInterstitialAd(); // DO NOT call the ad here. It blocks navigation.

                      try {
                        final String cornerOwnerId = widget.chatModel!.userId!;
                        final UserModel cornerOwner = await firebaseServices.getUserWithId(id: cornerOwnerId);
                        final String cornerOwnerNickname = cornerOwner.alterEgoId.toString();
                        final String visitorId = currentUser!.uid;
                        final UserModel visitor = await firebaseServices.getUserWithId(id: visitorId);
                        final visitorNickname = visitor.alterEgoId;
                        bool canProceed = false;

                        if (visitorId == cornerOwnerId) {
                          showToast('Welcome back to your Alter Ego corner.');
                          canProceed = true;
                        } else {
                          const int entryCost = 1;
                          const int taxAmount = 1;
                          const int totalDebit = entryCost + taxAmount;

                          if (visitor.currentLoveCount < totalDebit) {
                            showToast("You need at least $totalDebit❤️ to continue in this corner.");
                          } else {
                            bool success = await firebaseServices.transferLoveBetweenUsers(
                              senderId: visitorId,
                              receiverId: cornerOwnerId,
                              amountToSend: entryCost,
                              taxAmount: taxAmount,
                              totalDebitAmount: totalDebit,
                              senderTransactionDesc: "$totalDebit❤️ for re-entering ${cornerOwnerNickname}'s corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                              receiverTransactionDesc: "$entryCost❤️ from ${visitorNickname} re-entering your corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                              claireTransactionDesc: "$taxAmount❤️ Tax from Alter Ego corner reentry.",
                              forRoomVisits: entryCost,
                              fromRoomVisits: entryCost,
                            );
                            canProceed = success;
                            if(success) {
                              showToast('Welcome Back to this corner with 1❤️ and positive vibes only.');
                            }
                          }
                        }

                        if (canProceed) {
                          await firebaseServices.saveUserActivity(
                            activityType: 'room_join',
                            activityMessage: "You re-entered ${cornerOwnerNickname}'s Alter Ego corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}'.",
                            sessionId: widget.chatRoomPodo!.id.toString(),
                          );
                          _showContChatInterstitialAd(); // Show ad on successful continuation
                          if (!mounted) return;
                          PageRouter.gotoWidget(
                              AlterEgoSubChatScreen( // Correct navigation target
                                documentID: cornerOwnerId,
                                chatModel: widget.chatModel,
                                chatRoomPodo: widget.chatRoomPodo,
                              ),
                              context);

                          if (visitorId != cornerOwnerId) {
                            await notificationService.sendNotification({
                              "token": cornerOwner.fcmId,
                              "notification": {
                                "title": "Someone Entered Your Alter Ego Corner. Again!",
                                "body": "${visitorNickname ?? 'An Alter Ego'} returned with 1❤️ to your corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}.",
                              },
                              "data": {
                                'route': 'alterEgoDiaryRooms',
                                'roomId': widget.chatRoomPodo!.id.toString(),
                              },
                            });
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
                            'Continue',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Pallet.colorPrimaryDark,
                            ),
                          ),
                        )),
                  ),
                ),



              if (!widget.chatModel!.members!.contains(currentUser!.uid))
                Visibility(
                  visible: !_isCompleted(widget.chatModel, widget.chatRoomPodo),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () async {if (_isProcessing) return;
                      setState(() {
                        _isProcessing = true;
                      });

                      try {
                        final String cornerOwnerId = widget.chatModel!.userId!;
                        final UserModel cornerOwner = await firebaseServices.getUserWithId(id: cornerOwnerId);
                        final String cornerOwnerNickname = cornerOwner.alterEgoId.toString();
                        final String visitorId = currentUser!.uid;
                        final UserModel visitor = await firebaseServices.getUserWithId(id: visitorId);
                        final visitorNickname = visitor.alterEgoId;

                        const int entryCost = 3;
                        const int taxAmount = 2;
                        const int totalDebit = entryCost + taxAmount;

                        if (visitor.currentLoveCount < totalDebit) {
                          showToast("You need at least $totalDebit❤️ to join this corner.");
                        } else {
                          final bool transactionSuccess = await firebaseServices.transferLoveBetweenUsers(
                            senderId: visitorId,
                            receiverId: cornerOwnerId,
                            amountToSend: entryCost,
                            taxAmount: taxAmount,
                            totalDebitAmount: totalDebit,
                            senderTransactionDesc: "$totalDebit❤️ for ${cornerOwnerNickname} entering your corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                            receiverTransactionDesc: "$entryCost❤️ from ${visitorNickname} entering your corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}.",
                            claireTransactionDesc: "$taxAmount❤️ Tax from corner join.",
                            forRoomVisits: entryCost,
                            fromRoomVisits: entryCost,
                          );

                          if (transactionSuccess) {
                            updateMembers(joining: true);
                            showToast('Welcome to this corner with 3❤️ and positive vibes only.');

                            await firebaseServices.saveUserActivity(
                              activityType: 'room_join',
                              activityMessage: "You entered ${cornerOwnerNickname}'s corner inside ${widget.chatRoomPodo?.title ?? 'Chatrooms'}'.",
                              sessionId: widget.chatRoomPodo!.id.toString(),
                            );
                            _showJoinChatInterstitialAd(); // Show ad on successful join

                            if (!mounted) return;
                            PageRouter.gotoWidget(
                                AlterEgoSubChatScreen(
                                  documentID: cornerOwnerId,
                                  chatModel: widget.chatModel,
                                  chatRoomPodo: widget.chatRoomPodo,
                                ),
                                context);

                            await notificationService.sendNotification({
                              "token": cornerOwner.fcmId,
                              "notification": {
                                "title": "Someone Entered Your Alter Ego Corner!",
                                "body": "${visitorNickname ?? 'An Alter Ego'} entered with 3❤️ to your corner inside ${widget.chatRoomPodo!.title ?? 'Chatrooms'}.",
                              },
                              "data": {
                                'route': 'alterEgoDiaryRooms',
                                'roomId': widget.chatRoomPodo!.id.toString(),
                              },
                            });
                          } else {
                            showToast("Could not process entry. Please try again.");
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
                                :  Text(
                              '${widget.chatModel!.members!.length} JOIN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _isCompleted(widget.chatModel, widget.chatRoomPodo)
                                    ? Pallet.blueGreyBgColor
                                    : Pallet.colorSplashScreen,
                              ),
                            ),
                          )),
                    ),
                  ),
                ),


              if (!widget.chatModel!.members!.contains(currentUser!.uid))
                Visibility(
                  visible: _isCompleted(widget.chatModel, widget.chatRoomPodo),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () {
                        _createLeaveChatInterstitialAd();

                        showToast('Sorry, this corner is full.\n'
                            'Start your own corner after this ad.');

                        Future.delayed(Duration(seconds: 5), () {
                          _showLeaveChatInterstitialAd();
                        });
                      },
                      child: Container(
                          padding: EdgeInsets.all(5),
                          width: 100,
                          height: 25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            gradient: LinearGradient(
                              begin: Alignment(
                                  -0.37857140550652835, -1.9473685559777252),
                              end: Alignment(1.2428571464417884, 2.526316110739735),
                              stops: [0.0, 0.856177031993866, 1.0],
                              colors: [
                                Colors.black45,
                                Pallet.grey,
                                Pallet.deepGreen,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.chatModel!.members!.length} Corner Full',
                              style: TextStyle(
                                  color: _isCompleted(widget.chatModel, widget.chatRoomPodo)
                                      ? Pallet.blueGreyBgColor
                                      : Pallet.colorSplashScreen,
                                  fontWeight: FontWeight.w600),
                            ),
                          )),
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
    return chatModel!.members!.length == chatRoomPodo?.numberOfParticipants;
  }

  void updateMembers({required bool joining}) async {
    final userID = currentUser!.uid.toString();
    if (joining) {
      widget.chatModel!.members!.add(userID);
    }
    if (!joining) {
      widget.chatModel!.members!.remove(userID);
    }
    firebaseServices.updateAlterEgoMembers(widget.chatModel!.userId.toString(), widget.chatRoomPodo, widget.chatModel!);
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
        deleteAlterEgoChat();
        deleteAlterEgoSubChat();
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

  Future<void> deleteAlterEgoChat() async {
    final collection = FirebaseFirestore.instance
        .collection("alterEgoChats")
        .doc(widget.chatRoomPodo!.id.toString())
        .collection(widget.chatRoomPodo!.title!);
    await collection.doc(widget.chatModel!.userId.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(widget.chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }

  Future<void> deleteAlterEgoSubChat() async {
    final collection = FirebaseFirestore.instance
        .collection("alterEgoChats")
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
