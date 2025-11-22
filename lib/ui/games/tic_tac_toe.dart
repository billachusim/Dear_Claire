// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Admob/ad_state.dart';
import '../../utils/color.dart';

class TicTacToe extends StatefulWidget {
  const TicTacToe({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TicTacToeState();
  }
}

const int maxFailedLoadAttempts = 3;

class _TicTacToeState extends State<TicTacToe> {
  late final WebViewController _webViewController;
  String filePath = 'assets/web_games/tictactoe/index.html';
  bool isWon = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  User? currentUser = FirebaseAuth.instance.currentUser;

  // --- ADMOB COMPLIANCE FIX 1: Update ad state variables ---
  BannerAd? _bottomBannerAd;
  bool _isBannerAdInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;


  @override
  void initState() {
    super.initState();
    _createTictactoeInterstitialAd();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Score', onMessageReceived: (JavaScriptMessage message) {
        Fluttertoast.showToast(msg: message.message);
        isWon = true;
        // The interstitial ad will now be shown on exit.
        incrementTotalLoveCount();
      });

    _loadHtmlFromAssets();
  }

  @override
  void dispose() {
    // --- ADMOB COMPLIANCE FIX 2: Show ad on exit and dispose all ads ---
    if (isWon) {
      _showTictactoeInterstitialAd();
    }
    _interstitialAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  /// Create new tictactoe interstitial ad.
  void _createTictactoeInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/6838873265"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/9286456091"
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
            _createTictactoeInterstitialAd();
          }
        },
      ),
    );
  }

  void _showTictactoeInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          // Optionally load the next one
          // _createTictactoeInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          // Optionally load the next one
          // _createTictactoeInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  // --- ADMOB COMPLIANCE FIX 3: Clean up banner ad loading logic ---
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
                adUnitId: adState.tictactoeTopBannerAdUnitId, // Using your unique ID
                request: AdRequest(),
                listener: BannerAdListener(
                  onAdLoaded: (ad) => print('TicTacToe banner loaded.'),
                  onAdFailedToLoad: (ad, error) {
                    print('TicTacToe banner failed to load: $error');
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

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.high,
      playSound: true);

  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id, channel.name,
          color: Pallet.colorPrimary,
          playSound: true,
          icon: '@drawable/claire_icon',
          enableLights: true,
          enableVibration: true,
          showWhen: true,
          channelShowBadge: true,
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true));
  }

  Future<void> incrementTotalLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'totalLoveCount': FieldValue.increment(10),
      },
      SetOptions(merge: true),
    );
    flutterLocalNotificationsPlugin.show(
      0,
      'ClaireLove Wallet',
      "Nice, you won me on Tic tac toe. 10 Loves for you.",
      _notificationDetails(),
      payload: "wallet",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimary,
        title: Text(
          'Tic Tac Toe',
          style: GoogleFonts.lato(
            fontSize: 24.0,
            color: Pallet.colorWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // --- ADMOB COMPLIANCE FIX 4: Restructure body with a Stack and Column ---
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(
              controller: _webViewController,
            ),
          ),
          // --- ADMOB COMPLIANCE FIX 5: Place a single, compliant banner ad ---
          if (_bottomBannerAd != null && _isBannerAdInitialized)
            Container(
              height: _bottomBannerAd!.size.height.toDouble(),
              width: _bottomBannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bottomBannerAd!),
              alignment: Alignment.center,
            ),
        ],
      ),
    );
  }

  Future<void> _loadHtmlFromAssets() async {
    String fileHtmlContents = await rootBundle.loadString(filePath);
    final uri = Uri.dataFromString(
      fileHtmlContents,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );
    _webViewController.loadRequest(uri);
  }
}
