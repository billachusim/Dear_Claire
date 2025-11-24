import 'package:clairediary/data/models/transaction_model.dart' as t_model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class DrawerRecentTransactionsList extends StatefulWidget {
  final int? itemCount;
  final bool isScrollable;

  const DrawerRecentTransactionsList({
    Key? key,
    this.itemCount,
    this.isScrollable = true,
  }) : super(key: key);

  @override
  _DrawerRecentTransactionsListState createState() =>
      _DrawerRecentTransactionsListState();
}

class _DrawerRecentTransactionsListState
    extends State<DrawerRecentTransactionsList> {
  final TransactionService _transactionService = TransactionService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(
          child: Text("Please log in to see transactions.",
              style: TextStyle(color: Colors.white70)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _transactionService.getRecentTransactions(currentUser!.uid, limit: widget.itemCount ?? 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return const Center(
              child: Text("Error loading transactions.",
                  style: TextStyle(color: Colors.white70)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No recent transactions.",
                  style: TextStyle(color: Colors.white70)));
        }

        final transactions = snapshot.data!.docs
            .map((doc) => t_model.TransactionModel.fromFirestore(doc))
            .toList();

        return ListView.separated(
          physics: widget.isScrollable
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionTile(transaction);
          },
          separatorBuilder: (context, index) => Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
          ),
        );
      },
    );
  }

  Widget _buildTransactionTile(t_model.TransactionModel transaction) {
    final isCredit = transaction.type == t_model.TransactionType.credit;
    final color = isCredit ? Colors.greenAccent : Colors.redAccent;
    final icon = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final prefix = isCredit ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(transaction.timestamp.toDate()),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "$prefix${transaction.amount}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
