import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final String buyerNickname;
  final String sellerId;
  final List<Map<String, dynamic>> items; // List of products as JSON maps
  final int totalLoveAmount;
  final String orderStatus;
  final Timestamp timestamp;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerNickname,
    required this.sellerId,
    required this.items,
    required this.totalLoveAmount,
    this.orderStatus = 'new', // Default status for new orders
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerNickname': buyerNickname,
      'sellerId': sellerId,
      'items': items,
      'totalLoveAmount': totalLoveAmount,
      'orderStatus': orderStatus,
      'timestamp': timestamp,
    };
  }
}
