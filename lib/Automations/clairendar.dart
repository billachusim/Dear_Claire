import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:uuid/uuid.dart';

import '../services/firebase_services.dart';
import '../ui/create_session/session_model.dart';
import '../utils/color.dart';

final Clairendar clairendar = Clairendar();

class Clairendar {
  User? currentUser = FirebaseAuth.instance.currentUser;
  File? recordFile;
  //used for generating random id for each session
  var uuid = Uuid();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'socialFaculty', // id
      'Social Faculty Channel', // title
      importance: Importance.max,
      playSound: true);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void startRecording() async {
    print('RECORDING!!!');

    // Request microphone permission
    if (!(await Permission.microphone.request().isGranted)) {
      print('Microphone permission denied');
      return;
    }

    Directory directory = await getApplicationDocumentsDirectory();
    print('SAVI');

    String filepath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    print('SAVING');

    final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder.openRecorder();

    // Start recording
    await _audioRecorder.startRecorder(
      toFile: filepath,
      codec: Codec.aacADTS,
    );

    print('SAVE!!!');
    print('SAVING!!!');

    // Optional wait (if you need the delay)
    await Future.delayed(Duration(seconds: 3));
    print('WAITED!!!');

    // Stop recording
    String? recordedFile = await _audioRecorder.stopRecorder();
    print('Recording saved at: $recordedFile');

    saveAndSendAutoDiary();
    print('SAVED!!!');

    randomizeReminderNotes();
    print('SAVEDED!!!');
  }

  static void saveAndSendAutoDiary() async {
    print('SENDING!!!');
    final Uuid uuid = Uuid();
    final FirebaseServices _firebaseServices = FirebaseServices();
    final userModel = await _firebaseServices.getUserInfo();
    CreateSessionModel sessionObject = CreateSessionModel();

    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = userModel.claireminderTitle;
    sessionObject.private = false;
    sessionObject.repliesEnabled = true;
    sessionObject.message = userModel.claireminderMessage;
    sessionObject.colorHex = "#6200EA";
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId = 0;
    sessionObject.location = '#AutoDiary';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessfull =
    await _firebaseServices.createSession(session: sessionObject);

    _firebaseServices.subscribeToYourSession(
        userModel.nickname.toString(), sessionObject);
  }

  static void randomizeReminderNotes() {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'socialFaculty', // id
        'Social Faculty Channel', // title
        importance: Importance.max,
        playSound: true);

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

    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1
        ? "Go on, Darling, talk to me..."
        : randomNumber == 2
        ? "I'm glad you are here"
        : randomNumber == 3
        ? "You have come to a safe place."
        : randomNumber == 4
        ? "Everything can be between us."
        : randomNumber == 5
        ? "I'll always be here for you."
        : randomNumber == 5
        ? "Let's have a heart to heart."
        : randomNumber == 6
        ? "Go ahead, type or record anything."
        : randomNumber == 7
        ? "Tell me what's happening, darling?"
        : randomNumber == 8
        ? "Where are you and what's going on?"
        : randomNumber == 9
        ? "Choose a game and let's play!"
        : randomNumber == 10
        ? "A problem shared is..."
        : randomNumber == 11
        ? "You are completely anonymous."
        : randomNumber == 12
        ? "Write or record anything."
        : randomNumber == 13
        ? "Tap the spinning flower after."
        : randomNumber == 14
        ? "It's you and me time."
        : randomNumber ==
        15
        ? "I challenge you to a game of tic tac toe"
        : randomNumber ==
        16
        ? "Tap record and say Dear Claire"
        : randomNumber ==
        17
        ? "I'm ready to listen."
        : randomNumber == 18
        ? "I'm ready to read, listen and reply."
        : randomNumber == 19
        ? "If you don't tell me, I won't know."
        : "Go on, Darling, talk to me...";
    flutterLocalNotificationsPlugin.show(
        0, 'Claireminder', message.toString(), _notificationDetails(),
        payload: message.contains("game") ? "game" : "claireminder");
    saveAndSendAutoDiary();
  }
}
