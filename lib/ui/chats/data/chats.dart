import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  bool? archived;
  String? audioUrl;
  String? colorHex;
  bool? featured;
  bool? flagged;
  String? font;
  List<String>? imageUrls;
  String? message;
  int? moodId;
  bool? private;
  bool? repliesEnabled;
  String? respondentUserId;
  String? sessionId;
  Timestamp? timeCreated;
  Timestamp? timeLastActivity;
  String? title;
  String? userAvatarUrl;
  String? userId;
  String? userNickname;
  String? image1;
  String? image2;
  String? location;
  String? userType;
  String? alterEgoId;
  List<dynamic>? members;
  Map<String, dynamic>? subMessage;

  ChatModel(
      {this.archived = false,
      this.audioUrl,
      this.colorHex,
      this.featured = false,
      this.flagged = false,
      this.font,
      this.imageUrls,
      required this.message,
      this.private,
      this.repliesEnabled,
      this.respondentUserId,
      this.sessionId,
      required this.timeCreated,
      this.timeLastActivity,
      this.title,
      this.moodId,
      this.subMessage,
      this.userAvatarUrl,
      required this.userId,
      this.members,
      this.userNickname,
      this.image1,
      this.image2,
      this.location,
      this.userType,
      this.alterEgoId,
      });

  ChatModel.fromJson(Map<String, dynamic> json) {
    if (json['imageUrls'] != null) {
      imageUrls = json['imageUrls'].cast<String>();
    }

    userType = json['userType'];
    alterEgoId = json['alterEgoId'];

    repliesEnabled = json['repliesEnabled'];
    if (json['respondentUserId'] != null) {
      respondentUserId = json['respondentUserId'];
    }
    if (json['moodId'] != null) {
      moodId = json['moodId'];
    }

    sessionId = json['sessionId'];
    timeCreated = json['timeCreated'];
    if (json['timeLastActivity'] != null) {
      timeLastActivity = json['timeLastActivity'];
    }

    if (json['location'] != null) {
      location = json['location'];
    }

    userAvatarUrl = json['userAvatarUrl'];
    userId = json['userId'];
    userNickname = json['userNickname'];
    image1 = json["image1"];
    image2 = json["image2"];
    if (json['repliesEnabled'] != null) {
      repliesEnabled = json['repliesEnabled'];
    }
    if (json['subMessage'] != null) {
      subMessage = Map<String, dynamic>.from(json['subMessage']);
    }
    title = json['title'];
    archived = json['archived'];
    colorHex = json['colorHex'];
    featured = json['featured'];
    flagged = json['flagged'];
    font = json['font'];

    if (json['audioUrl'] != null) {
      audioUrl = json['audioUrl'];
    }

    message = json['message'];
    private = json['private'];
    if (json['members'] != null) {
      members = json['members'] ?? [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (imageUrls != null) {
      data['imageUrls'] = imageUrls!.map((e) => e.toString()).toList();
    }
    if (moodId != null) {
      data['moodId'] = moodId;
    }

    data['userType'] = userType;
    data['alterEgoId'] = alterEgoId;

    if (location != null) {
      data['location'] = location;
    }

    data['repliesEnabled'] = repliesEnabled;
    data['respondentUserId'] = respondentUserId;
    data['members'] = members;
    data['sessionId'] = sessionId;
    data['subMessage'] = subMessage;
    data['timeCreated'] = Timestamp.now();
    data['timeLastActivity'] = timeLastActivity;
    data['userAvatarUrl'] = userAvatarUrl;
    data['userId'] = userId;
    data['userNickname'] = userNickname;
    data["image1"] = image1;
    data["image2"] = image2;
    data['repliesEnabled'] = repliesEnabled;
    data['title'] = title;
    data['archived'] = archived;
    data['colorHex'] = colorHex;
    data['featured'] = featured;
    data['flagged'] = flagged;
    if (font == null) {
      data['font'] = '';
    } else {
      data['font'] = font;
    }
    if (audioUrl != null) {
      data['audioUrl'] = audioUrl;
    }

    data['message'] = message;
    data['private'] = private;
    data['repliesEnabled'] = repliesEnabled;

    return data;
  }
}
