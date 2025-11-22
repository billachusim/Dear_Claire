import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/color.dart'; // Make sure this import is correct

class Claireminder {
  // Make this method static so it can be called from the top-level callbackDispatcher
  static Future<void> randomizeReminderNotes() async {
    // 1. Initialize the plugin *inside* the background isolate.
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    // You must re-initialize the plugin here for the background isolate.
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 2. Define notification details.
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'socialFaculty', // Same channel ID as in notification.dart
      'Social Faculty Channel',
      channelDescription: 'Reminders from Claire',
      color: Pallet.colorPrimary,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentSound: true);
    final NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    // 3. Your existing message logic.
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

    // 4. Show the notification immediately. No Future.delayed!
    await flutterLocalNotificationsPlugin.show(
      0, // A static ID for the reminder notification
      'Claireminder',
      message.toString(),
      notificationDetails,
      payload: message.contains("game") ? "game" : "claireminder",
    );
  }
}

