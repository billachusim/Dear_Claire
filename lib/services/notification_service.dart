import 'dart:convert';
import 'dart:io';

import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logger/logger.dart';

final NotificationService notificationService = NotificationService();

class NotificationService {
  final _projectId = 'clair-52652';

  Future<String> _getAccessToken() async {
    final serviceAccountJson = jsonDecode(
      await rootBundle.loadString('secrets/service-account.json'),
    );

    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client = await clientViaServiceAccount(credentials, [
      'https://www.googleapis.com/auth/firebase.messaging',
    ]);

    return client.credentials.accessToken.data;
  }

  /// send notifications
  Future<void> sendNotification(Map<String, dynamic> notification) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await Dio().post(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        data: {
          'message': notification,
        },
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Notification sent successfully');
      } else {
        logger.e('Failed to send notification: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        logger.e('Dio error!');
        logger.e('STATUS: ${e.response?.statusCode}');
        logger.e('DATA: ${e.response?.data}');
        logger.e('HEADERS: ${e.response?.headers}');
      } else {
        logger.e('Error sending request!');
        logger.e(e.message);
      }
    }
  }
}
