import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/featured/widget/post_details_widget.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/widgets/comment_widget.dart';
import 'package:flutter/material.dart';

class NewDiaryDetailsScreen extends StatefulWidget {
  var featuredSessionModel;

  NewDiaryDetailsScreen(
      {Key? key, required this.featuredSessionModel})
      : super(key: key);

  @override
  _NewDiaryDetailsScreenState createState() =>
      _NewDiaryDetailsScreenState(featuredSessionModel);
}

class _NewDiaryDetailsScreenState
    extends State<NewDiaryDetailsScreen> {
  Session? featuredSessionModel;

  _NewDiaryDetailsScreenState(this.featuredSessionModel);

  List<CommentSessionModel> _commentSessionList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(featuredSessionModel!.colorHex!),
        title: Text(featuredSessionModel!.title!),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Image.asset(
            AppImages.appChatBg,
            height: getDeviceHeight(context),
            width: getDeviceWidth(context),
            fit: BoxFit.cover,
          ),
          ListView(
            children: [
              PostDetailsWidget(
                sessionId: featuredSessionModel!.sessionId,
              ),
              StreamBuilder(
                  stream: firebaseServices.getFeaturedSessionsComments(
                      featuredSessionModel!.sessionId!),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                    if (snapShot.hasError) {
                      return Container();
                    }

                    if (snapShot.hasData) {
                      _commentSessionList.clear();

                      /// clear list
                      snapShot.data!.docs
                          .map((e) => _commentSessionList
                          .add(CommentSessionModel.fromJson(e)))
                          .toList();
                      return Column(
                        children: [
                          ..._commentSessionList
                              .map((element) => CommentWidget(
                            commentSessionModel: element,
                          ))
                              .toList(),
                        ],
                      );
                    }
                    return Container();
                  }),
              SizedBox(
                height: 70,
              )
            ],
          ),
          ChatEditField(
            onTap: (String comment, voiceNote) =>
                _sendComment(comment, voiceNote, featuredSessionModel!),
          )
        ],
      ),
    );
  }

  void _sendComment(String comment, String voiceNote, Session session) async {
    if (!await firebaseServices.isUserSignIn(context)) return;

    final _userModel = await firebaseServices.getUserInfo();

    final _commentModel = CommentSessionModel(
        alterEgoId: _userModel.alterEgoId,
        audioUrl: voiceNote,
        commentId: '',
        flagged: session.flagged!,
        imageUrls: [],
        isUserAdmin: false,
        message: comment,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname: _userModel.nickname);

    firebaseServices.addComment(
        title: session.title ?? '',
        sender: _userModel.userType == 'ADMIN' ? 'Claire' : _userModel.nickname!,
        docId: session.sessionId!, map: _commentModel.toJson());
  }
}
