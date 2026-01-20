import 'package:cloud_firestore/cloud_firestore.dart';

class CommentSessionModel {
  String? alterEgoId;
  String? audioUrl;
  String? commentId;
  bool flagged;
  bool isUserAdmin;
  String? message;
  Timestamp? timeCreated;
  String? userAvatarUrl;
  String? userId;
  String? userNickname;
  String? image1;
  String? image2;
  List<dynamic>? imageUrls = [];
  int? numberOfThanks;
  List<dynamic>? thanks = [];
  String? originalAdviseCategory;
  Map<String, dynamic>? translatedComment; // Add this line

  CommentSessionModel(
      {this.alterEgoId = '',
        this.message = '',
        this.audioUrl = '',
        this.commentId = '',
        this.userNickname = '',
        this.image1 = '',
        this.image2 = '',
        this.timeCreated,
        this.userAvatarUrl = '',
        this.flagged = false,
        this.userId = '',
        this.isUserAdmin = false,
        this.imageUrls,
        this.numberOfThanks = 0,
        this.thanks,
        this.originalAdviseCategory,
        this.translatedComment // Add this line
      });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    // ... (keep existing toJson assignments)
    data["alterEgoId"] = this.alterEgoId;
    data["message"] = this.message;
    data["audioUrl"] = this.audioUrl;
    data["commentId"] = this.commentId;
    data["userNickname"] = this.userNickname;
    data["image1"] = this.image1;
    data["image2"] = this.image2;
    data["timeCreated"] = this.timeCreated;
    data["userAvatarUrl"] = this.userAvatarUrl;
    data["flagged"] = this.flagged;
    data["userId"] = this.userId;
    data["isUserAdmin"] = this.isUserAdmin;
    data["numberOfThanks"] = this.numberOfThanks;
    data["originalAdviseCategory"] = this.originalAdviseCategory;
    if (this.imageUrls != null) {
      data["imageUrls"] = this.imageUrls;
    }
    if (this.thanks != null) {
      data["thanks"] = this.thanks;
    }
    if (this.translatedComment != null) { // Add this block
      data["translatedComment"] = this.translatedComment;
    }
    return data;
  }

  factory CommentSessionModel.fromJson(json) {
    return CommentSessionModel(
        alterEgoId: json['alterEgoId'] ?? '',
        audioUrl: json['audioUrl'] ?? '',
        message: json['message'] ?? '',
        commentId: json['commentId'] ?? '',
        userNickname: json['userNickname'] ?? '',
        image1: json['image1'] ?? '',
        image2: json['image2'] ?? '',
        timeCreated: json['timeCreated'],
        userAvatarUrl: json['userAvatarUrl'] ?? '',
        imageUrls: json['imageUrls'] ?? [],
        flagged: json['flagged'] ?? false,
        isUserAdmin: json['isUserAdmin'] ?? false,
        numberOfThanks: json['numberOfThanks'] ?? 0,
        thanks: json['thanks'] ?? [],
        userId: json['userId'] ?? '',
        originalAdviseCategory: json['originalAdviseCategory'] ?? '',
        // Add this line to parse the map from json
        translatedComment: json['translatedComment'] != null
            ? Map<String, dynamic>.from(json['translatedComment'])
            : {});
  }
}
