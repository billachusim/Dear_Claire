import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../widgets/toast.dart';

class EditClairevatar extends StatefulWidget {
  final Function(String) onAvatarChanged;

  const EditClairevatar({Key? key, required this.onAvatarChanged}) : super(key: key);

  @override
  _EditClairevatarState createState() => _EditClairevatarState();
}

const int maxFailedLoadAttempts = 3;

class _EditClairevatarState extends State<EditClairevatar> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  late String avatarUrl;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }

  /// Query Clairevatars from Firestore
  final Stream<QuerySnapshot> _clairevatarGrid =
  FirebaseFirestore.instance.collection('claire_vartar').snapshots();

  /// Get user's Clairevatar
  Future<String?> getUserClairevatar() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(currentUser?.uid)
        .get();
    if (response.exists) {
      var user = UserModel.fromFirestore(response.data() as Map<String, dynamic>);
      logger.d('Successfully got the clairevatar');
      print('avatarUrl is: ${user.avatarUrl}');
      return user.avatarUrl;
    }
    return null;
  }

  /// Change user's Clairevatar
  Future<void> changeClairevatar() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
      "avatarUrl": avatarUrl,
    });
    logger.d('Successfully saved new clairevatar');
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  // Create interstitial ad.
  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/4264541851"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/9032269917"
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
            _createInterstitialAd();
          }
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16,
          bottom: 16,
          top: 20,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: EdgeInsets.only(top: 20, bottom: 10),
                child: GestureDetector(
                    onTap: () {
                      print("Clicking on X");
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset(
                      "assets/images/ic_close.svg",
                      width: 17.0,
                      height: 17.0,
                    )),
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Choose A New Clairevatar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Pallet.colorWhite,
                    ),
                  ),
                  Text(
                    '(Express your ego)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Pallet.colorWhite,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _clairevatarGrid,
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading");
                  }

                  return GridView.count(
                    crossAxisCount: 5,
                    physics: AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    children: snapshot.data!.docs.map<Widget>((DocumentSnapshot document) {
                      final data = document.data() as Map<String, dynamic>?;
                      final imageUrl = data?['imageUrl'] as String?;

                      return GestureDetector(
                        onTap: () {
                          if (imageUrl != null) {
                            avatarUrl = imageUrl;
                            changeClairevatar().then((_) {
                              widget.onAvatarChanged(avatarUrl);
                              Navigator.pop(context);
                            });
                            Future.delayed(Duration(seconds: 1), () {
                              _showInterstitialAd();
                            });
                            showToast(AppString.nice_clairevatar);
                          }
                        },
                        child: ClipOval(
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? CachedNetworkImage(
                            width: 20,
                            height: 20,
                            imageUrl: imageUrl,
                            imageBuilder: (context, imageProvider) => Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                              width: 20,
                              height: 20,
                            ),
                          )
                              : Image.asset(
                            "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
