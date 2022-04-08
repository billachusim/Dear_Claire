import 'package:cloud_firestore/cloud_firestore.dart';

class FeaturedSessionModel {
  String? title;
  String? message;
  String? sessionId;
  String? colorHex;
  String? userNickname;
  String? userAvatarUrl;
  Timestamp? timeCreated;
  List<dynamic>? imageUrls;
  int? meTooFollowCount;
  String? userId;
  int? moodId;
  List<dynamic>? followers;
  List<dynamic>? meToos;
  bool flagged;
  bool featured;
  String? location;

  FeaturedSessionModel({
    this.title,
    this.message,
    this.sessionId,
    this.colorHex,
    this.userNickname,
    this.timeCreated,
    this.userAvatarUrl,
    this.imageUrls,
    this.meTooFollowCount,
    this.userId,
    this.moodId,
    this.followers,
    this.meToos,
    this.flagged = false,
    this.featured = false,
    this.location
  });

  factory FeaturedSessionModel.fromJson(dynamic json) {
    return FeaturedSessionModel(
      title: json['title'] ?? '',
      flagged: json['flagged'],
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
      location: json['location'] ?? '',
    );
  }
}
