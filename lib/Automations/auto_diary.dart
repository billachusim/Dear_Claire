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
import '../ui/create_session/session_model.dart';
import '../utils/color.dart';

/// A class to manage the auto-diary background recording functionality.
///
/// This class uses static methods to ensure a single, consistent state
/// for the audio recorder, which is crucial when the start and stop actions
/// are invoked from different events in the background service.
class AutoDiary {
  // A single, static recorder instance to be shared across start/stop calls.
  static final _audioRecorder = AudioRecorder();

  // A static variable to hold the path of the ongoing recording.
  static String? _recordedFilePath;

  /// Starts the audio recording.
  ///
  /// This method checks for microphone permission, determines a file path,
  /// and begins recording. It only handles the *start* of the process.
  static Future<void> startRecording() async {
    print('BACKGROUND: Auto Diary recording initiated.');

    try {

      // Prevent starting a new recording if one is already in progress.
      if (await _audioRecorder.isRecording()) {
        print('BACKGROUND: Already recording. Ignoring new start command.');
        return;
      }

      Directory directory = await getApplicationDocumentsDirectory();
      _recordedFilePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording to the specified path with aacLc encoder for good compatibility.
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordedFilePath!,
      );

      print('BACKGROUND: Recording started. Path: $_recordedFilePath');
    } catch (e) {
      print('BACKGROUND: An error occurred during startRecording: $e');
    }
  }

  /// Stops the audio recording and processes the file.
  ///
  /// This method stops the recording, retrieves the final file path,
  /// and then calls the method to upload the file and create a diary entry.
  static Future<void> stopRecording() async {
    print('BACKGROUND: Stopping recording...');
    try {
      if (!await _audioRecorder.isRecording()) {
        print('BACKGROUND: Stop command received, but not currently recording.');
        // If there's a stray file path, clear it.
        _recordedFilePath = null;
        return;
      }

      // Stop the recording. The path of the finished file is returned.
      final String? path = await _audioRecorder.stop();

      print('BACKGROUND: Recording stopped.');

      if (path != null && path.isNotEmpty) {
        // The primary flow: use the path returned by the stop() method.
        await saveAndSendAutoDiary(path);
      } else if (_recordedFilePath != null) {
        // A fallback: if stop() returns null, use the path saved when we started.
        print('BACKGROUND: Fallback - Using initially stored file path.');
        await saveAndSendAutoDiary(_recordedFilePath!);
      } else {
        print('BACKGROUND: Recording failed, file path is not available.');
      }
    } catch (e) {
      print('BACKGROUND: An error occurred during stopRecording: $e');
    } finally {
      // Clear the path for the next session.
      _recordedFilePath = null;
    }
  }

  /// Uploads the recorded audio file and creates a Firestore document.
  static Future<void> saveAndSendAutoDiary(String recordedFilePath) async {
    print('BACKGROUND: Preparing to save and send auto diary from path: $recordedFilePath');

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
      // Optional: Delete the local file after successful upload to save space.
      // await recordFile.delete();
    } else {
      print('BACKGROUND: Error - Recorded file not found at path: $recordedFilePath');
      return; // Can't proceed if there's no file.
    }

    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = "Auto Diary";
    sessionObject.private = false;
    sessionObject.repliesEnabled = true;
    sessionObject.message = "This diary entry was recorded automatically by Claire.";
    sessionObject.colorHex = "#6200EA";
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId = 0;
    sessionObject.location = '#AutoDiary';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessful = await _firebaseServices.createSession(session: sessionObject);

    if (isSuccessful) {
      print('BACKGROUND: Firestore session created successfully.');
      _firebaseServices.subscribeToYourSession(
          userModel.nickname.toString(), sessionObject);
    } else {
      print('BACKGROUND: Failed to create Firestore session.');
    }
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
