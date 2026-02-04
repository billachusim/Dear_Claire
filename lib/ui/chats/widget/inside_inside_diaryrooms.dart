import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/chats/widget/sub_diaryroom_online_users_stream.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/firebase_services.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../../widgets/toast.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class InsideInsideChatWidget extends StatefulWidget {
  String? documentID;
  ChatModel? chatModel;
  ChatRoomPodo? chatRoomPodo;

  /// use this bool value to determine when a chat is sub chat or not
  bool? isSubChat;


  InsideInsideChatWidget(
      {Key? key,
        required this.documentID,
        required this.chatModel,
        required this.chatRoomPodo,
        this.isSubChat = false})
      : super(key: key);

  @override
  State<InsideInsideChatWidget> createState() => _InsideInsideChatWidgetState();
}

class _InsideInsideChatWidgetState extends State<InsideInsideChatWidget> {
  late String visitedUsersID;
  UserModel userModel = UserModel();
  UserModel? _currentUserModel;
  late String visitedEgoName;
  bool _isAvatarLoading = false;


  @override
  void initState() {
    super.initState();
    _updateLanguagePreference();
  }


  Future<void> _updateLanguagePreference() async {
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
              future: firebaseServices.getUserWithId(id: widget.chatModel!.userId),
              builder: (_, AsyncSnapshot<UserModel> snap) {
                if (!snap.hasData) {
                  return Container();
                }
                UserModel? _user = snap.data;
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
                      width: 6,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              // --- 2. HANDLE SELF-VISIT ---
                              if (visitingUser.userId == visitedUserId) {
                                // If visiting self, just navigate without a transaction.
                                PageRouter.gotoWidget(
                                    VisitedUserEgoProfilePage(
                                        visitedUsersID: visitedUserId,
                                        visitedEgoName: visitedEgoName),
                                    context);
                                return;
                              }

                              // --- 3. CHECK PERMISSIONS & SUFFICIENT LOVES ---
                              // Note: The permission message was slightly different, so I've used the more descriptive one from the avatar's logic.
                              if (visitingUser.userType == "REGULAR" &&
                                  visitingUser.currentLoveCount < 500) { // Changed from 50 to 500 for consistency
                                showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                                return;
                              }

                              if (visitingUser.currentLoveCount < visitCost) {
                                showToast("You need at least 1❤️ to visit a profile.");
                                return;
                              }

                              // --- 4. PERFORM THE LOVE TRANSACTION ---
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

                              // --- 5. NAVIGATE ON SUCCESS ---
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
                            child: Text(_user.nickname ?? '',
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: GoogleFonts.lato(
                                    fontSize: 17.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w800)),
                          ),
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
                fontSize: 17.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.bold),
          ),


          _buildImageGrid(context),


          Visibility(
            visible: widget.chatModel?.audioUrl != '',
            child: Container(
              child: PlayAdviseVoiceNote(filePath: widget.chatModel!.audioUrl),
            ),
          ),

          SizedBox(
            height: 2,
          ),

          Row(
            children: [

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                  child: OnlineRoomVisitorsStream(roomData: widget.chatRoomPodo!, roomModel: widget.chatModel!, docId: widget.documentID!,)),

              Spacer(flex: 1,),

              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                    padding: EdgeInsets.all(5),
                    width: 110,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                          color: _isCompleted(widget.chatModel, widget.chatRoomPodo)
                              ? Pallet.blueGreyBgColor
                              : Pallet.colorSplashScreen),
                      gradient: LinearGradient(
                        begin: Alignment(
                            -0.37857140550652835, -1.9473685559777252),
                        end: Alignment(1.2428571464417884, 2.526316110739735),
                        stops: [0.0, 0.856177031993866, 1.0],
                        colors: [
                          Colors.white70,
                          Pallet.colorPrimary,
                          Pallet.colorSecondaryDark,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.chatModel!.members!.length} Online',
                        style: TextStyle(
                            color: _isCompleted(widget.chatModel, widget.chatRoomPodo)
                                ? Pallet.blueGreyBgColor
                                : Pallet.colorSplashScreen),
                      ),
                    )),
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
