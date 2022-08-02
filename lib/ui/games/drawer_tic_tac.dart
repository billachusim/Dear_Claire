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
import '../../utils/helper.dart';
import '../routes/routes.dart';

class TicTacToe extends StatefulWidget {
  const TicTacToe({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TicTacToeState();
  }
}

class _TicTacToeState extends State<TicTacToe> {
  late WebViewController _webViewController;
  String filePath = 'assets/web_games/tictactoe/index2.html';
  bool isWon = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();




  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }



  @override
  void dispose() {
    super.dispose();
    _rewardedAd?.dispose();
  }


  RewardedAd? _rewardedAd;
  /// Show rewarded ad when user wins tictactoe
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/4046562117" :
      Platform.isIOS? "ca-app-pub-2404156870680632/7411092050" :
      '',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAd = null;
              });
              _loadRewardedAd();
            },
          );

          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
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
                if (message.message != null) {
                  isWon = true;
                  Future.delayed(Duration(seconds: 4), () {
                    showCustomDialog(context,
                      message: "Great Win!\n"
                          "Watch an Ad to claim 10 Loves.",
                      onPressed: () {
                        Navigator.pop(context);
                        _rewardedAd?.show(
                          onUserEarnedReward: (_, reward) {
                            incrementTotalLoveCount();
                          },
                        );
                      },
                    );
                  });
                }
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
