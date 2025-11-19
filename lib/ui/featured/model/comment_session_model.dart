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
  List<dynamic>? imageUrls = []; // Kept as List<dynamic> for compatibility
  int? numberOfThanks;
  List<dynamic>? thanks = []; // Kept as List<dynamic> for compatibility
  String? originalAdviseCategory;

  CommentSessionModel(
      {this.alterEgoId = '',
        this.message = '',
        this.audioUrl = '',
        this.commentId = '',
        this.userNickname = '',
        this.image1 = '', // Kept for compatibility
        this.image2 = '', // Kept for compatibility
        this.timeCreated,
        this.userAvatarUrl = '',
        this.flagged = false,
        this.userId = '',
        this.isUserAdmin = false,
        this.imageUrls,
        this.numberOfThanks = 0,
        this.thanks,
        this.originalAdviseCategory});

  /// Converts the model instance to a Map, suitable for uploading to Firestore.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["alterEgoId"] = this.alterEgoId;
    data["message"] = this.message;
    data["audioUrl"] = this.audioUrl;
    data["commentId"] = this.commentId;
    data["userNickname"] = this.userNickname;
    data["image1"] = this.image1; // Kept for compatibility
    data["image2"] = this.image2; // Kept for compatibility
    data["timeCreated"] = this.timeCreated;
    data["userAvatarUrl"] = this.userAvatarUrl;
    data["flagged"] = this.flagged;
    data["userId"] = this.userId;
    data["isUserAdmin"] = this.isUserAdmin;
    data["numberOfThanks"] = this.numberOfThanks;
    data["originalAdviseCategory"] = this.originalAdviseCategory;

    // --- START OF THE MINIMAL FIX ---

    // 1. For image URLs:
    // If the list is not null, assign it directly. Firestore can handle List<String>.
    if (this.imageUrls != null) {
      data["imageUrls"] = this.imageUrls; // CORRECTED: Removed the failing .map() call
    }

    // 2. For thanks:
    // Apply the same logic. If 'thanks' is a list of simple types (like Strings),
    // it should also be assigned directly.
    if (this.thanks != null) {
      // Assuming 'thanks' contains Firestore-compatible types (String, Number, etc.)
      data["thanks"] = this.thanks; // CORRECTED: Removed the failing .map() call
    }

    // --- END OF THE MINIMAL FIX ---

    return data;
  }

  /// Creates a CommentSessionModel instance from a Firestore document snapshot.
  factory CommentSessionModel.fromJson(json) {
    return CommentSessionModel(
        alterEgoId: json['alterEgoId'] ?? '',
        audioUrl: json['audioUrl'] ?? '',
        message: json['message'] ?? '',
        commentId: json['commentId'] ?? '',
        userNickname: json['userNickname'] ?? '',
        image1: json['image1'] ?? '', // Kept for compatibility
        image2: json['image2'] ?? '', // Kept for compatibility
        timeCreated: json['timeCreated'],
        userAvatarUrl: json['userAvatarUrl'] ?? '',
        imageUrls: json['imageUrls'] ?? [],
        flagged: json['flagged'] ?? false,
        isUserAdmin: json['isUserAdmin'] ?? false,
        numberOfThanks: json['numberOfThanks'] ?? 0,
        thanks: json['thanks'] ?? [],
        userId: json['userId'] ?? '',
        originalAdviseCategory: json['originalAdviseCategory'] ?? '');
  }
}
