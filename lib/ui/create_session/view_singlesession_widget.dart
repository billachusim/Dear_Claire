import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/create_session/session_details_widget.dart';
import 'package:clairediary/ui/create_session/session_model.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/comment_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../utils/strings.dart';
import '../featured/model/session.dart';

class SessionPostDetailsScreen extends StatefulWidget {
  CreateSessionModel? sessionModel;

  SessionPostDetailsScreen({Key? key, required this.sessionModel})
      : super(key: key);

  @override
  _SessionPostDetailsScreenState createState() =>
      _SessionPostDetailsScreenState(sessionModel);
}

const int maxFailedLoadAttempts = 3;

class _SessionPostDetailsScreenState
    extends State<SessionPostDetailsScreen> {
  CreateSessionModel? sessionModel;

  _SessionPostDetailsScreenState(this.sessionModel);

  List<CommentSessionModel> _commentSessionList = [];

  Session featuredSessionModel = Session();

  User? currentUser = FirebaseAuth.instance.currentUser;

  // --- ADMOB COMPLIANCE FIX 1: Add new ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;

  @override
  void initState() {
    super.initState();
    _createAdviseInterstitialAd();
  }

  @override
  void dispose() {
    // --- ADMOB COMPLIANCE FIX 2: Show interstitial on exit and dispose all ads ---
    _showAdviseInterstitialAd();
    _interstitialAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  /// Create new sub chat interstitial ad.
  void _createAdviseInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/9839548530"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/8291211887"
          : '',
      request: AdRequest(),
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

  void _showAdviseInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; // Prevent showing the same ad twice
    }
  }

  // --- ADMOB COMPLIANCE FIX 3: Clean up ad loading logic ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerAdInitialized) {
      final adState = Provider.of<AdState>(context);
      adState.initialization.then((status) {
        if (mounted) {
          // Ensure widget is still in the tree
          setState(() {
            _bottomBannerAd = BannerAd(
                size: AdSize.banner,
                adUnitId: adState.egoModeBottomCommentBannerAdUnitId,
                request: const AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) =>
                      print('Session post details banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print(
                        'Session post details banner failed to load: $error');
                    ad.dispose();
                  },
                ))
              ..load();
            _isBannerAdInitialized = true;
          });
        }
      });
    }
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
      // --- ADMOB COMPLIANCE FIX 4: Restructure the body with a Stack ---
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
              SessionDetailsWidget(
                singleSessionModel: sessionModel,
              ),
              StreamBuilder(
                  stream: firebaseServices
                      .getFeaturedSessionsComments(sessionModel!.sessionId!),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                    if (snapShot.hasData) {
                      _commentSessionList.clear(); // Clear list before populating
                      snapShot.data!.docs
                          .map((e) => _commentSessionList
                          .add(CommentSessionModel.fromJson(e.data() as Map<String, dynamic>))) // Use e.data()
                          .toList();
                      // --- ADMOB COMPLIANCE FIX 5: Remove ads from the Column ---
                      return Column(
                        children: [
                          // Top ad unit REMOVED
                          ..._commentSessionList
                              .map((element) => CommentWidget(
                            commentSessionModel: element,
                            featuredSessionModel: featuredSessionModel,
                            userId: '',
                          ))
                              .toList(),
                          SizedBox(
                            height: 20,
                          ),
                          // Bottom ad unit REMOVED
                        ],
                      );
                    }
                    return Container();
                  }),
              // Adjust space for the input field AND the banner ad
              SizedBox(
                height: 120,
              )
            ],
          ),
          // --- ADMOB COMPLIANCE FIX 6: Place the single, compliant banner ad ---
          if (_bottomBannerAd != null && _isBannerAdInitialized)
            Positioned(
              bottom: 0, // Anchored to the bottom
              left: 0,
              right: 0,
              child: Container(
                height: _bottomBannerAd!.size.height.toDouble(),
                width: _bottomBannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bottomBannerAd!),
                alignment: Alignment.center,
              ),
            ),
        ],
      ),
    );
  }
}
