import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/featured/widget/post_details_widget.dart';
import 'package:dear_claire/ui/splash_screen/custom_rotate_bacground.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/widgets/comment_widget.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:flutter/material.dart';

class AlterEgoModeSessionDetail extends StatefulWidget {
  final Session featuredSessionModel;

  const AlterEgoModeSessionDetail({super.key, required this.featuredSessionModel});

  @override
  _AlterEgoModeSessionDetailState createState() =>
      _AlterEgoModeSessionDetailState();
}

class _AlterEgoModeSessionDetailState extends State<AlterEgoModeSessionDetail> {
  List<CommentSessionModel> _commentSessionList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(widget.featuredSessionModel.colorHex!),
        title: Text(widget.featuredSessionModel.title!),
        elevation: 0,
      ),
      body: Stack(
        children: [
          CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
          ListView(
            children: [
              PostDetailsWidget(
                sessionId: widget.featuredSessionModel.sessionId,
              ),
              StreamBuilder(
                stream: firebaseServices
                    .getFeaturedSessionsComments(widget.featuredSessionModel.sessionId!),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                  if (snapShot.hasError) {
                    return Container();
                  }

                  if (snapShot.hasData) {
                    _commentSessionList = snapShot.data!.docs
                        .map((e) => CommentSessionModel.fromJson(e.data() as Map<String, dynamic>))
                        .toList();

                    return Column(
                      children: _commentSessionList
                          .map((element) => CommentWidget(
                                commentSessionModel: element,
                                onPressed: () =>
                                    _updateReaction(element, widget.featuredSessionModel),
                                onShare: () => _share(element.message),
                              ))
                          .toList(),
                    );
                  }
                  return Container();
                },
              ),
              const SizedBox(
                height: 70,
              )
            ],
          ),
          ChatEditField(
            onTap: (String comment) =>
                _sendComment(comment, widget.featuredSessionModel),
          )
        ],
      ),
    );
  }

  void _sendComment(String comment, Session session) async {
    if (!await firebaseServices.isUserSignIn(context)) return;

    final _userModel = await firebaseServices.getUserInfo();

    final _commentModel = CommentSessionModel(
      alterEgoId: _userModel.alterEgoId,
      audioUrl: '',
      commentId: '',
      flagged: session.flagged!,
      imageUrls: [],
      isUserAdmin: true,
      message: comment,
      timeCreated: Timestamp.now(),
      userAvatarUrl: _userModel.avatarUrl,
      userId: _userModel.userId,
      userNickname: _userModel.nickname,
    );

    firebaseServices.addComment(
      title: session.title ?? '',
      docId: session.sessionId!,
      sender: _userModel.userType == 'ADMIN' ? 'Claire' : _userModel.nickname!,
      map: _commentModel.toJson(),
    );
  }

  void _updateReaction(CommentSessionModel? commentSessionModel, Session session) async {
    if (commentSessionModel!.commentId!.isEmpty) {
      showToast('You can\'t react to this post at this time.');
      return;
    }
    if (!await firebaseServices.isUserSignIn(context)) return;

    final _userModel = await firebaseServices.getUserInfo();
    firebaseServices.addThanksReaction(
      commentID: commentSessionModel.commentId!,
      docId: session.sessionId!,
      map: commentSessionModel.thanks!.contains(_userModel.userId)
          ? {
              'thanks': FieldValue.arrayRemove([_userModel.userId])
            }
          : {
              'thanks': FieldValue.arrayUnion([_userModel.userId])
            },
    );
  }

  void _share(String? message) {
    final _message = '''
    Here is an anonymous advise from Dear Claire - Secret Diary Chat:
    
     $message  
    ''';
    shareMessage(_message);
  }
}
