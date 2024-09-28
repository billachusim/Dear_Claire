// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/firebase_services.dart';
import '../../utils/color.dart';
import '../routes/routes.dart';

class TicTacToe extends StatefulWidget {
  const TicTacToe({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TicTacToeState();
  }
}

const int maxFailedLoadAttempts = 3;


class _TicTacToeState extends State<TicTacToe> {
  late WebViewController _webViewController;
  String filePath = 'assets/web_games/tictactoe/index2.html';
  bool isWon = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();




  @override
  void initState() {
    super.initState();
    _createTictactoeInterstitialAd();
  }



  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }


  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  /// Create new tictactoe interstitial ad.

  void _createTictactoeInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/6838873265" :
      Platform.isIOS? "ca-app-pub-2404156870680632/9286456091" :
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
          _createTictactoeInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createTictactoeInterstitialAd();
        },
      );
      _interstitialAd!.show();
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
            channelShowBadge: true),
        iOS: IOSNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true));
  }

  /// Increase total love count when user wins on tic tac toe.

  Future<void> incrementTotalLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'totalLoveCount': FieldValue.increment(10),
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully increased total love count');
    print('Session Count is: $FieldValue');

    flutterLocalNotificationsPlugin.show(0, 'ClaireLove Wallet',
        "Nice, you won me on Tic tac toe. 10 Loves for you.", _notificationDetails(), payload: "wallet");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: '',
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: Set.from([
          JavascriptChannel(
              name: 'Score',
              onMessageReceived: (JavascriptMessage message){
                Fluttertoast.showToast(msg: message.message);
                isWon = true;
                Future.delayed(Duration(seconds: 5), () {
                  _showTictactoeInterstitialAd();
                  incrementTotalLoveCount();
                });
                            })
        ]),
        onWebViewCreated: (WebViewController webViewController) {
          _webViewController = webViewController;
          _loadHtmlFromAssets();
        },
      ),
    );
  }

  _loadHtmlFromAssets() async {
    String fileHtmlContents = await rootBundle.loadString(filePath);
    _webViewController.loadUrl(Uri.dataFromString(fileHtmlContents,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }
}
