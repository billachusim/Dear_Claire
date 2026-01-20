import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? alterEgoAccessCode;
  String? alterEgoId;
  String? avatarUrl;
  String? email;
  String? fcmId;
  String? gender;
  String? nickname;
  String? secretCode;
  String? referredBy;
  String? influencerStatus;
  String? tiktok;
  String? instagram;
  String? twitter;
  String? whatsapp;
  Timestamp? timeLastUnlocked;
  Timestamp? timeRegistered;
  String? userId;
  String? userType;
  List<int> moods;
  int? sessionCount;
  int? adviseCount;
  int? totalLoveCount;
  var currentLoveCount;
  var withdrawnLoveCount;
  bool flagged;
  String? claireminderTitle;
  String? claireminderMessage;
  int? claireminderDelay;
  List<String> blockedUsers;
  String? languagePreference;

  UserModel({
    this.alterEgoAccessCode,
    this.alterEgoId,
    this.avatarUrl,
    this.email,
    this.fcmId,
    this.nickname,
    this.secretCode,
    this.referredBy,
    this.influencerStatus,
    this.tiktok,
    this.instagram,
    this.twitter,
    this.whatsapp,
    this.timeLastUnlocked,
    this.timeRegistered,
    this.gender,
    this.userId,
    this.userType,
    this.moods = const [],
    this.sessionCount,
    this.adviseCount,
    this.totalLoveCount,
    this.currentLoveCount,
    this.withdrawnLoveCount,
    this.flagged = false,
    this.claireminderTitle,
    this.claireminderMessage,
    this.claireminderDelay,
    this.blockedUsers = const [],
    this.languagePreference,
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
      moods: List<int>.from(json['moods'] ?? []),
      referredBy: json['referredBy'] ?? '',
      influencerStatus: json['influencerStatus'] ?? 'none',
      tiktok: json['tiktok'] ?? '',
      instagram: json['instagram'] ?? '',
      twitter: json['twitter'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      sessionCount: json['sessionCount'] ?? 0,
      adviseCount: json['adviseCount'] ?? 0,
      totalLoveCount: json['totalLoveCount'] ?? 0,
      currentLoveCount: json['currentLoveCount'] ?? 0,
      withdrawnLoveCount: json['withdrawnLoveCount'] ?? 0,
      flagged: json['flagged'] ?? false,
      claireminderTitle: json['claireminderTitle'] ?? '',
      claireminderMessage: json['claireminderMessage'] ?? '',
      claireminderDelay: json['claireminderDelay'] ?? 0,
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      languagePreference: json['languagePreference'] ?? 'en',
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
      moods: List<int>.from(json['moods'] ?? []),
      referredBy: json['referredBy'] ?? '',
      influencerStatus: json['influencerStatus'] ?? 'none',
      tiktok: json['tiktok'] ?? '',
      instagram: json['instagram'] ?? '',
      twitter: json['twitter'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      sessionCount: json['sessionCount'] ?? 0,
      adviseCount: json['adviseCount'] ?? 0,
      totalLoveCount: json['totalLoveCount'] ?? 0,
      currentLoveCount: json['currentLoveCount'] ?? 0.0,
      withdrawnLoveCount: json['withdrawnLoveCount'] ?? 0.0,
      flagged: json['flagged'] ?? false,
      claireminderTitle: json['claireminderTitle'] ?? '',
      claireminderMessage: json['claireminderMessage'] ?? '',
      claireminderDelay: json['claireminderDelay'] ?? 0,
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      languagePreference: json['languagePreference'] ?? 'en',
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
    'moods': moods,
    'referredBy': referredBy,
    'influencerStatus': influencerStatus,
    'sessionCount': sessionCount,
    'adviseCount': adviseCount,
    'totalLoveCount': totalLoveCount,
    'currentLoveCount': currentLoveCount,
    'withdrawnLoveCount': withdrawnLoveCount,
    'flagged': flagged,
    'claireminderTitle': claireminderTitle,
    'claireminderMessage': claireminderMessage,
    'claireminderDelay': claireminderDelay,
    'blockedUsers': blockedUsers,
    'languagePreference': languagePreference,
  };
}
