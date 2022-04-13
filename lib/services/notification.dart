import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ClairNotification clairNotification = ClairNotification();

class ClairNotification {
  User? currentUser = FirebaseAuth.instance.currentUser;

  SharedPreferences? _prefs;

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    logger.d('A bg message just showed up :  ${message.messageId}');
  }

  Future<void> initializeNotification() async {
    _prefs = await SharedPreferences.getInstance();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void triggerNotifications() async {
    String _usersID = currentUser!.uid;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification!;
      AndroidNotification? android = message.notification!.android;
      if (android != null && _usersID != message.data['id']) {
        flutterLocalNotificationsPlugin.show(notification.hashCode,
            notification.title, notification.body, _notificationDetails());
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('A new onMessageOpenedApp event was published!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        logger.d(notification.toString());
      }
    });
  }

  void triggerReminder() async {
    if (_itsTime()) {
      flutterLocalNotificationsPlugin.show(0, 'Claireminder',
          'Erm, what\'s happening there/?', _notificationDetails());
      return;
    }
    await _prefs!.setString('reminder', DateTime.now().toString());
  }

  bool _itsTime() {
    if (_prefs!.containsKey('reminder')) {
      String _cachedTime =
          _prefs!.getString('reminder') ?? DateTime.now().toString();
      DateTime _dateTime = DateTime.parse(_cachedTime);

      final _difference = DateTime.now().difference(_dateTime);

      if (_difference.inDays == 3) {
        return true;
      }
    }
    return false;
  }

  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name, channel.description,
            color: Colors.blue,
            playSound: true,
            icon: '@drawable/claire_icon',
            enableLights: true,
            enableVibration: true,
            showWhen: true,
            channelShowBadge: true),
        iOS: IOSNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true));
  }
}
