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
  String? userNickname;
  String? userAvatarUrl;
  List<String>? involvedUsers;

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
    this.userNickname,
    this.userAvatarUrl,
    this.involvedUsers,
  });

  factory UserActivityModel.fromJson(dynamic json) {
    return UserActivityModel(
      userActivityId: json['userActivityId'],
      userId: json['userId'],
      clientId: json['clientId'],
      clientNickname: json['clientNickname'],
      activityMessage: json['activityMessage'],
      dateCreated: json['dateCreated'],
      activityType: json['activityType'],
      sessionId: json['sessionId'],
      clientAvatarUrl: json['clientAvatarUrl'], // Corrected this from 'avatarUrl'
      userNickname: json['userNickname'],
      userAvatarUrl: json['userAvatarUrl'],
      involvedUsers: json['involvedUsers'] != null ? List<String>.from(json['involvedUsers']) : [],
    );
  }

  // --- THIS IS THE FIX ---
  // Add this method to your model class
  Map<String, dynamic> toJson() {
    return {
      'userActivityId': userActivityId,
      'userId': userId,
      'clientId': clientId,
      'clientNickname': clientNickname,
      'activityMessage': activityMessage,
      'dateCreated': dateCreated,
      'activityType': activityType,
      'sessionId': sessionId,
      'clientAvatarUrl': clientAvatarUrl,
      'userNickname': userNickname,
      'userAvatarUrl': userAvatarUrl,
      'involvedUsers': involvedUsers,
    };
  }
}
