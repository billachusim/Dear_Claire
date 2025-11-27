import 'package:cloud_firestore/cloud_firestore.dart';

class CreateSessionModel {
  bool? containsAudio;
  bool? containsVideo;
  bool? archived;
  String? audioUrl;
  List<String>? videoUrls;
  List<String>? videoThumbnailUrls;
  String? colorHex;
  bool? featured;
  bool? flagged;
  String? font;
  List<String>? imageUrls;
  String? message;
  int? moodId;
  bool? private;
  bool? repliesEnabled;
  String? theContext;
  String? respondentUserId;
  String? sessionId;
  Timestamp? timeCreated;
  Timestamp? timeLastActivity;
  String? title;
  String? userAvatarUrl;
  String? userId;
  String? userNickname;
  String? location;
  String? category1;
  String? category2;
  String? category3;
  String? category4;
  List<dynamic>? followers;

  CreateSessionModel(
      {this.archived = false,
      this.containsAudio,
      this.containsVideo,
      this.audioUrl,
      this.videoUrls,
      this.videoThumbnailUrls,
      this.colorHex,
      this.featured = false,
      this.flagged = false,
      this.font,
      this.imageUrls,
      this.message,
      this.private,
      this.theContext,
      this.repliesEnabled,
      this.respondentUserId,
      this.sessionId,
      this.timeCreated,
      this.timeLastActivity,
      this.title,
      this.moodId,
      this.userAvatarUrl,
      this.userId,
      this.location,
      this.userNickname,
      this.category1,
      this.category2,
      this.category3,
      this.category4,
      this.followers,
      }
      );

  CreateSessionModel.fromJson(Map<String, dynamic> json) {
    if (json['imageUrls'] != null) {
      imageUrls = json['imageUrls'].cast<String>();
    }

    repliesEnabled = json['repliesEnabled'];
    if (json['theContext'] != null) {
      theContext = json['theContext'];
    }
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

    userAvatarUrl = json['userAvatarUrl'];
    userId = json['userId'];
    userNickname = json['userNickname'];
    if (json['repliesEnabled'] != null) {
      repliesEnabled = json['repliesEnabled'];
    }
    if (json['location'] != null) {
      location = json['location'];
    }

    title = json['title'];
    archived = json['archived'];
    colorHex = json['colorHex'];
    featured = json['featured'];
    flagged = json['flagged'];
    font = json['font'];

    if (json['audioUrl'] != null) {
      audioUrl = json['audioUrl'];
      containsAudio = json['containsAudio'];
    }

    if (json['videoUrls'] != null) {
      videoUrls = json['videoUrls'];
      containsVideo = json['containsVideo'];
    }

    if (json['videoThumbnailUrls'] != null) {
      videoThumbnailUrls = json['videoThumbnailUrls'];
      containsVideo = json['containsVideo'];
    }


    message = json['message'];
    private = json['private'];

    category1 = json['category1'];
    category2 = json['category2'];
    category3 = json['category3'];
    category4 = json['category4'];

    if (json['followers'] != null) {
      followers = json['followers'];
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    // --- All your existing data assignments ---
    if (imageUrls != null) {
      data['imageUrls'] = imageUrls!.map((e) => e.toString()).toList();
    }
    if (moodId != null) {
      data['moodId'] = moodId;
    }
    if (location != null) {
      data['location'] = location;
    }

    data['repliesEnabled'] = repliesEnabled;
    data['theContext'] = theContext;
    data['respondentUserId'] = respondentUserId;
    data['sessionId'] = sessionId;
    data['timeCreated'] = Timestamp.now();
    data['timeLastActivity'] = timeLastActivity;
    data['userAvatarUrl'] = userAvatarUrl;
    data['userId'] = userId;
    data['userNickname'] = userNickname;
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
      data['containsAudio'] = containsAudio;
    }

    if (videoUrls != null && videoUrls!.isNotEmpty) {
      data['videoUrls'] = videoUrls;
      data['containsVideo'] = true;
    }
    if (videoThumbnailUrls != null && videoThumbnailUrls!.isNotEmpty) {
      data['videoThumbnailUrls'] = videoThumbnailUrls;
    }

    data['category1'] = category1;
    data['category2'] = category2;
    data['category3'] = category3;
    data['category4'] = category4;
    data['followers'] = followers;
    data['message'] = message;
    data['private'] = private;

    return data;
  }

}
