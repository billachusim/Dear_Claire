

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/create_session/session_details_widget.dart';
import 'package:dear_claire/ui/create_session/session_model.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/comment_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../featured/model/session.dart';



class SessionPostDetailsScreen extends StatefulWidget {

  CreateSessionModel? sessionModel;

   SessionPostDetailsScreen({Key? key, required this.sessionModel}) : super(key: key);

  @override
  _SessionPostDetailsScreenState createState() => _SessionPostDetailsScreenState(sessionModel);
}

const int maxFailedLoadAttempts = 3;

class _SessionPostDetailsScreenState extends State<SessionPostDetailsScreen> {

  CreateSessionModel? sessionModel;

  _SessionPostDetailsScreenState(this.sessionModel);

  List<CommentSessionModel> _commentSessionList = [];

  Session featuredSessionModel = Session();

  User? currentUser = FirebaseAuth.instance.currentUser;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();





  @override
  void initState() {
    super.initState();
    _createAdviseInterstitialAd();
  }



  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }


  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  /// Create new sub chat interstitial ad.

  void _createAdviseInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/9839548530" :
      Platform.isIOS? "ca-app-pub-2404156870680632/8291211887" :
      '',      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createAdviseInterstitialAd();
          }
        },
      ),
    );
  }




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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(sessionModel!.colorHex!),
        title: Text(sessionModel!.title ?? ""),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Image.asset(AppImages.appChatBg,
            height: getDeviceHeight(context),
            width: getDeviceWidth(context),
            fit: BoxFit.cover,
          ),
          ListView(
            children: [
              SessionDetailsWidget(singleSessionModel: sessionModel,),
              StreamBuilder(
                  stream: firebaseServices.getFeaturedSessionsComments(sessionModel!.sessionId!),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot){
                    if (snapShot.hasData) {
                      snapShot.data!.docs
                          .map((e) => _commentSessionList
                          .add(CommentSessionModel.fromJson(e)))
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
                              .map((element) => CommentWidget(commentSessionModel: element, featuredSessionModel: featuredSessionModel, userId: '',))
                              .toList(),

                          SizedBox(height: 20,),

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
              SizedBox(height: 70,)
            ],
          ),
        ],
      ),
    );
  }
}
