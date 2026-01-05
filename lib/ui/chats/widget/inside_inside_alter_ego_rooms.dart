import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/notification_service.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/play_advise_voice_note.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';
import 'alter_ego_sub_room_online_users_stream.dart';

class InsideInsideAlterEgoChatWidget extends StatefulWidget {
  final String? documentID;
  final ChatModel? chatModel;
  final ChatRoomPodo? chatRoomPodo;
  final bool? isSubChat;

  InsideInsideAlterEgoChatWidget(
      {Key? key,
        required this.documentID,
        required this.chatModel,
        required this.chatRoomPodo,
        this.isSubChat = false})
      : super(key: key);

  @override
  _InsideInsideAlterEgoChatWidgetState createState() =>
      _InsideInsideAlterEgoChatWidgetState();
}

class _InsideInsideAlterEgoChatWidgetState
    extends State<InsideInsideAlterEgoChatWidget> {
  // --- 2. ADDED STATE VARIABLE ---
  bool _isAvatarLoading = false;

  Future<void> _handleAvatarTap(
      BuildContext context, UserModel visitedUser) async {
    setState(() {
      _isAvatarLoading = true;
    });

    try {
      final visitingUser = await firebaseServices.getUserInfo();
      final String visitedUserId = visitedUser.userId!;
      final String visitedAlterEgoName = visitedUser.alterEgoId!;
      const int visitCost = 1;

      // Handle self-visit
      if (visitingUser.userId == visitedUserId) {
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: visitedUserId,
                visitedEgoName: visitedAlterEgoName),
            context);
        return; // Exit after navigation
      }

      // Check for sufficient loves
      if (visitingUser.currentLoveCount < visitCost) {
        showToast("You need at least 1❤️ to visit an Alter Ego's profile.");
        return;
      }

      // Perform the transaction
      final bool success = await firebaseServices.transferLoveBetweenUsers(
        senderId: visitingUser.userId!,
        receiverId: visitedUserId,
        amountToSend: visitCost,
        taxAmount: 0,
        totalDebitAmount: visitCost,
        senderTransactionDesc: "1❤️ visiting ${visitedAlterEgoName}'s Alter Ego.",
        receiverTransactionDesc: "1❤️ from ${visitingUser.alterEgoId} visiting your Ego.",
        claireTransactionDesc: "Tax from an Alter Ego profile visit.",
        forProfileVisits: 1,
        fromProfileVisits: 1,
      );

      // Navigate on success
      if (success) {
        showToast("You are visiting ${visitedAlterEgoName} with a kola of 1❤️.");

        // Send notification to the visited user
        final receiverToken = visitedUser.fcmId;
        if (receiverToken != null && receiverToken.isNotEmpty) {
          await notificationService.sendNotification({
            "token": receiverToken,
            "notification": {
              "title": "Your Alter Ego profile has a visitor!",
              "body": "${visitingUser.alterEgoId ?? 'An Alter Ego'} just visited your profile with a kola of 1❤️."
            },
            "data": {
              "route": "egoPage" // Navigate them to their Alter Ego page
            }
          });
        }

        if (!mounted) return;
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: visitedUserId,
                visitedEgoName: visitedAlterEgoName),
            context);
      } else {
        showToast("Profile visit failed. Please try again.");
      }
    } catch (e) {
      print("Error during Alter Ego avatar tap: $e");
      showToast("An error occurred during profile visit.");
    } finally {
      if (mounted) {
        setState(() {
          _isAvatarLoading = false;
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
                  return Container(); // or a shimmer/loader
                }
                UserModel _user = snap.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- 3. WRAP AVATAR IN GESTUREDETECTOR & STACK ---
                    GestureDetector(
                      onTap: () => _handleAvatarTap(context, _user),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                              width: 55,
                              height: 55,
                              imageUrl: _user.avatarUrl ?? '',
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Center(child: CupertinoActivityIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 55,
                                height: 55,
                              )),
                          // --- 4. ADD LOADING OVERLAY ---
                          if (_isAvatarLoading)
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
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
                    SizedBox(width: 6),
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
                                  fontSize: 18.0,
                                  color: Pallet.colorBlack,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
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
          SizedBox(height: 6),
          // --- REST OF THE WIDGET (UNCHANGED) ---
          Text(
            widget.chatModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 17.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.bold),
          ),
          Visibility(
            visible: widget.chatModel?.audioUrl != '' && widget.chatModel?.audioUrl != null,
            child: Container(
              child: PlayAdviseVoiceNote(filePath: widget.chatModel!.audioUrl),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10, top: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Visibility(
                      visible: widget.chatModel!.image1 != '' && widget.chatModel!.image1 != null,
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(
                              CustomImageWidget(
                                  imageUrl: widget.chatModel!.image1.toString()),
                              context);
                        },
                        child: CachedNetworkImage(
                            height: 120,
                            width: 100,
                            imageUrl: widget.chatModel!.image1.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                              ),
                            ),
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 48,
                                height: 48)),
                      )),
                  SizedBox(width: 5),
                  Visibility(
                      visible: widget.chatModel!.image2 != '' && widget.chatModel!.image2 != null,
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(
                              CustomImageWidget(
                                  imageUrl: widget.chatModel!.image2.toString()),
                              context);
                        },
                        child: CachedNetworkImage(
                            height: 120,
                            width: 100,
                            imageUrl: widget.chatModel!.image2.toString(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                              ),
                            ),
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 48,
                                height: 48)),
                      )),
                ],
              ),
            ),
          ),
          SizedBox(height: 2),
          Row(
            children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AlterEgoOnlineRoomVisitorsStream(
                    roomData: widget.chatRoomPodo!,
                    roomModel: widget.chatModel!,
                    docId: widget.documentID!,
                  )),
              Spacer(flex: 1),
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
                        begin: Alignment(-0.37857140550652835, -1.9473685559777252),
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
}
