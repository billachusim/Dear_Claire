import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String? productId;
  String? sellerId;
  String? sellerNickname;
  String? sellerAvatarUrl;
  String? title;
  String? description;
  int? loveAmount;
  int? stock;
  List<String>? mediaUrls;
  List<String>? videoUrls;
  List<String>? videoThumbnailUrls;
  String? colorHex;
  List<String>? followers;
  Timestamp? timeCreated;
  Timestamp? timeLastActivity;
  String? category1;
  String? category2;
  String? category3;

  Product({
    this.productId,
    this.sellerId,
    this.sellerNickname,
    this.sellerAvatarUrl,
    this.title,
    this.description,
    this.loveAmount,
    this.stock,
    this.mediaUrls,
    this.videoUrls,
    this.videoThumbnailUrls,
    this.colorHex,
    this.followers,
    this.timeCreated,
    this.timeLastActivity,
    this.category1,
    this.category2,
    this.category3,
  });

  // Convert a Product object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'sellerNickname': sellerNickname,
      'sellerAvatarUrl': sellerAvatarUrl,
      'title': title,
      'description': description,
      'loveAmount': loveAmount,
      'stock': stock,
      'mediaUrls': mediaUrls,
      'videoUrls': videoUrls,
      'videoThumbnailUrls': videoThumbnailUrls,
      'colorHex': colorHex,
      'followers': followers,
      'timeCreated': timeCreated ?? FieldValue.serverTimestamp(),
      'timeLastActivity': timeLastActivity ?? FieldValue.serverTimestamp(),
      'category1': category1,
      'category2': category2,
      'category3': category3,
    };
  }

  // Create a Product object from a Map object
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'],
      sellerId: json['sellerId'],
      sellerNickname: json['sellerNickname'],
      sellerAvatarUrl: json['sellerAvatarUrl'],
      title: json['title'],
      description: json['description'],
      loveAmount: json['loveAmount'],
      stock: json['stock'],
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      videoThumbnailUrls: List<String>.from(json['videoThumbnailUrls'] ?? []),
      colorHex: json['colorHex'],
      followers: List<String>.from(json['followers'] ?? []),
      timeCreated: json['timeCreated'],
      timeLastActivity: json['timeLastActivity'],
      category1: json['category1'],
      category2: json['category2'],
      category3: json['category3'],
    );
  }
}
