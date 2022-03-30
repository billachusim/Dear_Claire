import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/Admob/ad_state.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../widgets/comment_widget.dart';
import '../splash_screen/custom_rotate_bacground.dart';
import 'model/comment_session_model.dart';
import 'model/session.dart';
import 'widget/post_details_widget.dart';

class EgoModeSessionDetail extends StatefulWidget {
  var featuredSessionModel;

  EgoModeSessionDetail(
      {Key? key, required this.featuredSessionModel})
      : super(key: key);

  @override
  _EgoModeSessionDetailState createState() =>
      _EgoModeSessionDetailState(featuredSessionModel);
}

class _EgoModeSessionDetailState
    extends State<EgoModeSessionDetail> {
  Session? featuredSessionModel;

  _EgoModeSessionDetailState(this.featuredSessionModel);

  List<CommentSessionModel> _commentSessionList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;


  // Admob Ad Units.
  late BannerAd egoModeSessionDetailTopBanner;
  late BannerAd egoModeSessionDetailBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        egoModeSessionDetailTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.egoModeTopCommentBannerAdUnitId,
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
        egoModeSessionDetailBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.egoModeBottomCommentBannerAdUnitId,
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



  /// Increase advise counter when user creates new comment.

  Future<void> incrementAdviseCount() async {
    FirebaseFirestore.instance
        .collection("user_comment_counters")
        .doc(currentUser?.uid)
        .update({
      "numberOfComments": FieldValue.increment(1),
    },
    );
    logger.d('Successfully increased advise count');
    print('Session Count is: $FieldValue');

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
                      _commentSessionList.clear();

                      /// clear list
                      snapShot.data!.docs
                          .map((e) => _commentSessionList
                              .add(CommentSessionModel.fromJson(e.data())))
                          .toList();
                      return Column(

                        children: [

                          // Top ad unit is here
                          if(egoModeSessionDetailTopBanner == null)
                            SizedBox(height: 70)
                          else
                            Container(
                              height: 60,
                              child: AdWidget(ad: egoModeSessionDetailTopBanner),
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
                          if(egoModeSessionDetailBottomBanner == null)
                            SizedBox(height: 70)
                          else
                            Container(
                              height: 60,
                              child: AdWidget(ad: egoModeSessionDetailBottomBanner),
                            ),
                        ],
                      );
                    }
                    return Container();
                  }
                  ),
              SizedBox(
                height: 70,
              )
            ],
          ),
          ChatEditField(
            onTap: (String comment) =>
                _sendComment(comment, featuredSessionModel!),
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
        isUserAdmin: false,
        message: comment,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname:  _userModel.nickname);

    firebaseServices.addComment(
        title: session.title ?? '',
        docId: session.sessionId!,
        sender: _userModel.userType == 'ADMIN' ? 'Claire' :
        _userModel.userType == 'SUPER_ADMIN' ? 'Claire' :
        _userModel.nickname!,
        map: _commentModel.toJson());
    incrementAdviseCount();
  }

  void _updateReaction(
      CommentSessionModel? commentSessionModel, Session session) async {
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
              });
  }

  _share(String? message) {
    String _message = '''
    Here is an anonymous advise from Dear Claire - Secret Diary Chat:
    
     $message  
    ''';
    shareMessage(_message);
  }
}
