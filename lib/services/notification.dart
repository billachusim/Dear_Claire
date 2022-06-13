import 'dart:math';

import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/color.dart';

final ClairNotification clairNotification = ClairNotification();

Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.d('A bg message just showed up :  ${message.messageId}');
}


class ClairNotification {
  User? currentUser = FirebaseAuth.instance.currentUser;


  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotification() async {

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    triggerAndroidNotifications();

     flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
     triggerIosNotifications();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void triggerAndroidNotifications() async {

    ///Get the message user is going to tap when app is closed
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      final routeForMessage = message?.data["route"];
      if (message != null) {
        navigatorKey.currentState?.pushNamed(routeForMessage);
      }
    });

    /// Foreground work for android
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification!;
      AndroidNotification? android = message.notification!.android;
      if (android != null)
      {
        flutterLocalNotificationsPlugin.show(notification.hashCode,
            notification.title, notification.body, _notificationDetails());
      }
    });

    /// When android app is open in background and user taps on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('You tapped on a new notification');
      RemoteNotification? notification = message.notification!;
      AndroidNotification? android = message.notification!.android;
      final routeForMessage = message.data["route"];
      if (notification != null && android != null) {

        logger.d(notification.toString());
        print(routeForMessage);

        navigatorKey.currentState?.pushNamed(routeForMessage);

      }
    });
  }


  void triggerIosNotifications() async {
    String? _usersID = currentUser?.uid.toString();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.instance.requestPermission().then((value) {
      print(value);});
    FirebaseMessaging.instance.getToken().then((token){
      print(token);});
    FirebaseMessaging.instance.getAPNSToken().then((APNStoken){
      print(APNStoken);});

    /// Foreground work for iOS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification!;
      AppleNotification? apple = message.notification!.apple;
      if (apple != null)
      {
        flutterLocalNotificationsPlugin.show(notification.hashCode,
            notification.title, notification.body, _notificationDetails());
      }
    });

    /// When iOS app is open in background and user taps on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('You tapped on a new notification!');
      RemoteNotification? notification = message.notification;
      AppleNotification? apple = message.notification?.apple;
      if (notification != null && apple != null) {
        logger.d(notification.toString());
      }
    });
  }


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
    await  Future.delayed(Duration(days: 2), () {
      flutterLocalNotificationsPlugin.show(0, 'Claireminder',
          message.toString(), _notificationDetails());
    }
    );
  }



  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name, channel.description,
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
