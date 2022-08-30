import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../services/firebase_services.dart';
import '../ui/create_session/session_model.dart';
import '../utils/color.dart';

final AutoDiary autoDiary = AutoDiary();



class AutoDiary {
  User? currentUser = FirebaseAuth.instance.currentUser;
  File? recordFile;
  final FirebaseServices _firebaseServices = FirebaseServices();
  late FlutterAudioRecorder2 _audioRecorder;
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


  Future<void> startRecording() async {
      Directory directory = await getApplicationDocumentsDirectory();
      var filepath = directory.path +
          '/' +
          DateTime.now().millisecondsSinceEpoch.toString() +
          '.aac';
      _audioRecorder =
          FlutterAudioRecorder2(filepath, audioFormat: AudioFormat.AAC);
      await _audioRecorder.initialized;
      _audioRecorder.start();
      recordFile = filepath as File?;
      //saveAndSendAutoDiary(recordFile!);
  }



  saveAndSendAutoDiary(File recordFile) async {
    userModel = await _firebaseServices.getUserInfo();
    CreateSessionModel sessionObject = CreateSessionModel();

    if (recordFile != null) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(recordFile);
    }

    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = "Auto Diary" + Timestamp.now().toString();
    sessionObject.private = false;
    sessionObject.repliesEnabled = true;
    sessionObject.message = "";
    sessionObject.colorHex = "#6200EA";
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId = 0;
    sessionObject.location = '#AutoDiary';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessfull =
    await _firebaseServices.createSession(session: sessionObject);

    _firebaseServices.subscribeToYourSession(userModel.nickname.toString(), sessionObject);

  }


  randomizeReminderNotes() {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1 ? "Go on, Darling, talk to me..." :
    randomNumber == 2 ? "I'm glad you are here" :
    randomNumber == 3 ? "You have come to a safe place." :
    randomNumber == 4 ? "Everything can be between us." :
    randomNumber == 5 ? "I'll always be here for you." :
    randomNumber == 5 ? "Let's have a heart to heart." :
    randomNumber == 6 ? "Go ahead, type or record anything." :
    randomNumber == 7 ? "Tell me what's happening, darling?" :
    randomNumber == 8 ? "Where are you and what's going on?" :
    randomNumber == 9 ? "Choose a game and let's play!" :
    randomNumber == 10 ? "A problem shared is..." :
    randomNumber == 11 ? "You are completely anonymous." :
    randomNumber == 12 ? "Write or record anything." :
    randomNumber == 13 ? "Tap the spinning flower after." :
    randomNumber == 14 ? "It's you and me time." :
    randomNumber == 15 ? "I challenge you to a game of tic tac toe" :
    randomNumber == 16 ? "Tap record and say Dear Claire" :
    randomNumber == 17 ? "I'm ready to listen." :
    randomNumber == 18 ? "I'm ready to read, listen and reply." :
    randomNumber == 19 ? "If you don't tell me, I won't know." :

    "Go on, Darling, talk to me...";
      flutterLocalNotificationsPlugin.show(0, 'Claireminder',
          message.toString(), _notificationDetails(), payload:
          message.contains("game") ? "game" : "claireminder");
  }




  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name,
            color: Pallet.colorPrimary,
            playSound: true,
            icon: '@drawable/claire_icon',
            enableLights: true,
            enableVibration: true,
            showWhen: true,
            channelShowBadge: true),
        iOS: IOSNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true));
  }
}
