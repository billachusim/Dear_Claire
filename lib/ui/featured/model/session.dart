import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String audioUrl;
  final String colorHex;
  final bool archived;
  final bool flagged;
  final bool featured;
  final List<dynamic> imageUrls;
  final String message;
  final String respondentUserId;
  final String sessionId;
  final Timestamp? timeCreated;
  final Timestamp? timeLastActivity;
  final String title;
  final String userAvatarUrl;
  final String userId;
  final String userNickname;
  final bool private;
  final bool repliesEnabled;
  final String font;
  final int meTooFollowCount;
  final int moodId;
  final List<dynamic> followers;
  final List<dynamic> meToos;
  final List<dynamic> meLove;
  final List<dynamic> meHiFive;
  final List<dynamic> meFlower;
  final String location;

  Session({
    this.audioUrl = '',
    this.colorHex = '',
    this.archived = false,
    this.flagged = false,
    this.featured = false,
    this.imageUrls = const [],
    this.message = '',
    this.respondentUserId = '',
    this.sessionId = '',
    this.timeCreated,
    this.timeLastActivity,
    this.title = '',
    this.userAvatarUrl = '',
    this.userId = '',
    this.userNickname = '',
    this.private = false,
    this.repliesEnabled = false,
    this.font = '',
    this.meTooFollowCount = 0,
    this.moodId = 0,
    this.followers = const [],
    this.meToos = const [],
    this.meLove = const [],
    this.meHiFive = const [],
    this.meFlower = const [],
    this.location = '',
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      title: json['title'] as String? ?? '',
      flagged: json['flagged'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      audioUrl: json['audioUrl'] as String? ?? '',
      private: json['private'] as bool? ?? false,
      repliesEnabled: json['repliesEnabled'] as bool? ?? false,
      timeLastActivity: json['timeLastActivity'] as Timestamp?,
      respondentUserId: json['respondentUserId'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      sessionId: json['sessionId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '',
      userNickname: json['userNickname'] as String? ?? '',
      timeCreated: json['timeCreated'] as Timestamp?,
      userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
      imageUrls: json['imageUrls'] as List<dynamic>? ?? [],
      meTooFollowCount: json['meTooFollowCount'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      moodId: json['moodId'] as int? ?? 0,
      followers: json['followers'] as List<dynamic>? ?? [],
      meToos: json['meToos'] as List<dynamic>? ?? [],
      meLove: json['meLove'] as List<dynamic>? ?? [],
      meHiFive: json['meHiFive'] as List<dynamic>? ?? [],
      meFlower: json['meFlower'] as List<dynamic>? ?? [],
      location: json['location'] as String? ?? '',
    );
  }

  DateTime? get dateTime => timeCreated?.toDate();

  @override
  String toString() {
    return 'Session{audioUrl: $audioUrl, colorHex: $colorHex, archived: $archived, flagged: $flagged, featured: $featured, imageUrls: $imageUrls, message: $message, respondentUserId: $respondentUserId, sessionId: $sessionId, timeCreated: $timeCreated, timeLastActivity: $timeLastActivity, title: $title, userAvatarUrl: $userAvatarUrl, userId: $userId, userNickname: $userNickname, private: $private, repliesEnabled: $repliesEnabled, font: $font, meTooFollowCount: $meTooFollowCount, moodId: $moodId, followers: $followers, meToos: $meToos, meLove: $meLove, meHiFive: $meHiFive, meFlower: $meFlower}';
  }
}
