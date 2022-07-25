import 'dart:math';

import 'package:dear_claire/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../utils/color.dart';

final ClairNotification clairNotification = ClairNotification();



class ClairNotification {
  User? currentUser = FirebaseAuth.instance.currentUser;


  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'socialFaculty', // id
      'Social Faculty Channel', // title
      importance: Importance.max,
      playSound: true);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();



  randomizeReminderNotes() async {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1 ? "Go on, Darling, talk to me..." :
    randomNumber == 2 ? "I'm glad you are here" :
    randomNumber == 3 ? "You have come to a safe place." :
    randomNumber == 4 ? "Everything can be between us." :
    randomNumber == 5 ? "I'll always be here for you." :
    randomNumber == 5 ? "Let's have a heart to heart." :
    randomNumber == 6 ? "Go ahead, type or record anything." :
    randomNumber == 7 ? "Tell me what's happening, darling?" :
    randomNumber == 8 ? "Where are you and what's going on?" :
    randomNumber == 9 ? "You'll never be not truly loved." :
    randomNumber == 10 ? "A problem shared is..." :
    randomNumber == 11 ? "You are completely anonymous." :
    randomNumber == 12 ? "Write or record anything." :
    randomNumber == 13 ? "Tap the spinning flower after." :
    randomNumber == 14 ? "It's you and me time." :
    randomNumber == 15 ? "Start with Dear Claire" :
    randomNumber == 16 ? "Tap record and say Dear Claire" :
    randomNumber == 17 ? "I'm ready to listen." :
    randomNumber == 18 ? "I'm ready to read, listen and reply." :
    randomNumber == 19 ? "If you don't tell me, I won't know." :

    "Go on, Darling, talk to me...";
    await  Future.delayed(Duration(hours: 23), () {
      flutterLocalNotificationsPlugin.show(0, 'Claireminder',
          message.toString(), _notificationDetails());
    }
    );
  }


  randomizeNewAppSessionToast() async {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1 ? "It's Claire O'clock!" :
    randomNumber == 2 ? "I'm glad you are here" :
    randomNumber == 3 ? "You have come to a safe place." :
    randomNumber == 4 ? "Grow your ego." :
    randomNumber == 5 ? "Shake your phone to switch ego.." :
    randomNumber == 5 ? "Let's have a heart to heart." :
    randomNumber == 6 ? "Go ahead, advise anonymously." :
    randomNumber == 7 ? "Welcome to Featured Sessions" :
    randomNumber == 8 ? "Different people, different situations." :
    randomNumber == 9 ? "Shake device to switch ego." :
    randomNumber == 10 ? "A problem shared is..." :
    randomNumber == 11 ? "You are completely anonymous." :
    randomNumber == 12 ? "Advise people positively." :
    randomNumber == 13 ? "Tap the spinning flower anytime." :
    randomNumber == 14 ? "It's you and me time." :
    randomNumber == 15 ? "Bored? Check out Diary Rooms." :
    randomNumber == 16 ? "Browse Love and other categories." :
    randomNumber == 17 ? "Be ready to be nice." :
    randomNumber == 18 ? "Ask Claire anything." :
    randomNumber == 0 ? "Don't forget to show love." :

    "It's Claire O'Clock!";
    await  Future.delayed(Duration(seconds: 7), () {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: message.toString(),
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );    });
  }



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
}
