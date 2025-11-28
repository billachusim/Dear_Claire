import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import '../services/firebase_services.dart';
import '../ui/create_session/session_model.dart';
import '../utils/color.dart';

// This top-level instance is not used by the static methods and can be removed
// if it has no other purpose. For background services, static is key.
final AutoDiary autoDiary = AutoDiary();

class AutoDiary {

  static Future<void> startRecording() async {
    print('BACKGROUND: Auto Diary recording initiated.');

    final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String filepath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.openRecorder();

      await _audioRecorder.startRecorder(
        toFile: filepath,
        codec: Codec.aacADTS,
      );
      print('BACKGROUND: Recording started. Will record for 15 seconds.');

      // Let's record for a fixed duration, for example, 15 seconds.
      await Future.delayed(const Duration(seconds: 15));

      final recordedFilePath = await _audioRecorder.stopRecorder();
      await _audioRecorder.closeRecorder();

      print('BACKGROUND: Recording stopped. File saved at: $recordedFilePath');

      if (recordedFilePath != null && recordedFilePath.isNotEmpty) {
        // Here is the crucial connection we made.
        await saveAndSendAutoDiary(recordedFilePath);
      } else {
        print('BACKGROUND: Recording failed, file path is null or empty.');
      }
    } catch (e) {
      print('BACKGROUND: An error occurred during recording: $e');
      if (_audioRecorder.isRecording) {
        await _audioRecorder.stopRecorder();
      }
      await _audioRecorder.closeRecorder();
    }
  }


  static Future<void> saveAndSendAutoDiary(String recordedFilePath) async {
    print('BACKGROUND: Preparing to save and send auto diary.');

    // Services and IDs must be initialized within the static method for background execution.
    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();

    // This is a critical point. `getUserInfo()` must be able to run without
    // a user interface context, which it should if it's just fetching from Firebase.
    final userModel = await _firebaseServices.getUserInfo();
    if (userModel == null) {
      print('BACKGROUND: Failed to get user model. Aborting.');
      return;
    }

    CreateSessionModel sessionObject = CreateSessionModel();
    File recordFile = File(recordedFilePath);

    // Upload the audio file to Firebase Storage.
    if (await recordFile.exists()) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(recordFile);
      print('BACKGROUND: Audio file uploaded successfully.');
    } else {
      print('BACKGROUND: Error - Recorded file not found at path: $recordedFilePath');
      sessionObject.audioUrl = ''; // Handle error case
    }

    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = "Auto Diary"; // A clear title
    sessionObject.private = false;
    sessionObject.repliesEnabled = true;
    sessionObject.message = "This diary entry was recorded automatically by Claire.";
    sessionObject.colorHex = "#6200EA";
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId = 0;
    sessionObject.location = '#AutoDiary';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessful =
    await _firebaseServices.createSession(session: sessionObject);

    if (isSuccessful) {
      print('BACKGROUND: Firestore session created successfully.');
      _firebaseServices.subscribeToYourSession(
          userModel.nickname.toString(), sessionObject);
    } else {
      print('BACKGROUND: Failed to create Firestore session.');
    }
  }

  // This function is for sending a notification, which is a separate concern
  // from recording. We'll keep it for now but won't call it from the recording flow.
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
          iOS: DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true));
    }

    Random random = new Random();
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
