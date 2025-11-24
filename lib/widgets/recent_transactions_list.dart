import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/transaction_model.dart';

class RecentTransactionsList extends StatefulWidget {
  const RecentTransactionsList({Key? key}) : super(key: key);

  @override
  _RecentTransactionsListState createState() => _RecentTransactionsListState();
}

class _RecentTransactionsListState extends State<RecentTransactionsList> {
  final TransactionService _transactionService = TransactionService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text("Please log in to see transactions."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _transactionService.getRecentTransactions(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading transactions."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No recent transactions."));
        }

        final transactions = snapshot.data!.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionTile(transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;
    final prefix = isCredit ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(transaction.description),
      subtitle: Text(
        "${DateFormat.yMMMd().add_jm().format(transaction.timestamp.toDate())} • ${transaction.status.name.capitalize()}",
      ),
      trailing: Text(
        "$prefix${transaction.amount} Loves",
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () => _showTransactionDetails(context, transaction),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Transaction Details"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(transaction.description, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Amount: ${transaction.amount} Loves"),
            Text("Type: ${transaction.type.name.capitalize()}"),
            Text("Status: ${transaction.status.name.capitalize()}"),
            Text("Date: ${DateFormat.yMMMd().add_jm().format(transaction.timestamp.toDate())}"),
            Text("Transaction ID: ${transaction.id}"),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
