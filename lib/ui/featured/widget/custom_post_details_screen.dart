import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/featured/widget/post_details_widget.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../Admob/ad_state.dart';
import '../../../services/firebase_services.dart';
import '../../../widgets/comment_widget.dart';
import '../../../widgets/toast.dart';
import '../model/comment_session_model.dart';

class CustomPostDetailsWidget extends StatefulWidget {
  CustomPostDetailsWidget({Key? key, required this.sessionId}) : super(key: key);
  String? sessionId;

  @override
  _CustomPostDetailsWidgetState createState() => _CustomPostDetailsWidgetState();
}

class _CustomPostDetailsWidgetState extends State<CustomPostDetailsWidget> {
  late String visitedUsersID;
  late String visitedEgoName;

  //initialize the audio record file that stores user audio record. null by default
  String? recordFile;
  Session featuredSessionModel = Session();
  List<CommentSessionModel> _commentSessionList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;





  // Admob Ad Units.
  late BannerAd customPostDetailTopBanner;
  late BannerAd customPostDetailBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        customPostDetailTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.customPostDetailTopBannerAdUnitId,
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
        customPostDetailBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.customPostDetailBottomBannerAdUnitId,
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
      backgroundColor: Pallet.colorSecondaryDark,
      body: Stack(
        children: [
          ListView(
            children: [

              Align(
                alignment:Alignment.topLeft,
                child: Row(
                  children: [
                    Container(
                      padding:EdgeInsets.only(left: 20, top:8, bottom: 8),
                      child: GestureDetector(
                          onTap: (){
                            print("Clicking on X");
                            Navigator.pop(context);
                          },
                          child: SvgPicture.asset("assets/images/ic_close.svg",
                            width: 17.0,
                            height: 17.0,
                            color: Colors.white,),
                      ),
                    ),

                    SizedBox( width: 12,),

                    Text(
                      featuredSessionModel.title ?? "This Session",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: Pallet.colorWhite,
                      ),
                    ),

                  ],
                ),
              ),


              PostDetailsWidget(
                sessionId: widget.sessionId,
              ),
              StreamBuilder(
                  stream: firebaseServices.getFeaturedSessionsComments(
                      widget.sessionId!),
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
                          if(customPostDetailTopBanner == null)
                            SizedBox(height: 70)
                          else
                            Container(
                              height: 60,
                              child: AdWidget(ad: customPostDetailTopBanner),
                            ),

                          ..._commentSessionList
                              .map((element) => CommentWidget(
                            commentSessionModel: element,
                            onPressed: () => _updateReaction(
                                element, featuredSessionModel),
                            onShare: () => _share(element.message), featuredSessionModel: featuredSessionModel, userId: '',
                          ))
                              .toList(),

                          // Bottom ad unit is here
                          if(customPostDetailBottomBanner == null)
                            SizedBox(height: 70)
                          else
                            Container(
                              height: 60,
                              child: AdWidget(ad: customPostDetailBottomBanner),
                            ),
                        ],
                      );
                    }
                    return Container();
                  }
              ),
            ],
          ),

        ],
      ),
    );
  }








  /// Increase advise counter when user creates new comment.

  Future<void> incrementAdviseCount() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser?.uid)
        .set({
      "adviseCount": FieldValue.increment(1),
    },
      SetOptions(merge: true),
    );
    logger.d('Increased advise count');
    print('Advise Count is: $FieldValue');

  }

  /// Increase total love count when user creates new session or comment.

  Future<void> incrementTotalLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'totalLoveCount': FieldValue.increment(10),
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
    },
    );
    logger.d('Successfully increased advise count');
    print('Session Count is: $FieldValue');

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
    And here is the advise from Claire:
    
     $message  
    ''';
    shareMessage(_message);
  }
}
