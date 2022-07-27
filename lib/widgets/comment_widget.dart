import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/play_advise_voice_note.dart';
import 'package:dear_claire/widgets/thanks_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data/notification_model.dart' as pushNotification;
import '../services/notification_service.dart';
import '../ui/featured/model/session.dart';
import '../ui/routes/page_router_animation.dart';
import '../ui/visited_user_ego_page/visited_user_ego_page.dart';
import '../utils/strings.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'custom_image_widget.dart';


class CommentWidget extends StatefulWidget {
  CommentWidget(
      {Key? key,
      this.onPressed,
      this.onShare,
      required this.commentSessionModel, required this.featuredSessionModel, required this.userId})
      : super(key: key);

  CommentSessionModel? commentSessionModel;
  final Function()? onPressed;
  final Function()? onShare;
  late String visitedUsersID;
  late String visitedEgoName;
  Session? featuredSessionModel;
  final String userId;

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  TextEditingController editAdviseController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;
  bool? isFlagged;
  String? _commentTime;

  String timeAgo() {
    final commentTime = widget.commentSessionModel?.timeCreated?.toDate();
    final _time = timeago.format(commentTime!);
    _commentTime = _time;
    return _commentTime.toString();
  }




  Future<void> editAdvise() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final advise = editAdviseController.text;
    final document = FirebaseFirestore.instance
        .collection("sessions")
        .doc(sessionId)
        .collection("comments")
        .doc(commentId);
        await document.update({
      "message": advise,
    },
    );
    logger.d('Successfully saved edited advise');
    print('EditedAdvise: $advise');
  }

  //show up when user clicks on the FAB to edit an advise
  Future<void> _showCardDialog() async {
    editAdviseController.text = widget.commentSessionModel!.message.toString();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            title: Container(
              child: Text(AppString.edit_advise_dialog_header,
                  textAlign: TextAlign.center),
            ),
            content: SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: editAdviseController,
                        minLines: 4,
                        maxLines: 200,
                        decoration: InputDecoration(
                          //border: InputBorder,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  editAdvise();
                  Navigator.of(context).pop();
                  setState(() {
                    editAdviseController.text = "";
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }



  /// Delete an Advise

  Future<void> deleteAdvise() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final collection = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection(AppString.appFeaturedSessionsComments);
    await collection.doc(commentId).delete();
    logger.d('Successfully deleted an advise');
  }


  /// Increase advise counter when user creates new comment.

  Future<void> decrementAdviseCount() async {
    final userId = widget.commentSessionModel!.userId.toString();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set({
      "adviseCount": FieldValue.increment(-1),
    },
      SetOptions(merge: true),
    );
    logger.d('Decreased advise count');
  }

  /// Increase total love count when user creates new session or comment.

  Future<void> decrementTotalLoveCount() async {
    final userId = widget.commentSessionModel!.userId.toString();
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
        'totalLoveCount': FieldValue.increment(-10),
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully decreased total love count');
  }

  /// subscribe user to a topic
  Future<void> notifyForDeletedAdvise() async {
    final userId = widget.commentSessionModel!.userId.toString();
    final sessionTitle = widget.featuredSessionModel!.title ?? '';
    final sessionId = widget.featuredSessionModel!.sessionId.toString();
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
      to: '/topics/$sessionId',
      collapseKey: 'type_a',
      data: pushNotification.Data(id: userId, route: sessionId.toString()),
      notification: pushNotification.Notification(
          title: 'Please, Be Careful.', body: 'Your advise on the session: $sessionTitle was deleted. You lost 10 Loves.'),
    );
    notificationService.sendNotification(_notificationModel.toJson());
    logger.d('Deleted an advise from this session: $sessionTitle');
  }




  /// Flag an Advise

  Future<bool?> sendToFlagged() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final value = true;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection(AppString.appFeaturedSessionsComments)
        .doc(commentId)
        .update({
      "flagged": value,
    },
    );
    logger.d('Successfully flagged a session');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }



  Future<bool?> removeFromFlagged() async {
    final sessionId = widget.featuredSessionModel!.sessionId;
    final commentId = widget.commentSessionModel!.commentId;
    final value = false;
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection(AppString.appFeaturedSessionsComments)
        .doc(commentId)
        .update({
      "flagged": value,
    },
    );
    logger.d('Successfully unflagged a session');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            AppImages.appChatBg,
          ),
          fit: BoxFit.fill,
        ),
          borderRadius: BorderRadius.circular(30), color: Pallet.colorWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  widget.visitedUsersID =
                      widget.commentSessionModel?.isUserAdmin == true
                          ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                          : widget.commentSessionModel!.userId ?? '';
                  widget.visitedEgoName =
                      widget.commentSessionModel?.isUserAdmin == true
                          ? "Claire"
                          : widget.commentSessionModel!.userNickname ?? '';
                  String thisEgoName = widget.visitedEgoName;
                  String thisUser =
                      widget.commentSessionModel?.isUserAdmin == true
                          ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                          : widget.commentSessionModel!.userId ?? '';
                  PageRouter.gotoWidget(
                      VisitedUserEgoProfilePage(
                          visitedUsersID: thisUser,
                          visitedEgoName: thisEgoName),
                      context);
                  print("Visited User ID::: $thisEgoName");
                },
                child: CachedNetworkImage(
                    width: 40,
                    height: 40,
                    imageUrl: widget.commentSessionModel?.isUserAdmin == true
                        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
                        : widget.commentSessionModel!.userAvatarUrl ?? '',
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
                          width: 40,
                          height: 40,
                        ) //Icon(Icons.error),
                    ),
              ),
              SizedBox(
                width: 4,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.visitedUsersID =
                            widget.commentSessionModel?.isUserAdmin == true
                                ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                                : widget.commentSessionModel!.userId ?? '';
                        widget.visitedEgoName =
                            widget.commentSessionModel?.isUserAdmin == true
                                ? "Lol, yes, it's me, Claire!"
                                : widget.commentSessionModel!.userNickname ??
                                    '';
                        String thisEgoName = widget.visitedEgoName;
                        String thisUser =
                            widget.commentSessionModel?.isUserAdmin == true
                                ? "PbRuh3FmtESK57j3PM1Tc9RvPKh2"
                                : widget.commentSessionModel!.userId ?? '';
                        PageRouter.gotoWidget(
                            VisitedUserEgoProfilePage(
                                visitedUsersID: thisUser,
                                visitedEgoName: thisEgoName),
                            context);
                        print("Visited User ID::: $thisEgoName");
                      },
                      child: Text(
                          widget.commentSessionModel?.isUserAdmin == true
                              ? "Claire"
                              : widget.commentSessionModel!.userNickname ?? '',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: Pallet.colorBlack,
                              fontWeight: FontWeight.w800)),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                        timeAgo(),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 11.0,
                            color: Pallet.colorGrey,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThanksButton(
                    count: widget.commentSessionModel!.thanks!.length,
                    onPressed: widget.onPressed,
                    color: 1 == 2 ? Pallet.colorPrimaryDark : Pallet.colorTextGray,
                  ),

                  SizedBox(width: 3,),

                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUser?.uid)
                        .get(),
                    builder: (_, snapshot) {
                      if (snapshot.hasData) {
                        var data = snapshot.data!.data();
                        var userType = data?["userType"] ?? "0";

                        return Visibility(
                          visible: userType == "SUPER_ADMIN",
                          child: Text(widget.commentSessionModel!.alterEgoId!,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorSecondaryDark,
                                  fontWeight: FontWeight.w800)),
                        );
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 1,
          ),
          Text(
            widget.commentSessionModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 15.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),

          Visibility(
            visible: widget.commentSessionModel!.audioUrl! != 'null',
            child: Container(
              alignment: Alignment.topLeft,
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    widget.commentSessionModel!.audioUrl!.isNotEmpty
                        ? PlayAdviseVoiceNote(
                            filePath: widget.commentSessionModel!.audioUrl)
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Visibility(
                      visible: widget.commentSessionModel!.image1!.isNotEmpty,
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: widget
                              .commentSessionModel!.image1!), context);
                        },
                        child: CachedNetworkImage(
                            height: 85,
                            width: 70,
                            imageUrl: widget
                                    .commentSessionModel!.image1!,
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
                                  "assets/images/brown_boy_mask.png",
                                  width: 48,
                                  height: 48,
                                ) //Icon(Icons.error),
                            ),
                      )),
                  SizedBox(
                    width: 5,
                  ),
                  Visibility(
                      visible: widget.commentSessionModel!.image2!.isNotEmpty,
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: widget
                              .commentSessionModel!.image2!), context);
                        },
                        child: CachedNetworkImage(
                            height: 85,
                            width: 70,
                            imageUrl: widget.commentSessionModel!.image2!,
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
                                  "assets/images/brown_boy_mask.png",
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
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [

                if (widget.commentSessionModel!.isUserAdmin)
                  GestureDetector(
                    onTap: widget.onShare,
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_rounded,
                          size: 15,
                          color: Pallet.colorSecondary,
                        ),
                        Text(
                          'Share',
                          style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Pallet.colorSecondary,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),


                  Visibility(
                    visible: widget.commentSessionModel?.flagged == true,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.userId == currentUser?.uid)
                          showCustomDialog(context,
                              message: AppString.delete_advise_alert_note,
                              onPressed: () {
                                PageRouter.goBack(context);
                                deleteAdvise();
                                decrementAdviseCount();
                                decrementTotalLoveCount();
                                notifyForDeletedAdvise();
                              });
                        },
                      child: Visibility(
                        visible: widget.userId == currentUser?.uid,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_forever_rounded,
                              color: Pallet.colorPrimaryDark,
                              size: 15,
                            ),
                            Text(
                              'Delete',
                              style: GoogleFonts.lato(
                                  fontSize: 11.0,
                                  color: Pallet.colorPrimaryDark,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                    SizedBox(width: 5,),

                    if (widget.commentSessionModel!.userId == currentUser?.uid)
                      GestureDetector(
                        onTap: _showCardDialog,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 15,
                              color: Pallet.colorPrimaryDark,
                            ),
                            Text(
                              'Edit',
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorPrimaryDark,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
              ]
              ),

              Spacer(flex: 1,),


              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  if (widget.commentSessionModel!.isUserAdmin != true)
                    GestureDetector(
                      onTap: () {
                        if (widget.commentSessionModel?.flagged == false)
                          showCustomDialog(context,
                              message: widget.commentSessionModel!.flagged == true
                                  ? AppString.unflag_advise_alert_note
                                  : AppString.flag_advise_alert_note,
                              onPressed: () {
                                PageRouter.goBack(context);
                                sendToFlagged();
                              });
                        else
                          showCustomDialog(context,
                              message: widget.commentSessionModel!.flagged == false
                                  ? AppString.flag_advise_alert_note
                                  : AppString.unflag_advise_alert_note,
                              onPressed: () {
                                PageRouter.goBack(context);
                                removeFromFlagged();
                              });
                      },
                      child: Row(
                        children: [
                          Icon(
                            widget.commentSessionModel!.flagged == true
                                ? Icons.flag
                                : Icons.flag_outlined,
                            color: Pallet.colorPrimary,
                            size: 15,
                          ),
                          Text(
                            'Flag',
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorPrimary,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(width: 5,),

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
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (currentUser == null) {
                                      Navigator.of(context)
                                          .pushReplacementNamed(AppRoutes.authSelection);
                                    } else {
                                      _showCardDialog();
                                    }
                                  },
                                  child: Row(
                                    children: [

                                      Icon(
                                        Icons.edit,
                                        size: 15,
                                        color: Pallet.colorSecondary,
                                      ),

                                      Text(
                                        'Mod',
                                        style: GoogleFonts.lato(
                                            fontSize: 12.0,
                                            color: Pallet.colorSecondary,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 4,),

                                Visibility(
                                  visible: widget.commentSessionModel?.flagged == true,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (currentUser == null) {
                                        Navigator.of(context)
                                            .pushReplacementNamed(AppRoutes.authSelection);
                                      } else {
                                        showCustomDialog(context,
                                            message: AppString.delete_advise_alert_note,
                                            onPressed: () {
                                              PageRouter.goBack(context);
                                              deleteAdvise();
                                              decrementAdviseCount();
                                              decrementTotalLoveCount();
                                              notifyForDeletedAdvise();
                                            });
                                      }
                                      },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_forever_rounded,
                                          color: Pallet.colorSecondary,
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                      }

                      return Container();
                    },
                  ),
                ],
              ),

            ],
          ),

          SizedBox(height: 6,),
        ],
      ),
    );
  }
}
