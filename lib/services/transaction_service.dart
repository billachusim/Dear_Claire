// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/transaction_model.dart' as t_model;

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for transactions
  CollectionReference<Map<String, dynamic>> _transactionsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  /// Records a new transaction in Firestore.
  Future<void> recordTransaction({
    required String userId,
    required int amount,
    required t_model.TransactionType type,
    required String description,
    t_model.TransactionStatus status = t_model.TransactionStatus.approved,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final newDoc = _transactionsCollection(userId).doc();
      final transaction = t_model.TransactionModel(
        id: newDoc.id,
        userId: userId,
        amount: amount,
        type: type,
        description: description,
        status: status,
        timestamp: Timestamp.now(),
        metadata: metadata,
      );
      await newDoc.set(transaction.toJson());
      print("Transaction recorded: $description");
    } catch (e) {
      print("Failed to record transaction: $e");
    }
  }

  /// Fetches a stream of recent transactions for a user.
  Stream<QuerySnapshot> getRecentTransactions(String userId, {int limit = 20}) {
    return _transactionsCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}
