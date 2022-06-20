import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/chats/data/chatroompodo.dart';
import 'package:dear_claire/ui/chats/data/chats.dart';
import 'package:dear_claire/ui/chats/sub_chat_screen.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/visited_user_ego_page/visited_user_ego_page.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/enums.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../utils/strings.dart';
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

  InterstitialAd? _joinChatInterstitialAd;
  int _joinChatInterstitialLoadAttempts = 0;

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


  InterstitialAd? _contChatInterstitialAd;
  int _contChatInterstitialLoadAttempts = 0;

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
                      onTap: () {
                        visitedUsersID = _user?.userId ?? '';
                        visitedEgoName = _user?.nickname ?? 'Chatter';
                        String thisEgoName = visitedEgoName;
                        String thisUser = visitedUsersID;
                        PageRouter.gotoWidget(
                            VisitedUserEgoProfilePage(
                                visitedUsersID: thisUser,
                                visitedEgoName: thisEgoName),
                            context);
                        print("Visited User ID::: $visitedUsersID");
                      },
                      child: CachedNetworkImage(
                          width: 35,
                          height: 35,
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
                                "assets/images/brown_boy_mask.png",
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
                        onTap: () {
                          visitedUsersID = _user.userId ?? '';
                          visitedEgoName = _user.nickname ?? 'Chatter';
                          String thisEgoName = visitedEgoName;
                          String thisUser = visitedUsersID;
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(
                                  visitedUsersID: thisUser,
                                  visitedEgoName: thisEgoName),
                              context);
                          print("Visited User ID::: $visitedUsersID");
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user.nickname ?? '',
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 13.0,
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
                                    fontSize: 11.0,
                                    color: Pallet.colorGrey,
                                    fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),

                    StreamBuilder(
                        stream: firebaseServices
                            .getSubMessages(documentID!, chatRoomPodo!, chatModel!),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                          if (snapShot.hasError) {
                            return Container();
                          }
                          if (snapShot.hasData) {
                            return Text(
                              snapShot.data!.docs.length.toString() + " Joined 🟢",
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
            chatModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 14.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          SizedBox(height: 5,),

          Row(
            children: [


              Visibility(
                visible: chatModel!.userId == currentUser!.uid,
                child: GestureDetector(
                  onTap: () {
                    if (chatModel!.userId == currentUser?.uid)
                      deletedAdviseAlertDialog(context);
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
                      padding: EdgeInsets.all(5),
                      width: 80,
                      height: 25,
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
                          '${chatModel!.members!.length} LEAVE',
                          style: TextStyle(
                              color: _isCompleted(chatModel, chatRoomPodo)
                                  ? Pallet.colorPrimaryDark
                                  : Pallet.colorSplashScreen),
                        ),
                      )),
                ),
              ),

              Spacer(flex: 1,),


              if (chatModel!.members!.contains(currentUser!.uid))
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () {
                      _createContChatInterstitialAd();
                      visitedUsersID = chatModel!.userId!.toString();
                      String thisUser = visitedUsersID;

                      if (!_isCompleted(chatModel, chatRoomPodo))
                        showToast('Welcome back. Positive vibes only.');

                      Future.delayed(Duration(minutes: 5), () {
                        _showContChatInterstitialAd();
                      });

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
                            'Continue',
                            style: TextStyle(
                                color: Pallet.colorPrimaryDark,
                            fontWeight: FontWeight.w600),
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
                      _createJoinChatInterstitialAd();
                      visitedUsersID = _userModel.userId ?? '';
                      String thisUser = visitedUsersID;

                      if (!_isCompleted(chatModel, chatRoomPodo))

                        updateMembers(joining: true);
                        showToast('Welcome. Start chatting after this ad.');

                      Future.delayed(Duration(seconds: 5), () {
                        _showJoinChatInterstitialAd();
                      });

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
                        width: 80,
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
                                color: _isCompleted(chatModel, chatRoomPodo)
                                    ? Pallet.blueGreyBgColor
                                    : Pallet.colorSplashScreen,
                            fontWeight: FontWeight.w600),
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


  deletedAdviseAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Wait First"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Delete Now"),
      onPressed:  () {
        deleteChat();
        showToast("You have deleted the chat. Keep your aura clean!");
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
    await collection.doc(currentUser!.uid.toString()).delete();
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
    await collection.doc(currentUser!.uid.toString()).delete();
    firebaseServices.unsubscribeToChatRoom(chatModel!.userId.toString());
    logger.d('Successfully deleted an chat session');
  }


}
