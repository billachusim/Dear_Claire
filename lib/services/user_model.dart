import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';

class UserModel {
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
  int? sessionCount;
  int? adviseCount;
  int? totalLoveCount;
  int? currentLoveCount;
  int? withdrawnLoveCount;

  UserModel({
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
    this.sessionCount,
    this.adviseCount,
    this.totalLoveCount,
    this.currentLoveCount,
    this.withdrawnLoveCount,
  });

  factory UserModel.fromJson(json) {
    return UserModel(
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
      sessionCount: json['sessionCount'] ?? 0,
      adviseCount: json['adviseCount'] ?? 0,
      totalLoveCount: json['totalLoveCount'] ?? 0,
      currentLoveCount: json['currentLoveCount'] ?? 0,
      withdrawnLoveCount: json['withdrawnLoveCount'] ?? 0,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> json) {
    return UserModel(
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
      sessionCount: json['sessionCount'] ?? 0,
      adviseCount: json['adviseCount'] ?? 0,
      totalLoveCount: json['totalLoveCount'] ?? 0,
      currentLoveCount: json['currentLoveCount'] ?? 0,
      withdrawnLoveCount: json['withdrawnLoveCount'] ?? 0,
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
        'sessionCount': sessionCount,
        'adviseCount': adviseCount,
        'totalLoveCount': totalLoveCount,
        'currentLoveCount': currentLoveCount,
        'withdrawnLoveCount': withdrawnLoveCount,
  };
}
