import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  String? audioUrl;
  List<String>? videoUrls;
  List<String>? videoThumbnailUrls;
  String? colorHex;
  bool? archived;
  bool? flagged;
  bool? featured;
  List<dynamic>? imageUrls;
  String? message;
  String? respondentUserId;
  String? theContext;
  String? sessionId;
  Timestamp? timeCreated;
  Timestamp? timeLastActivity;
  String? title;
  String? userAvatarUrl;
  String? userId;
  String? userNickname;
  bool? private;
  bool? repliesEnabled;
  String? font;
  int? meTooFollowCount;
  int? moodId;
  List<dynamic>? followers;
  List<dynamic>? meToos;
  List<dynamic>? meLove;
  List<dynamic>? meHiFive;
  List<dynamic>? meFlower;
  String? location;
  String? category1;
  Map<String, dynamic>? translatedSession;
  Map<String, dynamic>? translatedTitle;

  Session({
    this.audioUrl,
    this.videoUrls,
    this.videoThumbnailUrls,
    this.colorHex,
    this.archived,
    this.flagged,
    this.featured,
    this.imageUrls,
    this.message,
    this.respondentUserId,
    this.theContext,
    this.sessionId,
    this.timeCreated,
    this.timeLastActivity,
    this.title,
    this.userAvatarUrl,
    this.userId,
    this.userNickname,
    this.private,
    this.repliesEnabled,
    this.font,
    this.meTooFollowCount,
    this.moodId,
    this.meToos,
    this.meLove,
    this.meHiFive,
    this.location,
    this.meFlower,
    this.followers,
    this.category1,
    this.translatedSession,
    this.translatedTitle,
  });

  factory Session.fromJson(json) {
    return Session(
      title: json['title'] ?? '',
      flagged: json['flagged'] ?? false,
      archived: json['archived'] ?? false,
      audioUrl: json['audioUrl'] ?? '',
      videoUrls: json['videoUrls'] != null ? List<String>.from(json['videoUrls']) : [],
      videoThumbnailUrls: json['videoThumbnailUrls'] != null ? List<String>.from(json['videoThumbnailUrls']) : [],
      private: json['private'] ?? false,
      repliesEnabled: json['repliesEnabled'] ?? false,
      timeLastActivity: json['timeLastActivity'],
      respondentUserId: json['respondentUserId'] ?? '',
      theContext: json['theContext'] ?? '',
      featured: json['featured'] ?? false,
      sessionId: json['sessionId'] ?? '',
      message: json['message'] ?? '',
      colorHex: json['colorHex'] ?? '',
      userNickname: json['userNickname'] ?? '',
      timeCreated: json['timeCreated'],
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      imageUrls: json['imageUrls'] ?? [],
      meTooFollowCount: json['meTooFollowCount'] ?? 0,
      userId: json['userId'] ?? '',
      moodId: json['moodId'] ?? 0,
      followers: json['followers'] ?? [],
      meToos: json['meToos'] ?? [],
      meLove: json['meLove'] ?? [],
      meHiFive: json['meHiFive'] ?? [],
      meFlower: json['meFlower'] ?? [],
      location: json['location'] ?? '',
      category1: json['category1'] ?? '',
      // Add this line to parse the map from json
      translatedSession: json['translatedSession'] != null ? Map<String, dynamic>.from(json['translatedSession']) : {},
      translatedTitle: json['translatedTitle'] != null ? Map<String, dynamic>.from(json['translatedTitle']) : {},
    );
  }

  ///converts the Timestamp in each session to a DateTime Object
  DateTime? get dateTime => timeCreated!.toDate();

  @override
  String toString() {
    // Note: I am not adding the new fields to the toString() to avoid clutter, but you can if you wish.
    return 'Session{audioUrl: $audioUrl, location: $location, colorHex: $colorHex, archived: $archived, flagged: $flagged, featured: $featured, imageUrls: $imageUrls, message: $message, respondentUserId: $respondentUserId, theContext: $theContext,  sessionId: $sessionId, timeCreated: $timeCreated, timeLastActivity: $timeLastActivity, title: $title, userAvatarUrl: $userAvatarUrl, userId: $userId, userNickname: $userNickname, private: $private, repliesEnabled: $repliesEnabled, font: $font, meTooFollowCount: $meTooFollowCount, moodId: $moodId, followers: $followers, meToos: $meToos, meLove: $meLove, meHiFive: $meHiFive, meFlower: $meFlower, category1: $category1,}';
  }
}
