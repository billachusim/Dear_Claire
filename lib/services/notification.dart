import 'dart:convert'; // Import dart:convert for JSON encoding/decoding
import 'dart:math';

import 'package:clairediary/Automations/setup_autoDiary_widget.dart';import 'package:clairediary/ui/routes/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
        if (payload == null || payload.isEmpty) return;

        print('Local Notification Tapped with payload: $payload');

        // --- NEW LOGIC: Try to decode payload as JSON first ---
        try {
          final Map<String, dynamic> data = jsonDecode(payload);
          final route = data['route'] as String?;
          if (route == 'diaryRooms' || route == 'alterEgoDiaryRooms') {
            navService.pushNamed(
              '/$route',
              args: {
                'roomId': data['roomId'],
                'cornerId': data['cornerId'],
              },
            );
            return; // Handled, so we exit.
          }
        } catch (e) {
          // If it's not a JSON string, it's a simple string payload.
          print("Payload is not a JSON object, handling as simple string.");
        }

        // --- OLD LOGIC: Handle simple string payloads ---
        switch (payload) {
          case 'start_instant_auto_diary':
            print("APP: Notification tapped, invoking instantRecording.");
            final service = FlutterBackgroundService();
            service.invoke('instantRecording');
            break;
          case 'auto_diary_record':
            NavigationService.navigationKey.currentState?.push(
                MaterialPageRoute(builder: (context) => SetupAutoDiary()));
            break;
          case 'alterEgoHomepage':
            navService.pushNamed('/alterEgoHomepage');
            break;
          case 'room':
            navService.pushNamed('/diaryRooms');
            break;
          case 'wallet':
          case 'egoPage':
          case 'love_transfer_received':
          case 'love_transfer_sent':
            navService.pushNamed('/egoPage');
            break;
          case 'claireminder':
          case 'create_session':
            navService.pushNamed('/create_session');
            break;
          case 'game':
            navService.pushNamed('/games');
            break;
          default:
          // This handles notifiedSessionDetails and any other routes passed as a plain string.
            navService.pushNamed('/notifiedSessionDetails', args: payload);
        }
      },
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      String payload;
      final route = message.data["route"];

      // --- NEW LOGIC: Encode full data for diary rooms ---
      if (route == 'diaryRooms' || route == 'alterEgoDiaryRooms') {
        payload = jsonEncode(message.data); // Encode the whole map
      } else {
        payload = route ?? ''; // Use the route string for others
      }

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
        payload: payload,
      );
    });

    // When app is in background and user taps FCM notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data["route"];
      if (route != null) {
        switch (route) {
          case 'diaryRooms':
          case 'alterEgoDiaryRooms':
            navService.pushNamed(
              '/$route',
              args: {
                'roomId': message.data['roomId'],
                'cornerId': message.data['cornerId'],
              },
            );
            break;
          case 'alterEgoHomepage':
            navService.pushNamed('/alterEgoHomepage');
            break;
          case 'room':
            navService.pushNamed('/diaryRooms');
            break;
          case 'wallet':
          case 'egoPage':
          case 'love_transfer_received':
          case 'love_transfer_sent':
            navService.pushNamed('/egoPage');
            break;
          case 'claireminder':
          case 'create_session':
            navService.pushNamed('/create_session');
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
    await Future.delayed(Duration(minutes: 15), () {
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
    await Future.delayed(Duration(seconds: 15), () {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: message.toString(),
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );
    });
  }
}
