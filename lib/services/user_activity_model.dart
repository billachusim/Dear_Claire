import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivityModel {
  String? userActivityId;
  String? userId;
  String? clientId;
  String? clientNickname;
  String? activityMessage;
  Timestamp? dateCreated;
  String? activityType;
  String? sessionId;
  String? clientAvatarUrl;

UserActivityModel({
    this.userActivityId,
    this.userId,
    this.clientId,
    this.clientNickname,
    this.activityMessage,
    this.dateCreated,
    this.activityType,
    this.sessionId,
    this.clientAvatarUrl,
  });

  factory UserActivityModel.fromJson(dynamic json) {
    return UserActivityModel(
      userActivityId: json['userActivityId'] ?? '',
      userId: json['userId'],
      clientId: json['clientId'] ?? false,
      clientNickname: json['clientNickname'] ?? '',
      activityMessage: json['activityMessage'] ?? '',
      dateCreated: json['dateCreated'] ?? '',
      activityType: json['activityType'] ?? '',
      sessionId: json['sessionId'] ?? '',
      clientAvatarUrl: json['avatarUrl'] ?? '',
    );
  }
}
