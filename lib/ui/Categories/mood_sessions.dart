import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../utils/strings.dart';
import '../featured/model/session.dart';
import '../../widgets/ego_mode_session_card.dart';
import '../../utils/mood.dart';
import '../routes/routes.dart';

class MoodSessions extends StatefulWidget {
  final int sessionMood;

  MoodSessions({Key? key, required this.sessionMood}) : super(key: key);

  @override
  State<MoodSessions> createState() => _MoodSessionsState();
}

class _MoodSessionsState extends State<MoodSessions> {
  List<Session>? _sessionList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;

  // --- ADMOB COMPLIANCE FIX 1: Add new ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;

  /// Get sessions from the category and have been marked to receive public replies.
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersMoodSessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("moodId", isEqualTo: widget.sessionMood)
        .where("archived", isEqualTo: false)
        .where("repliesEnabled", isEqualTo: true)
        .orderBy("timeCreated", descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // --- ADMOB COMPLIANCE FIX 2: Dispose the ad ---
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  // --- ADMOB COMPLIANCE FIX 3: Clean up ad loading logic ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerAdInitialized) {
      final adState = Provider.of<AdState>(context);
      adState.initialization.then((status) {
        if (mounted) {
          setState(() {
            _bottomBannerAd = BannerAd(
                size: AdSize.banner,
                adUnitId: adState.categorySessionTopBannerAdUnitId, // You can use any of your banner IDs
                request: AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) => print('Mood sessions banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print('Mood sessions banner failed to load: $error');
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
    return Material(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Pallet.colorPrimaryDark,
          title: Row(
            children: [
              Text(
                Mood.getMood(widget.sessionMood).toString(),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(
                flex: 1,
              ),
              StreamBuilder(
                  stream: getUsersMoodSessions(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                    if (snapShot.hasError) {
                      return Container();
                    }
                    if (snapShot.hasData) {
                      return Text(
                        snapShot.data!.docs.length.toString() + "+ Sessions 🔥",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      );
                    }
                    return Container();
                  }),
            ],
          ),
        ),
        // --- ADMOB COMPLIANCE FIX 4: Restructure body with a Stack ---
        body: Stack(
          children: [
            StreamBuilder(
              stream: getUsersMoodSessions(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return RotateImage(70, 70);
                }
                if (!session.hasData || session.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No Session data",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 15.0,
                            color: Pallet.colorBlack,
                            fontWeight: FontWeight.w600)),
                  );
                }
                if (session.hasData) {
                  // clear list
                  _sessionList!.clear();

                  session.data!.docs.map((e) {
                    _sessionList!.add(Session.fromJson(e.data() as Map<String, dynamic>));
                  }).toList();

                  return Scrollbar(
                    child: ListView(
                      children: [
                        // --- ADMOB COMPLIANCE FIX 5: Remove ad from dynamic list ---
                        // Top ad unit has been removed from here

                        ..._sessionList!
                            .map((element) => EgoModeSessionCard(
                          element: element,
                          visitedUsersID: '',
                          visitedEgoName: '',
                        ))
                            .toList(),

                        // Add space at the bottom for the ad and FAB
                        SizedBox(height: 140),
                      ],
                    ),
                  );
                }
                return Container();
              },
            ),
            // --- ADMOB COMPLIANCE FIX 6: Place a single, compliant banner ad ---
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
        floatingActionButton: FloatingActionButton(
          heroTag: "moodSession",
          backgroundColor: Pallet.colorSplashScreen,
          onPressed: () {
            if (currentUser == null) {
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.authSelection);
            } else {
              Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
            }
          },
          tooltip: 'Send or Save',
          child: RotateImage(45, 45),
        ),
      ),
    );
  }
}
