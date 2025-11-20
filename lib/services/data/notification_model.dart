class NotificationModel {
  String? topic;
  Notification? notification;
  Data? data;

  NotificationModel({
    this.topic,
    this.notification,
    this.data,
  });

  NotificationModel.fromJson(Map<String, dynamic> json) {
    if (json["topic"] is String) this.topic = json["topic"];
    if (json["notification"] is Map)
      this.notification = json["notification"] == null
          ? null
          : Notification.fromJson(json["notification"]);
    if (json["data"] is Map)
      this.data = json["data"] == null ? null : Data.fromJson(json["data"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["topic"] = this.topic;
    if (this.notification != null)
      data["notification"] = this.notification?.toJson();
    if (this.data != null) data["data"] = this.data?.toJson();
    return data;
  }
}

class Notification {
  String? body;
  String? title;

  Notification({this.body, this.title});

  Notification.fromJson(Map<String, dynamic> json) {
    if (json["body"] is String) this.body = json["body"];
    if (json["title"] is String) this.title = json["title"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["body"] = this.body;
    data["title"] = this.title;
    return data;
  }
}

class Data {
  String? id;

  String? route;

  Data({this.id, this.route});

  Data.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.route = json["route"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data["id"] = this.id;
    data["route"] = this.route;
    return data;
  }
}
