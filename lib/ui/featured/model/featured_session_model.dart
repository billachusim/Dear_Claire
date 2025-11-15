import 'package:cloud_firestore/cloud_firestore.dart';

class FeaturedSessionModel {
  final String title;
  final String message;
  final String sessionId;
  final String colorHex;
  final String userNickname;
  final String userAvatarUrl;
  final Timestamp? timeCreated;
  final List<dynamic> imageUrls;
  final int meTooFollowCount;
  final String userId;
  final int moodId;
  final List<dynamic> followers;
  final List<dynamic> meToos;
  final bool flagged;
  final bool featured;

  FeaturedSessionModel({
    this.title = '',
    this.message = '',
    this.sessionId = '',
    this.colorHex = '',
    this.userNickname = '',
    this.timeCreated,
    this.userAvatarUrl = '',
    this.imageUrls = const [],
    this.meTooFollowCount = 0,
    this.userId = '',
    this.moodId = 0,
    this.followers = const [],
    this.meToos = const [],
    this.flagged = false,
    this.featured = false,
  });

  factory FeaturedSessionModel.fromJson(Map<String, dynamic> json) {
    return FeaturedSessionModel(
      title: json['title'] as String? ?? '',
      flagged: json['flagged'] as bool? ?? false,
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
    );
  }
}
