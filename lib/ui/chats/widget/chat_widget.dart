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

class ChatWidget extends StatelessWidget {

  UserModel userModel = UserModel();
  User? currentUser = FirebaseAuth.instance.currentUser;

  int maxFailedLoadAttempts = 3;


  getUser() async {
    userModel = await firebaseServices.getUserInfo();
  }

  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;
  late String visitedUsersID;
  late String visitedEgoName;
  late UserModel _userModel;

  ChatWidget(
      {Key? key,
      required this.documentID,
      required this.chatModel,
      required this.chatRoomPodo,
      this.isSubChat = false})
      : super(key: key);



  InterstitialAd? _leaveChatInterstitialAd;
  int _leaveChatInterstitialLoadAttempts = 0;

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
              future: firebaseServices.getUserWithId(id: chatModel!.userId),
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
                          // --- SEND NOTIFICATION ---
                          try {
                            await notificationService.sendNotification(
                                push_notification.NotificationModel(
                                    topic: visitedUserId,
                                    data: push_notification.Data(id: visitedUserId, route: 'wallet'),
                                    notification: push_notification.Notification(
                                        title: "Someone Visited Your Ego!",
                                        body: "${visitingUser.nickname} visited your Ego Profile with a kola of 1❤️."
                                    )
                                ).toJson()
                            );
                          } catch (e) {
                            print("Failed to send profile visit notification: $e");
                            // Do not block navigation if notification fails
                          }

                          // --- NAVIGATE ---
                          // Only navigate to the profile if the transaction was successful.
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: visitedUserId,
                                  visitedEgoName: visitedEgoName),
                              context);
                        }
                      },
                      child: CachedNetworkImage(
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
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
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
                            // --- SEND NOTIFICATION ---
                            try {
                              await notificationService.sendNotification(
                                  push_notification.NotificationModel(
                                      topic: visitedUserId,
                                      data: push_notification.Data(id: visitedUserId, route: 'wallet'),
                                      notification: push_notification.Notification(
                                          title: "Someone Visited Your Ego!",
                                          body: "${visitingUser.nickname} visited your Ego Profile with a kola of 1❤️."
                                      )
                                  ).toJson()
                              );
                            } catch (e) {
                              print("Failed to send profile visit notification: $e");
                              // Do not block navigation if notification fails
                            }

                            // --- NAVIGATE ---
                            // Only navigate to the profile if the transaction was successful.
                            PageRouter.gotoWidget(
                                VisitedUserEgoProfilePage(
                                    visitedUsersID: visitedUserId,
                                    visitedEgoName: visitedEgoName),
                                context);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user.nickname ?? '',
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
                                timeConverter(chatModel!.timeCreated!,
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
                          chatModel!.members!.length.toString() + " Joined",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,

                              color: _isCompleted(chatModel, chatRoomPodo)
                                  ? Pallet.colorPrimaryDark
                                  : Pallet.colorSplashScreen),
                        ),

                        SizedBox(height: 4,),

                        StreamBuilder(
                            stream: firebaseServices
                                .getSubMessages(documentID!, chatRoomPodo!, chatModel!),
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
          SelectableLinkify(
            onOpen: (link) async {
              final Uri url = Uri.parse("${link.url}");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                throw 'Could not launch $link';
              }
            },
            linkStyle: TextStyle(color: Colors.blue),
            text: chatModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 18.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          Visibility(
            visible: chatModel?.audioUrl != '',
            child: Container(
              child: PlayAdviseVoiceNote(filePath: chatModel!.audioUrl),
            ),
          ),



          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Visibility(
                      visible: chatModel!.image1 != '',
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: chatModel!.image1.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 85,
                            width: 75,
                            imageUrl: chatModel!.image1.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                image: DecorationImage(
                                  image: imageProvider,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                              width: 48,
                              height: 48,
                            ) //Icon(Icons.error),
                        ),
                      )),
                  SizedBox(
                    width: 5,
                  ),
                  Visibility(
                      visible:
                      chatModel!.image2 != '',
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: chatModel!.image2.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 75,
                            width: 75,
                            imageUrl: chatModel!.image2.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                image: DecorationImage(
                                  image: imageProvider,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                              width: 48,
                              height: 48,
                            ) //Icon(Icons.error),
                        ),
                      )),
                ],
              ),
            ),
          ),

          Row(
            children: [

              Visibility(
                visible: chatModel!.userId == currentUser!.uid,
                child: GestureDetector(
                  onTap: () {
                    if (chatModel!.userId == currentUser?.uid)
                      deletedRoomAlertDialog(context);
                  },
                  child: Visibility(
                    visible: chatModel!.userId == currentUser?.uid,
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


              if (chatModel!.members!.contains(currentUser!.uid))
              Align(
                alignment: Alignment.bottomLeft,
                child: InkWell(
                  onTap: () {
                    _createLeaveChatInterstitialAd();
                    visitedUsersID = _userModel.userId ?? '';
                      showToast('Thanks for your time. Just a short ad please.');

                    deleteSubChat();
                    updateMembers(joining: false);
                    firebaseServices.unsubscribeToChatRoom(chatModel!.userId.toString());

                    Future.delayed(Duration(seconds: 4), () {
                      _showLeaveChatInterstitialAd();
                    });

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
                              color: _isCompleted(chatModel, chatRoomPodo)
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


              if (chatModel!.members!.contains(currentUser!.uid))
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () async { // Make sure this is async
                      final String roomOwnerId = chatModel!.userId!;
                      final String visitorId = currentUser!.uid;

                      // --- NEW AND CORRECTED LOGIC ---
                      if (visitorId == roomOwnerId) {
                        // User is entering their own room, no cost.
                        showToast('Welcome back to your room.');
                      } else {
                        // Visitor is entering another user's room.
                        const int entryCost = 3;
                        const int taxAmount = 2;
                        const int totalDebit = entryCost + taxAmount;

                        // Check if the visitor can afford the entry
                        UserModel visitorData = await firebaseServices.getUserWithId(id: visitorId);
                        if (visitorData.currentLoveCount < totalDebit) {
                          showToast("You need at least $totalDebit ❤️ to enter another user's room.");
                          return; // Stop if they can't afford it.
                        }

                        // Perform the user-to-user transfer
                        bool success = await firebaseServices.transferLoveBetweenUsers(
                          senderId: visitorId,
                          receiverId: roomOwnerId,
                          amountToSend: entryCost,
                          taxAmount: taxAmount,
                          totalDebitAmount: totalDebit,
                          senderTransactionDesc: "5❤️ to enter ${chatModel!.userNickname}'s room.",
                          receiverTransactionDesc: "3❤️ for ${visitorData.nickname} visiting your room.",
                          claireTransactionDesc: "2❤️ Tax from room entry.",
                          // Pass the stat increments
                          forRoomVisits: entryCost,
                          fromRoomVisits: entryCost,
                        );

                        if (!success) {
                          // The transaction failed, probably due to a race condition or other error.
                          // The service method already shows a toast.
                          return;
                        }
                      }

                      PageRouter.gotoWidget(
                          SubChatScreen(
                            documentID: roomOwnerId,
                            chatModel: chatModel,
                            chatRoomPodo: chatRoomPodo,
                          ),
                          context);
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
                          child: Text(
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



              if (!chatModel!.members!.contains(currentUser!.uid))
                Visibility(
                  visible: !_isCompleted(chatModel, chatRoomPodo),
                  child: Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () {
                      visitedUsersID = _userModel.userId ?? '';
                      String thisUser = visitedUsersID;

                      if (!_isCompleted(chatModel, chatRoomPodo))

                        updateMembers(joining: true);
                        showToast('Welcome. Start chatting with positive vibes.');


                      PageRouter.gotoWidget(
                            SubChatScreen(
                                documentID: thisUser,
                                chatModel: chatModel,
                                chatRoomPodo: chatRoomPodo,
                            ),
                            context);
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
                          child: Text(
                            '${chatModel!.members!.length} JOIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                                color: _isCompleted(chatModel, chatRoomPodo)
                                    ? Pallet.blueGreyBgColor
                                    : Pallet.colorSplashScreen,
                            ),
                          ),
                        )),
                  ),
              ),
                ),


              if (!chatModel!.members!.contains(currentUser!.uid))
                Visibility(
                  visible: _isCompleted(chatModel, chatRoomPodo),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () {
                        _createLeaveChatInterstitialAd();

                        showToast('Sorry, this room is full.\n'
                            'Start your own room after this ad.');

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
                              '${chatModel!.members!.length} Room Full',
                              style: TextStyle(
                                  color: _isCompleted(chatModel, chatRoomPodo)
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
      chatModel!.members!.add(userID);
    }
    if (!joining) {
      chatModel!.members!.remove(userID);
    }
    firebaseServices.updateMembers(chatModel!.userId.toString(), chatRoomPodo, chatModel!);
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
        firebaseServices.unsubscribeToChatRoom(chatRoomPodo!.id.toString());
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
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo!.title!);
    await collection.doc(chatModel!.userId.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }


  Future<void> deleteSubChat() async {
    final collection = FirebaseFirestore.instance
        .collection(AppString.appChats)
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo!.title!)
        .doc(chatModel!.userId.toString())
        .collection(chatModel!.userId.toString());
    await collection.doc(chatModel!.userId.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }


}
