import 'dart:io';

import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dio/dio.dart';

final NotificationService notificationService = NotificationService();

class NotificationService {
  /// send notifications
  Future<void> sendNotification(Map map) async {
    try {
       await Dio().post('https://fcm.googleapis.com/fcm/send',
          data: map,
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: AppString.firebaseToken,
          }));
    } catch (e) {
      logger.e(e);
    }
  }
}
