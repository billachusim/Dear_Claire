// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, approved, declined }
enum TransactionType { credit, debit }

class TransactionModel {
  final String id;
  final String userId;
  final int amount;
  final TransactionType type;
  final String description;
  final TransactionStatus status;
  final Timestamp timestamp;
  final Map<String, dynamic>? metadata; // For extra info like session ID, recipient ID, etc.

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.status = TransactionStatus.approved, // Default to approved for automatic transactions
    required this.timestamp,
    this.metadata,
  });

  // From Firestore
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: data['amount'] ?? 0,
      type: (data['type'] == 'credit') ? TransactionType.credit : TransactionType.debit,
      description: data['description'] ?? 'No description',
      status: _statusFromString(data['status']),
      timestamp: data['timestamp'] ?? Timestamp.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // To Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'status': status.name,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  static TransactionStatus _statusFromString(String? status) {
    switch (status) {
      case 'approved':
        return TransactionStatus.approved;
      case 'declined':
        return TransactionStatus.declined;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }
}
