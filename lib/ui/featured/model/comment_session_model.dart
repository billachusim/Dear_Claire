import 'package:cloud_firestore/cloud_firestore.dart';

class CommentSessionModel {
  final String alterEgoId;
  final String audioUrl;
  final String commentId;
  final bool flagged;
  final bool isUserAdmin;
  final String message;
  final Timestamp? timeCreated;
  final String userAvatarUrl;
  final String userId;
  final String userNickname;
  final List<dynamic> imageUrls;
  final int numberOfThanks;
  final List<dynamic> thanks;

  CommentSessionModel({
    this.alterEgoId = '',
    this.message = '',
    this.audioUrl = '',
    this.commentId = '',
    this.userNickname = '',
    this.timeCreated,
    this.userAvatarUrl = '',
    this.flagged = false,
    this.userId = '',
    this.isUserAdmin = false,
    this.imageUrls = const [],
    this.numberOfThanks = 0,
    this.thanks = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "alterEgoId": alterEgoId,
      "message": message,
      "audioUrl": audioUrl,
      "commentId": commentId,
      "userNickname": userNickname,
      "timeCreated": timeCreated,
      "userAvatarUrl": userAvatarUrl,
      "flagged": flagged,
      "userId": userId,
      "isUserAdmin": isUserAdmin,
      "numberOfThanks": numberOfThanks,
      "imageUrls": imageUrls,
      "thanks": thanks,
    };
  }

  factory CommentSessionModel.fromJson(Map<String, dynamic> json) {
    return CommentSessionModel(
      alterEgoId: json['alterEgoId'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      message: json['message'] as String? ?? '',
      commentId: json['commentId'] as String? ?? '',
      userNickname: json['userNickname'] as String? ?? '',
      timeCreated: json['timeCreated'] as Timestamp?,
      userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
      imageUrls: json['imageUrls'] as List<dynamic>? ?? [],
      flagged: json['flagged'] as bool? ?? false,
      isUserAdmin: json['isUserAdmin'] as bool? ?? false,
      numberOfThanks: json['numberOfThanks'] as int? ?? 0,
      thanks: json['thanks'] as List<dynamic>? ?? [],
      userId: json['userId'] as String? ?? '',
    );
  }
}
