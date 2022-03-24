import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';

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
  List<dynamic>? imageUrls = [];
  int? numberOfThanks;
  List<dynamic>? thanks = [];

  CommentSessionModel(
      {this.alterEgoId = '',
      this.message = '',
      this.audioUrl = '',
      this.commentId = '',
      this.userNickname = '',
      this.timeCreated,
      this.userAvatarUrl = '',
      this.flagged = false,
      this.userId = '',
      this.isUserAdmin = false,
      this.imageUrls,
      this.numberOfThanks = 0,
      this.thanks});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["alterEgoId"] = this.alterEgoId;
    data["message"] = this.message;
    data["audioUrl"] = this.audioUrl;
    data["commentId"] = this.commentId;
    data["userNickname"] = this.userNickname;
    data["timeCreated"] = this.timeCreated;
    data["userAvatarUrl"] = this.userAvatarUrl;
    data["flagged"] = this.flagged;
    data["userId"] = this.userId;
    data["isUserAdmin"] = this.isUserAdmin;
    data["numberOfThanks"] = this.numberOfThanks;
    if (this.imageUrls != null)
      data["imageUrls"] = this.imageUrls?.map((e) => e.toJson()).toList();
    if (this.thanks != null)
      data["thanks"] = this.thanks?.map((e) => e.toJson()).toList();
    return data;
  }

  factory CommentSessionModel.fromJson(json) {
    return CommentSessionModel(
        alterEgoId: json['alterEgoId'] ?? '', //
        audioUrl: json['audioUrl'] ?? '',
        message: json['message'] ?? '',
        commentId: json['commentId'] ?? '',
        userNickname: json['userNickname'] ?? '',
        timeCreated: json['timeCreated'],
        userAvatarUrl: json['userAvatarUrl'] ?? '',
        imageUrls: json['imageUrls'] ?? [],
        flagged: json['flagged'] ?? false,
        isUserAdmin: json['isUserAdmin'] ?? false,
        numberOfThanks: json['numberOfThanks'] ?? 0, //
        thanks: json['thanks'] ?? [], //
        userId: json['userId']);
  }
}
