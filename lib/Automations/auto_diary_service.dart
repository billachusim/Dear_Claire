import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AutoDiaryService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'auto_diary_channel', // id
      'Auto Diary Prompts', // title
      description: 'Channel for Auto Diary recording prompts.',
      importance: Importance.max,
      playSound: true);

  Future<void> init() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher', // Using the default app icon
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ));
  }

  String _getRandomMessage() {
    const messages = [
      "Go on, Darling, talk to me...",
      "I'm glad you are here.",
      "You have come to a safe place.",
      "Everything can be between us.",
      "I'll always be here for you.",
      "Let's have a heart to heart.",
      "Go ahead, record anything.",
      "Tell me what's happening, darling?",
      "Where are you and what's going on?",
      "A problem shared is...",
      "You are completely anonymous here.",
      "It's you and me time.",
      "Tap here and say 'Dear Claire'.",
      "I'm ready to listen.",
    ];
    return messages[Random().nextInt(messages.length)];
  }

  Future<void> scheduleAutoDiaryNotifications({
    required int startHour,
    required int endHour,
    int count = 5, // Schedule 5 random notifications per day
  }) async {
    // First, cancel any previously scheduled notifications
    await cancelAllNotifications();

    if (endHour <= startHour) {
      print(
          "AutoDiaryService Error: endHour must be greater than startHour. No notifications scheduled.");
      return;
    }

    final Random random = Random();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < count; i++) {
      int hour = startHour + random.nextInt(endHour - startHour);
      int minute = random.nextInt(60);

      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time is in the past for today, schedule it for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        i,
        'Claireminder',
        _getRandomMessage(),
        scheduledDate,
        _notificationDetails(),
        payload: 'auto_diary_record',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
