import 'dart:math';

import 'package:clairediary/Automations/setup_autoDiary_widget.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/color.dart';

class ClairNotification {
  User? currentUser = FirebaseAuth.instance.currentUser;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'socialFaculty', // id
      'Social Faculty Channel', // title
      importance: Importance.max,
      playSound: true);

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        print('Notification Tapped with payload: $payload');

        if (payload == 'auto_diary_record') {
          NavigationService.navigationKey.currentState?.push(
              MaterialPageRoute(builder: (context) => SetupAutoDiary()));
        } else if (payload != null) {
          // Your existing FCM logic
          switch (payload) {
            case 'room':
              navService.pushNamed('/diaryRooms');
              break;
            case 'wallet':
            case 'love_transfer_received': // Add this line
            case 'love_transfer_sent':
              navService.pushNamed('/egoPage');
              break;
            case 'claireminder':
            case 'createSession':
              navService.pushNamed('/createSession');
              break;
            case 'game':
              navService.pushNamed('/games');
              break;
            default:
              navService.pushNamed('/notifiedSessionDetails', args: payload);
          }
        }
      },
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      /*// Don't show notification if the sender is the current user.
      if (message.data['id'] != null &&
          message.data['id'] == FirebaseAuth.instance.currentUser?.uid) {
        return;
      }*/

      final notification = message.notification;
      final route = message.data["route"];
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: route,
        );
      }
    });

    // When app is in background and user taps FCM notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data["route"];
      if (route != null) {
          switch (route) {
            case 'room':
              navService.pushNamed('/diaryRooms');
              break;
            case 'wallet':
            case 'love_transfer_received': // Add this line
            case 'love_transfer_sent':
              navService.pushNamed('/egoPage');
              break;
            case 'claireminder':
            case 'createSession':
              navService.pushNamed('/createSession');
              break;
            case 'game':
              navService.pushNamed('/games');
              break;
            default:
              navService.pushNamed('/notifiedSessionDetails', args: route);
          }
      }
    });
  }

  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name,
            color: Pallet.colorPrimary,
            playSound: true,
            icon: '@drawable/claire_icon',
            enableLights: true,
            enableVibration: true,
            showWhen: true,
            channelShowBadge: true),
        iOS: DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true));
  }

  randomizeReminderNotes() async {
    const messages = [
      "Go on, Darling, talk to me...",
      "I'm glad you are here",
      "You have come to a safe place.",
      "Everything can be between us.",
      "I'll always be here for you.",
      "Let's have a heart to heart.",
      "Go ahead, type or record anything.",
      "Tell me what's happening, darling?",
      "Where are you and what's going on?",
      "Choose a game and let's play!",
      "A problem shared is...",
      "You are completely anonymous.",
      "Write or record anything.",
      "If you need some Loves just ask me.",
      "It's you and me time.",
      "I challenge you to a game of tic tac toe",
      "Tap record and say Dear Claire",
      "I'm ready to listen.",
      "I'm ready to read, listen and reply.",
      "If you don't tell me, I won't know.",
    ];
    final message = messages[Random().nextInt(messages.length)];
    await Future.delayed(Duration(minutes: 5), () {
      flutterLocalNotificationsPlugin.show(0, 'Claireminder',
          message.toString(), _notificationDetails(),
          payload: message.contains("game") ? "game" : "claireminder");
    });
  }

  randomizeNewAppSessionToast() async {
    const messages = [
      "It's Claire O'clock!",
      "I'm glad you are here",
      "You have come to a safe place.",
      "Grow your ego.",
      "Shake your phone to switch ego..",
      "Let's have a heart to heart.",
      "Go ahead, advise anonymously.",
      "Welcome to Featured Sessions",
      "Different people, different situations.",
      "Shake device to switch ego.",
      "A problem shared is...",
      "You are completely anonymous.",
      "Advise people positively.",
      "Tap the spinning flower anytime.",
      "It's you and me time.",
      "Bored? Check out Diary Rooms.",
      "Browse Love and other categories.",
      "Be ready to be nice.",
      "Ask Claire anything.",
      "Don't forget to show love.",
    ];
    final message = messages[Random().nextInt(messages.length)];
    await Future.delayed(Duration(seconds: 7), () {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: message.toString(),
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );
    });
  }
}
