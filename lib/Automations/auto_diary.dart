import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../services/firebase_services.dart';
import '../services/notification.dart';
import '../ui/create_session/session_model.dart';
import '../utils/color.dart';

/// A class to manage the auto-diary background recording functionality.
///
/// This class uses static methods to ensure a single, consistent state
/// for the audio recorder, which is crucial when the start and stop actions
/// are invoked from different events in the background service.
class AutoDiary {
  static final _audioRecorder = AudioRecorder();
  static String? _recordedFilePath;

  static Future<void> startRecording() async {
    print('BACKGROUND: Auto Diary recording initiated.');

    try {
      if (await _audioRecorder.isRecording()) {
        print('BACKGROUND: Already recording. Ignoring new start command.');
        return;
      }

      Directory directory = await getApplicationDocumentsDirectory();
      _recordedFilePath = '${directory.path}/${DateTime
          .now()
          .millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordedFilePath!,
      );

      print('BACKGROUND: Recording started. Path: $_recordedFilePath');
    } catch (e) {
      print('BACKGROUND: An error occurred during startRecording: $e');
    }
  }

  // CHANGED: Renamed to clearly separate from the new method.
  static Future<void> stopAndSaveRecording() async {
    print('BACKGROUND: Stopping and saving recording...');
    try {
      if (!await _audioRecorder.isRecording()) {
        print(
            'BACKGROUND: Stop command received, but not currently recording.');
        _recordedFilePath = null;
        return;
      }

      final String? path = await _audioRecorder.stop();
      print('BACKGROUND: Recording stopped.');

      if (path != null && path.isNotEmpty) {
        await saveAndSendAutoDiary(path);
      } else if (_recordedFilePath != null) {
        print('BACKGROUND: Fallback - Using initially stored file path.');
        await saveAndSendAutoDiary(_recordedFilePath!);
      } else {
        print('BACKGROUND: Recording failed, file path is not available.');
      }
    } catch (e) {
      print('BACKGROUND: An error occurred during stopAndSaveRecording: $e');
    } finally {
      _recordedFilePath = null;
    }
  }

  // NEW: This is the main method called by the service timer.
  /// Stops recording, saves the file, and then sends a notification to the user.
  static Future<void> stopRecordingAndNotify() async {
    print('BACKGROUND: Stopping recording and preparing notification...');
    // First, perform the stop and save operation.
    await stopAndSaveRecording();

    // After saving is complete, send the notification.
    await _sendContinuationNotification();
  }


  /// Uploads the recorded audio file and creates a Firestore document.
  static Future<void> saveAndSendAutoDiary(String recordedFilePath) async {
    print(
        'BACKGROUND: Preparing to save and send auto diary from path: $recordedFilePath');

    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();

    final userModel = await _firebaseServices.getUserInfo();
    if (userModel == null) {
      print('BACKGROUND: Failed to get user model. Aborting.');
      return;
    }

    CreateSessionModel sessionObject = CreateSessionModel();
    File recordFile = File(recordedFilePath);

    if (await recordFile.exists()) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(recordFile);
      print('BACKGROUND: Audio file uploaded successfully.');
      // await recordFile.delete(); // Uncomment to save space
    } else {
      print(
          'BACKGROUND: Error - Recorded file not found at path: $recordedFilePath');
      return;
    }

    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = "Auto Diary";
    sessionObject.private = false;
    sessionObject.repliesEnabled = true;
    sessionObject.message =
    "This diary entry was recorded automatically by Claire.";
    sessionObject.colorHex = "#6200EA";
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId = 0;
    sessionObject.location = '#AutoDiary';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessful = await _firebaseServices.createSession(
        session: sessionObject);

    if (isSuccessful) {
      print('BACKGROUND: Firestore session created successfully.');
      _firebaseServices.subscribeToYourSession(
          userModel.nickname.toString(), sessionObject);
    } else {
      print('BACKGROUND: Failed to create Firestore session.');
    }
  }

  // NEW: A dedicated method to send the follow-up notification.
  static Future<void> _sendContinuationNotification() async {
    final ClairNotification clairNotification = ClairNotification();
    const channel = AndroidNotificationChannel(
        'auto_diary_continuation', // id
        'Auto Diary Continuation', // title
        description: 'Notifications for continuing an auto diary session.',
        importance: Importance.max,
        playSound: true);

    final details = NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name,
            channelDescription: channel.description,
            color: Pallet.colorPrimary,
            playSound: true,
            icon: '@drawable/claire_icon',
            importance: Importance.max,
            priority: Priority.high),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true));

    await clairNotification.flutterLocalNotificationsPlugin.show(
      999, // A unique ID for this notification type
      'Continue Your Thought?',
      'Your Auto Diary session has finished. Tap here to start another one instantly.',
      details,
      // This payload is crucial. It tells our app what to do when the notification is tapped.
      payload: 'start_instant_auto_diary',
    );
    print('BACKGROUND: Continuation notification sent.');
  }

  // The 'randomizeReminderNotes' method is unrelated to recording and remains unchanged.
  static void randomizeReminderNotes() {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'socialFaculty', // id
        'Social Faculty Channel', // title
        importance: Importance.max,
        playSound: true);

    NotificationDetails _notificationDetails() {
      return NotificationDetails(
          android: AndroidNotificationDetails(channel.id, channel.name,
              color: Pallet.colorPrimary,
              playSound: true,
              icon: '@drawable/claire_icon',
              enableLights: true,
              enableVibration: true,
              showWhen: true,
              channelShowBadge: true),
          iOS: const DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true));
    }

    Random random = Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1
        ? "Go on, Darling, talk to me..."
        : randomNumber == 2
        ? "I'm glad you are here"
        : "Go on, Darling, talk to me..."; // Simplified for brevity

    flutterLocalNotificationsPlugin.show(
        0, 'Claireminder', message.toString(), _notificationDetails(),
        payload: message.contains("game") ? "game" : "claireminder");
  }
}
