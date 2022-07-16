import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../ui/routes/routes.dart';

class LocalNotificationService{
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void initialize(BuildContext context){

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: AndroidInitializationSettings("@drawable/claire_icon"),
        iOS: IOSInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        ),
    );


    _notificationsPlugin.initialize(initializationSettings, onSelectNotification: (String? payload) async {
      if(payload != null){
        navService.pushNamed('/postDetailsWidget', args: payload);
      }
    });
  }

  static void display(RemoteMessage message) async {

    final id = DateTime.now().millisecondsSinceEpoch ~/1000;

    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        "socialFaculty",
        "Social Faculty Channel",
        importance: Importance.max,
        priority: Priority.high,
      )
    );

    _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data["route"],
    );
  }
}