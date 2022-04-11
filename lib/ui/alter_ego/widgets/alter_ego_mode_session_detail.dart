import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/Admob/ad_state.dart';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../services/firebase_services.dart';

class AlterEgoModeSessionDetail extends StatefulWidget {
  var featuredSessionModel;

  AlterEgoModeSessionDetail({Key? key, required this.featuredSessionModel})
      : super(key: key);

  @override
  _AlterEgoModeSessionDetailState createState() =>
      _AlterEgoModeSessionDetailState(featuredSessionModel);
}

class _AlterEgoModeSessionDetailState extends State<AlterEgoModeSessionDetail> {
  Session? featuredSessionModel;

  _AlterEgoModeSessionDetailState(this.featuredSessionModel);

  List<CommentSessionModel> _commentSessionList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;



  // Admob Ad Units.
  late BannerAd alterEgoModeSessionDetailTopBanner;
  late BannerAd alterEgoModeSessionDetailBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        alterEgoModeSessionDetailTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.alterEgoModeTopCommentBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        alterEgoModeSessionDetailBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.alterEgoModeBottomCommentBannerAdUnitId,
            request: AdRequest(),
          listener: BannerAdListener(
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
            },
          )
        )..load();
      });
    });
  }

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
          CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
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
                      /// clear list before adding now items
                      _commentSessionList.clear();
                      snapShot.data!.docs
                          .map((e) => _commentSessionList
                              .add(CommentSessionModel.fromJson(e.data())))
                          .toList();
                      return Column(

                        children: [

                          // Top ad unit is here
                          if(alterEgoModeSessionDetailTopBanner == null)
                            SizedBox(height: 70)
                          else
                            Container(
                              height: 60,
                              child: AdWidget(ad: alterEgoModeSessionDetailTopBanner),
                            ),
                          ..._commentSessionList
                              .map((element) => CommentWidget(
                                    commentSessionModel: element,
                            onPressed: () => _updateReaction(
                                element, featuredSessionModel!),
                            onShare: () => _share(element.message),
                                  ))
                              .toList(),

                          // Bottom ad unit is here
                          if(alterEgoModeSessionDetailBottomBanner == null)
                            SizedBox(height: 70)
                          else
                            Container(
                              height: 60,
                              child: AdWidget(ad: alterEgoModeSessionDetailBottomBanner),
                            ),
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
        isUserAdmin: true,
        message: comment,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname: _userModel.nickname);

    firebaseServices.addComment(
        title: session.title ?? '',
        docId: session.sessionId!,
        sender: _userModel.userType == 'ADMIN'? 'Claire' :
        _userModel.userType == 'SUPER_ADMIN'? 'Claire' :
        _userModel.nickname!,
        map: _commentModel.toJson());

    updateSessionTimeLastActivity(session);
    incrementAdviseCount();
    incrementTotalLoveCount();
  }



  /// Increase advise counter when user creates new comment.

  Future<void> incrementAdviseCount() async {
    FirebaseFirestore.instance
        .collection("user_comment_counters")
        .doc(currentUser?.uid)
        .set({
      "numberOfComments": FieldValue.increment(1),
    },
      SetOptions(merge: true),

    );
    logger.d('Successfully increased advise count');
    print('Session Count is: $FieldValue');

  }

  /// Increase total love count when user creates new session or comment.

  Future<void> incrementTotalLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'totalLoveCount': FieldValue.increment(20),
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully increased total love count');
    print('Session Count is: $FieldValue');
  }

  /// Update a session's timeLastActivity when new comment is made.

  Future<void> updateSessionTimeLastActivity(Session session) async {
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId)
        .update({
      'timeLastActivity': FieldValue.serverTimestamp(),
      'respondentUserId': currentUser!.uid,
    },
    );
    logger.d('Successfully increased advise count');
    print('Session Count is: $FieldValue');

  }

  void _updateReaction(
      CommentSessionModel? commentSessionModel, Session session) async {
    if (commentSessionModel!.commentId!.isEmpty) {
      showToast('You cann\'t react to this post at this time.');
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
        });
  }

  _share(String? message) {
    String _message = '''
    And here is the advise from Claire:
    
     $message  
    ''';
    shareMessage(_message);
  }
}
