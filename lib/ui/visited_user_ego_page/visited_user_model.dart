import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';

class VisitedUserModel {
  String? alterEgoAccessCode;
  String? alterEgoId;
  String? avatarUrl;
  String? email;
  String? fcmId;
  String? gender;
  String? nickname;
  String? secretCode;
  Timestamp? timeLastUnlocked;
  Timestamp? timeRegistered;
  String? userId;
  String? userType;

  VisitedUserModel({
    this.alterEgoAccessCode,
    this.alterEgoId,
    this.avatarUrl,
    this.email,
    this.fcmId,
    this.nickname,
    this.secretCode,
    this.timeLastUnlocked,
    this.timeRegistered,
    this.gender,
    this.userId,
    this.userType,
  });

  factory VisitedUserModel.fromJson(json) {
    return VisitedUserModel(
      alterEgoAccessCode: json['alterEgoAccessCode'] ?? '',
      alterEgoId: json['alterEgoId'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      email: json['email'] ?? '',
      fcmId: json['fcmId'] ?? '',
      gender: json['gender'] ?? '',
      nickname: json['nickname'] ?? '',
      secretCode: json['secretCode'] ?? '',
      timeLastUnlocked: json['timeLastUnlocked'],
      timeRegistered: json['timeRegistered'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
    );
  }

  factory VisitedUserModel.fromFirestore(Map<String, dynamic> json) {
    return VisitedUserModel(
      alterEgoAccessCode: json['alterEgoAccessCode'] ?? '',
      alterEgoId: json['alterEgoId'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      email: json['email'] ?? '',
      fcmId: json['fcmId'] ?? '',
      gender: json['gender'] ?? '',
      nickname: json['nickname'] ?? '',
      secretCode: json['secretCode'] ?? '',
      timeLastUnlocked: json['timeLastUnlocked'],
      timeRegistered: json['timeRegistered'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'alterEgoAccessCode': alterEgoAccessCode,
    'alterEgoId': alterEgoId,
    'avatarUrl': avatarUrl,
    'email': email,
    'fcmId': fcmId,
    'gender': gender,
    'nickname': nickname,
    'secretCode': secretCode,
    'timeLastUnlocked': timeLastUnlocked,
    'timeRegistered': timeRegistered,
    'userId': userId,
    'userType': userType,
  };
}
