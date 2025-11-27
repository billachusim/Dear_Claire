import 'dart:core';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/ego-profile/love_history_chart.dart';
import 'package:clairediary/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/transaction_model.dart' as t_model;
import '../../services/data/notification_model.dart' as push_notification;
import '../../services/notification_service.dart';
import '../../services/transaction_service.dart';
import '../../services/user_model.dart';

class VisitedUserClaireLoves extends StatefulWidget {
  final String visitedUsersID;
  final String visitedEgoName;

  const VisitedUserClaireLoves(
      {Key? key, required this.visitedUsersID, required this.visitedEgoName})
      : super(key: key);

  @override
  _VisitedUserClaireLovesState createState() => _VisitedUserClaireLovesState();
}

class _VisitedUserClaireLovesState extends State<VisitedUserClaireLoves> {
  int _totalLoveCount = 0;
  int _currentLoveCount = 0;
  int _withdrawnLoveCount = 0;
  int _sessionCount = 0;
  int _adviseCount = 0;
  String _rateBadge = 'Ego Rate';
  double _rate = 1.5;
  double _convertedAmount = 0.0;
  bool _isLoading = true;
  final TransactionService _transactionService = TransactionService();
  final FirebaseServices _firebaseServices = FirebaseServices();
  final TextEditingController _amountController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _amountController.addListener(_calculateConversion);
  }

  void _calculateConversion() {
    final amount = int.tryParse(_amountController.text) ?? 0;
    setState(() {
      _convertedAmount = amount * _rate;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.visitedUsersID)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data()!;
        final userType = data['userType'];
        setState(() {
          _totalLoveCount = data["totalLoveCount"] ?? 0;
          _currentLoveCount = data["currentLoveCount"] ?? 0;
          _withdrawnLoveCount = data["withdrawnLoveCount"] ?? 0;
          _sessionCount = data["sessionCount"] ?? 0;
          _adviseCount = data["adviseCount"] ?? 0;
          _rate = userType == 'SUPER_ADMIN'
              ? 3.0
              : userType == 'ADMIN'
                  ? 2.0
                  : 1.5;
          _rateBadge = userType == 'SUPER_ADMIN'
              ? 'Super Ego Rate'
              : userType == 'ADMIN'
                  ? 'Alter Ego Rate'
                  : 'Ego Rate';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppToast.showError(e.toString());
    }
  }




  Future<void> _sendGiftNotifications({
    required String senderName,
    required String receiverId,
    required int amount,
  }) async {
    try {
      // Notify the receiver
      final receiverNotification = push_notification.NotificationModel(
          topic: receiverId, // Subscribing users to their own UID topic
          data: push_notification.Data(id: receiverId, route: 'wallet'),
          notification: push_notification.Notification(
              title: "You've Received Love!",
              body: "$senderName has sent you $amount ❤️"));
      await notificationService.sendNotification(receiverNotification.toJson());

      // Notify the sender (confirmation)
      final senderNotification = push_notification.NotificationModel(
          topic: currentUser!.uid,
          data: push_notification.Data(id: currentUser!.uid, route: 'wallet'),
          notification: push_notification.Notification(
              title: "Love Sent!",
              body: "You successfully sent loves to ${widget.visitedEgoName}."));
      await notificationService.sendNotification(senderNotification.toJson());

    } catch (e) {
      print("Failed to send gift notifications: $e");
    }
  }

  Future<void> _sendAdminEmail({
    required UserModel sender,
    required String receiverName,
    required String receiverId,
    required int amountSent,
    required int amountReceived,
    required String note
  }) async {
    try {
      final String emailPayload = '''
A 'Send Love' transaction has occurred:
--------------------------------
Sender Nickname: ${sender.nickname}
Sender ID: ${sender.userId}
Amount Sent: $amountSent Loves

Receiver Nickname: $receiverName
Receiver ID: $receiverId
Amount Received: $amountReceived Loves

Note: "${note.isNotEmpty ? note : 'No note provided.'}"
Timestamp: ${DateTime.now().toIso8601String()}
''';

      final Email email = Email(
        body: emailPayload,
        subject: '[Love Transfer] ${sender.nickname} -> $receiverName',
        recipients: ['dearclaireapp@gmail.com'],
        isHTML: false,
      );
      await FlutterEmailSender.send(email);
    } catch (e) {
      print("Failed to prepare admin email: $e");
      // Don't block the user, just log the error
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Pallet.colorWhite))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _buildStatsSection(),
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                  if (currentUser?.uid != widget.visitedUsersID)
                    _buildSendLoveSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Pallet.colorPrimary, Pallet.colorSecondaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            "Total Love Earned",
            style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
          ),
          Text(
            '$_totalLoveCount ❤️',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LoveHistoryChart(spots: _generateDummySpots()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
        children: [
          _buildStatCard("Current Loves", "$_currentLoveCount ❤️", Colors.green),
          _buildStatCard("Withdrawn Loves", "$_withdrawnLoveCount ❤️", Colors.orange),
          _buildLoveStatCard(
            title: "From Sessions",
            count: _sessionCount,
            lovePerUnit: 10,
            color: Colors.blue,
          ),
          _buildLoveStatCard(
            title: "From Advices",
            count: _adviseCount,
            lovePerUnit: 10,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  // New detailed stat card for loves calculation
  Widget _buildLoveStatCard({
    required String title,
    required int count,
    required int lovePerUnit,
    required Color color,
  }) {
    final totalLove = count * lovePerUnit;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallet.colorSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            '$totalLove ❤️',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count x $lovePerUnit',
            style: GoogleFonts.lato(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallet.colorSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.lato(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSendLoveSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send Love to ${widget.visitedEgoName}",
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Brighten their day by sending some love! Your loves will be multiplied by their Ego Rate before it is sent. Only Alter and Super Egos can send loves for now.",
              style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Pallet.colorSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Amount of love to send",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Pallet.colorPrimary),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${_amountController.text.isEmpty ? '0' : _amountController.text} ❤️ x $_rate = ${_convertedAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallet.colorPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    onPressed: _handleSendLove,
                    child: Text("Send Love 🌺",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Chip(
                label: Text('Rate: $_rateBadge'),
                backgroundColor: Pallet.colorPrimary,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _handleSendLove() async {
    // Basic validation before showing the dialog
    if (currentUser == null) {
      AppToast.showError("You must be logged in to send love.");
      return;
    }
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppToast.showError("Please enter a valid amount to send.");
      return;
    }

    // --- FIX: Calculate total debit amount for balance check ---
    final int taxAmount = (amount * 0.10).ceil();
    final int totalDebitAmount = amount + taxAmount;

    final sender = await _firebaseServices.getUserInfo();

    // --- FIX: Check against the total debit amount ---
    if (sender.currentLoveCount < totalDebitAmount) {
      AppToast.showError("You need $totalDebitAmount Loves to send $amount (including tax).");
      return;
    }
    // If all checks pass, show the confirmation dialog
    _showConfirmationDialog(amount, sender);
  }



  void _showConfirmationDialog(int amount, UserModel sender) {
    final noteController = TextEditingController();  // --- Calculate tax and total debit ---
    final int taxAmount = (amount * 0.10).ceil(); // 10% tax, rounded up.
    final int totalDebitAmount = amount + taxAmount;
    final int amountToReceive = _convertedAmount.toInt();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Pallet.colorSecondary,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Confirm Your Gift",
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Updated Dialog Text ---
                Text(
                  "You are sending $amount ❤️ to ${widget.visitedEgoName}.",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "They will receive: $amountToReceive ❤️",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  "Claire's Tax (10%): $taxAmount ❤️",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  "Total Debit: $totalDebitAmount ❤️",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // --- End of Updated Text ---
                SizedBox(height: 20),
                TextFormField(
                  controller: noteController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Add a short note (optional)",
                    labelStyle: TextStyle(color: Colors.white54),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Pallet.colorPrimary),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.redAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Pallet.colorPrimary),
              child: Text("Confirm & Send",
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);

                try {
                  final senderId = currentUser!.uid;
                  final receiverId = widget.visitedUsersID;
                  final note = noteController.text.trim();

                  final noteText = note.isNotEmpty ? ' for "$note"' : '.';
                  final senderDesc = "Out: $totalDebitAmount ❤️ ($amount to ${widget.visitedEgoName} + $taxAmount tax)$noteText";
                  final receiverDesc = "Credit: $amountToReceive ❤️ received from ${sender.nickname}$noteText";
                  final claireDesc = "Credit: $taxAmount ❤️ tax from transfer: ${sender.nickname} -> ${widget.visitedEgoName}";

                  // --- SINGLE, CORRECT CALL to the new transfer method ---
                  bool success = await _firebaseServices.transferLoveBetweenUsers(
                    senderId: senderId,
                    receiverId: receiverId,
                    amountToSend: amountToReceive,
                    taxAmount: taxAmount,
                    totalDebitAmount: totalDebitAmount,
                    senderTransactionDesc: senderDesc,
                    receiverTransactionDesc: receiverDesc,
                    claireTransactionDesc: claireDesc,
                    metadata: {'senderId': senderId, 'receiverId': receiverId, 'note': note},
                  );

                  if (success) {
                    // Save  as activity
                    await _firebaseServices.saveUserActivity(
                      activityType: 'send_love',
                      activityMessage: "You sent $amount ❤️ to ${widget.visitedEgoName}.",
                      recipientId: widget.visitedUsersID,
                      recipientNickname: widget.visitedEgoName,
                    );

                    AppToast.show("$totalDebitAmount ❤️ Love sent successfully!");
                    await _sendGiftNotifications(
                      senderName: sender.nickname ?? 'An Ego',
                      receiverId: receiverId,
                      amount: amountToReceive,
                    );
                    await _sendAdminEmail(
                      sender: sender,
                      receiverName: widget.visitedEgoName,
                      receiverId: receiverId,
                      amountSent: totalDebitAmount,
                      amountReceived: amountToReceive,
                      note: note,
                    );
                  } else {
                    AppToast.showError("Transaction failed. Please try again.");
                  }
                } catch (e) {
                  AppToast.showError("An error occurred. Please try again.");
                  print("Error in _showConfirmationDialog: $e");
                } finally {
                  _amountController.clear();
                  _fetchUserData();
                  setState(() => _isLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }





  List<FlSpot> _generateDummySpots() {
    final Random random = Random();
    List<FlSpot> spots = [];
    double y = 50;
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), y));
      y += random.nextInt(20) - 10;
      if (y < 0) y = 0;
    }
    return spots;
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateConversion);
    _amountController.dispose();
    super.dispose();
  }
}

class AppToast {
  static void show(String message, {Color? bgColor}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: bgColor ?? Pallet.colorSplashScreen,
    );
  }

  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
