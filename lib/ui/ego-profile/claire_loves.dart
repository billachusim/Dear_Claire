import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:clairediary/ui/ego-profile/top_up_loves_page.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/ego-profile/love_history_chart.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clairediary/data/models/transaction_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firebase_services.dart';
import '../../services/notification_service.dart';
import '../../utils/helper.dart' as Helper;
import '../../widgets/toast.dart';
import 'request_claire_love_form.dart';

class ClaireLoves extends StatefulWidget {
  @override
  _ClaireLovesState createState() => _ClaireLovesState();
}

class _ClaireLovesState extends State<ClaireLoves> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _withdrawnLoveCount = 0;
  int _currentLoveCount = 0;
  int _totalLoveCount = 0;
  int _sessionCount = 0;
  int _adviseCount = 0;
  String _rateBadge = 'Ego Rate';
  double _rate = 1.5;
  double _convertedAmount = 0.0;
  late String _userId;
  bool _isLoading = true;
  int _loveSentForVisits = 0;
  int _profileVisitLove = 0;
  int _loveFromThanks = 0;
  int _loveSentForThanks = 0;
  int fromGameWins = 0;
  int forGameLoses = 0;
  int _fromRoomVisits = 0;
  int _forRoomVisits = 0;
  int _loveFromReactions = 0;
  int _loveSentForReactions = 0;
  int _forLoveTransfer = 0;
  int _fromLoveTransfer = 0;
  int _forLoveStore = 0;
  int _fromLoveStore = 0;
  bool _showMoreStats = false;
  bool _showAllTransactions = false;
  late String _userName;
  late String _userFCMToken;

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
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data()!;
        final userType = data['userType'];
        setState(() {
          _userName = data['nickname'] ?? 'A User';
          _userFCMToken = data['fcmId'] ?? ''; // This will now have a value
          _userId = data["userId"] ?? "";
          _totalLoveCount = data["totalLoveCount"] ?? 0;
          _currentLoveCount = data["currentLoveCount"] ?? 0;
          _withdrawnLoveCount = data["withdrawnLoveCount"] ?? 0;
          _sessionCount = data["sessionCount"] ?? 0;
          _adviseCount = data["adviseCount"] ?? 0;
          _loveSentForVisits = data["loveSentForVisits"] ?? 0;
          _profileVisitLove = data["profileVisitLove"] ?? 0;
          _loveFromThanks = data["loveFromThanks"] ?? 0;
          _loveSentForThanks = data["loveSentForThanks"] ?? 0;
          fromGameWins = data["fromGameWins"] ?? 0;
          forGameLoses = data["forGameLoses"] ?? 0;
          _fromRoomVisits = data["fromRoomVisits"] ?? 0;
          _forRoomVisits = data["forRoomVisits"] ?? 0;
          _loveFromReactions = data["loveFromReactions"] ?? 0;
          _loveSentForReactions = data["loveSentForReactions"] ?? 0;
          _forLoveTransfer = data["forLoveTransfer"] ?? 0;
          _fromLoveTransfer = data["fromLoveTransfer"] ?? 0;
          _forLoveStore = data["forLoveStore"] ?? 0;
          _fromLoveStore = data["fromLoveStore"] ?? 0;

          _userId = data["userId"] ?? "";
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        showToast("Press back again to exit.");
      },
      child: Scaffold(
        backgroundColor: Pallet.colorSecondaryDark,
        body: SafeArea(
          child: _isLoading
              ? Center(child: RotateImage(70, 70))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    _buildStatsSection(),
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    _buildLoveTransferActionButtons(),
                    SliverToBoxAdapter(child: SizedBox(height: 10)),
                    _buildRecentTransactions(),
                    _buildWithdrawSection(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoveTransferActionButtons() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.arrow_upward_rounded, color: Colors.white),
                    label: Text('Send Love', style: TextStyle(color: Colors.white)),
                    onPressed: _showSendLoveDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.arrow_downward_rounded, color: Colors.white),
                    label: Text('Receive Love', style: TextStyle(color: Colors.white)),
                    onPressed: _showReceiveLoveDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.8),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16), // Spacing
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                label: Text('Top Up Loves', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  // Navigate to Top Up Page
                  Get.to(() => TopUpLovesPage());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallet.colorPrimary, // Or your preferred color
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showReceiveLoveDialog() {
    bool isAwaitingPayment = false;
    Stream<QuerySnapshot>? transactionStream;
    DateTime awaitStartTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isAwaitingPayment) {
              // --- AWAITING PAYMENT & SUCCESS UI ---
              return Dialog(
                backgroundColor: Pallet.colorSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                child: StreamBuilder<QuerySnapshot>(
                  stream: transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final newTransactions = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = (data['timestamp'] as Timestamp).toDate();
                        final type = data['type'] as String;
                        return type == 'credit' && timestamp.isAfter(awaitStartTime);
                      }).toList();

                      if (newTransactions.isNotEmpty) {
                        // --- SUCCESS UI ---
                        final latestTransaction = TransactionModel.fromFirestore(newTransactions.first);
                        final amount = latestTransaction.amount;
                        final description = latestTransaction.description;

                        // --- PARSE SENDER AND NOTE ---
                        String senderInfo = "";
                        String note = "";

                        if (description.contains("from user")) {
                          try {
                            // Extract sender
                            senderInfo = " from " + description.split("from user ")[1].split(".")[0];

                            // Extract note if it exists
                            if (description.contains("Note:")) {
                              note = description.split('Note: "')[1].split('"')[0];
                            }
                          } catch (e) {
                            // ignore if parsing fails
                          }
                        }
                        // --- END PARSING ---

                        _fetchUserData();

                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 60),
                              SizedBox(height: 16),
                              Text("Payment Received!", style: GoogleFonts.lato(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text("You received $amount ❤️$senderInfo", style: GoogleFonts.lato(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                              // --- DISPLAY NOTE ---
                              if (note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text(
                                      '"$note"',
                                      style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              // --- END DISPLAY NOTE ---
                              SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text("Close", style: TextStyle(color: Colors.white)),
                              )
                            ],
                          ),
                        );
                      }
                    }

                    // --- WAITING UI ---
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotateImage(50, 50),
                          SizedBox(height: 16),
                          Text("Awaiting payment...", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          SizedBox(height: 20),
                          Text(
                            "Keep this screen open. It will update automatically upon receiving love.",
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            } else {
              // --- INITIAL "RECEIVE" UI (No changes here) ---
              return Dialog(
                backgroundColor: Pallet.colorSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Receive Love", style: GoogleFonts.lato(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      Text("Share your User ID or QR Code", style: GoogleFonts.lato(color: Colors.white70, fontSize: 16)),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text(_userId, style: GoogleFonts.lato(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: QrImageView(data: _userId, version: QrVersions.auto, size: 150.0),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.copy, color: Colors.white70),
                            label: Text("Copy ID", style: TextStyle(color: Colors.white70)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _userId));
                              AppToast.show("User ID copied to clipboard!");
                            },
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.share, color: Colors.white70),
                            label: Text("Share", style: TextStyle(color: Colors.white70)),
                            onPressed: () {
                              final shareText = "Here's my Dear Claire App User ID to send Love❤️ to me instantly: $_userId";
                              Share.share(shareText);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isAwaitingPayment = true;
                            awaitStartTime = DateTime.now();
                            transactionStream = FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser!.uid)
                                .collection('transactions')
                                .orderBy('timestamp', descending: true)
                                .limit(1)
                                .snapshots();
                          });
                        },
                        child: Text('Receive Now', style: TextStyle(color: Colors.white, fontSize: 16)),
                      )
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }




  void _showSendLoveDialog() {
    final _formKey = GlobalKey<FormState>();
    final _recipientIdController = TextEditingController();
    final _amountController = TextEditingController();
    final _noteController = TextEditingController(); // Add this controller
    bool _isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Pallet.colorSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              child: SingleChildScrollView( // Wrap with SingleChildScrollView
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Send Love Instantly", style: GoogleFonts.lato(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 20),
                        if (_isProcessing)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Column(
                              children: [
                                RotateImage(50, 50),
                                SizedBox(height: 16),
                                Text("Processing transaction...", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              TextFormField(
                                controller: _recipientIdController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Recipient's User ID",
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.paste, color: Colors.white70),
                                    onPressed: () async {
                                      final clipboardData = await Clipboard.getData('text/plain');
                                      if (clipboardData != null) {
                                        _recipientIdController.text = clipboardData.text ?? '';
                                      }
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Recipient ID cannot be empty.';
                                  if (value == _userId) return "You can't send love to yourself.";
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: _amountController,
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount of Love❤️',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Amount cannot be empty.';
                                  final amount = int.tryParse(value);
                                  if (amount == null || amount <= 0) return 'Please enter a valid amount.';
                                  final tax = (amount * 0.10).ceil();
                                  if (_currentLoveCount < (amount + tax)) return 'Insufficient love for amount + tax.';
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              // New Optional Note Field
                              TextFormField(
                                controller: _noteController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Add a note (optional)',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                ),
                                maxLength: 100, // Optional: limit note length
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    setDialogState(() => _isProcessing = true);
                                    await _processLoveTransfer(
                                      _recipientIdController.text,
                                      int.parse(_amountController.text),
                                      _noteController.text, // Pass the note
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('Send Love', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _processLoveTransfer(String recipientId, int amount, String note) async {
    final firebaseServices = FirebaseServices();
    final taxAmount = (amount * 0.10).ceil();
    final totalDebitAmount = amount + taxAmount;
    final noteSuffix = note.isNotEmpty ? ' Note: "$note"' : '';

    final success = await firebaseServices.transferLoveBetweenUsers(
      senderId: currentUser!.uid,
      receiverId: recipientId,
      amountToSend: amount,
      taxAmount: taxAmount,
      totalDebitAmount: totalDebitAmount,
      senderTransactionDesc: 'Sent $amount❤️ to user $recipientId.$noteSuffix',
      receiverTransactionDesc: 'Received $amount❤️ from user $_userId.$noteSuffix',
      claireTransactionDesc: 'Tax ($taxAmount❤️) from transfer between $_userId and $recipientId.',
      forLoveTransfer: totalDebitAmount,
      fromLoveTransfer: amount,
      metadata: note.isNotEmpty ? {'note': note} : {},
    );

    if (success) {
      AppToast.show("Love sent successfully!");

      // --- Start Targeted Notification Logic ---
      try {
        final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(recipientId).get();
        if (receiverDoc.exists) {
          final receiverData = receiverDoc.data()!;
          final receiverToken = receiverData['fcmId'] as String?; // Use the correct field name
          final senderName = _userName.isNotEmpty ? _userName : 'A user';
          final receiverName = receiverData['nickname'] ?? 'user $recipientId';

          // 1. Send notification to the RECEIVER
          if (receiverToken != null && receiverToken.isNotEmpty) {
            await notificationService.sendNotification({
              "token": receiverToken,
              "notification": {
                "title": "You've Received Love! ❤️",
                "body": "$senderName sent you $amount❤️. ${note.isNotEmpty ? 'Note: $note' : ''}"
              },
              "data": {"route": "love_transfer_received", "senderId": currentUser!.uid}
            });
          }

          // 2. Send confirmation notification back to the SENDER
          if (_userFCMToken.isNotEmpty) {
            await notificationService.sendNotification({
              "token": _userFCMToken,
              "notification": {
                "title": "Love Sent Successfully!",
                "body": "You successfully sent $amount❤️ to $receiverName."
              },
              "data": {"route": "love_transfer_sent", "receiverId": recipientId}
            });
          }
        }
      } catch (e) {
        print("Error sending notification: $e");
        // Don't block user flow if notifications fail
      }
      // --- End Targeted Notification Logic ---

      await _fetchUserData();
    } else {
      AppToast.showError("Transaction failed. Check recipient ID & balance.");
    }
  }



  Widget _buildHeader() {
    return Container(
      //padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
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
          SizedBox(height: 10),
          SizedBox(
              height: 120,
              child: LoveHistoryChart(spots: _generateDummySpots())),
        ],
      ),
    );
  }


  Widget _buildStatsSection() {
    // A list to hold the primary stat cards
    final List<Widget> primaryStats = [
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
      _buildStatCard("From Love Transfer", "+$_fromLoveTransfer ❤️", Colors.teal),
      _buildStatCard("For Love Transfer", "-$_forLoveTransfer ❤️", Colors.blueGrey),
    ];

    // A list for the stats that will be hidden initially
    final List<Widget> secondaryStats = [
      _buildStatCard("From Ego Visits", "+$_profileVisitLove ❤️", Colors.pinkAccent),
      _buildStatCard("For Ego Visits", "-$_loveSentForVisits ❤️", Colors.grey),
      _buildStatCard("From Game Wins", "+$fromGameWins ❤️", Colors.green),
      _buildStatCard("For Game Loses", "-$forGameLoses ❤️", Colors.red),
      _buildStatCard("From Thanks", "+$_loveFromThanks ❤️", Colors.teal),
      _buildStatCard("For Thanks", "-$_loveSentForThanks ❤️", Colors.blueGrey),
      _buildStatCard("From Room Visits", "+$_fromRoomVisits ❤️", Colors.cyan),
      _buildStatCard("For Room Visits", "-$_forRoomVisits ❤️", Colors.indigo),
      _buildStatCard("From Reactions", "+$_loveFromReactions ❤️", Colors.amber),
      _buildStatCard("For Reactions", "-$_loveSentForReactions ❤️", Colors.brown),
      _buildStatCard("From Love Store", "+$_fromLoveStore ❤️", Colors.cyan),
      _buildStatCard("For Love Store", "-$_forLoveStore ❤️", Colors.indigo),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            // Grid for the primary stats that are always visible
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: primaryStats.length,
              itemBuilder: (context, index) => primaryStats[index],
              shrinkWrap: true, // Important for nested scrolling
              physics:
              const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
            ),

            // Conditionally display the "See More" section
            if (_showMoreStats) ...[
              const SizedBox(height: 10),
              // Grid for the secondary, expandable stats
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                itemCount: secondaryStats.length,
                itemBuilder: (context, index) => secondaryStats[index],
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ],

            const SizedBox(height: 10),

            // The "See More" / "See Less" button
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showMoreStats = !_showMoreStats;
                  });
                },
                child: Text(
                  _showMoreStats ? 'See Less' : 'See More',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Glass Decoration to maintain consistency
  BoxDecoration _glassDecoration() => BoxDecoration(gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Pallet.colorPrimary.withValues(alpha: 0.2),
      Pallet.colorSecondary.withValues(alpha: 0.1),
    ],
  ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1.5,
    ),
  );

  Widget _buildLoveStatCard({
    required String title,
    required int count,
    required int lovePerUnit,
    required Color color,
  }) {
    final totalLove = count * lovePerUnit;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _glassDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count x $lovePerUnit',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38),
              ),
              const Spacer(),
              // Gradient Text for the total
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, color.withValues(alpha: 0.7)],
                ).createShader(bounds),
                child: Text(
                  '$totalLove ❤️',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _triggerMoodConfetti() {
    final emoji = '❤️'; // Fallback if no emoji found

    if (emoji.isEmpty) return;

    // Configuration for "Flooding" from the bottom edges
    final options = ConfettiOptions(
      particleCount: 25,
      spread: 70,
      startVelocity: 40,
      gravity: 0.8, // Slightly heavy so they "settle" or fall back down
      ticks: 300,   // How long they stay on screen
      colors: [const Color(0xffffffff)], // Base color
    );

    // Launch from Bottom Left
    Confetti.launch(
      context,
      options: options.copyWith(x: 0.1, y: 1.0, angle: 60),
      // Use 'Emoji' class from the flutter_confetti package
      particleBuilder: (index) => Emoji(
        emoji: emoji,
        textStyle: const TextStyle(fontSize: 30),
      ),
    );

    // Launch from Bottom Right
    Confetti.launch(
      context,
      options: options.copyWith(x: 0.9, y: 1.0, angle: 120),
      // Use 'Emoji' class from the flutter_confetti package
      particleBuilder: (index) => Emoji(
        emoji: emoji,
        textStyle: const TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _triggerMoodConfetti();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _glassDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showTransactionDetailsDialog(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isCredit = transaction.type == TransactionType.credit;
        final statusColor = transaction.status == TransactionStatus.approved
            ? Colors.greenAccent
            : transaction.status == TransactionStatus.pending
            ? Colors.orangeAccent
            : Colors.redAccent;

        return Dialog(
          backgroundColor: Pallet.colorSecondary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // To make the dialog wrap its content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Transaction Details',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Description:', transaction.description),
                _buildDetailRow(
                  'Amount:',
                  '${isCredit ? '+' : '-'}${transaction.amount} ❤️',
                  valueColor: isCredit ? Colors.greenAccent : Colors.redAccent,
                ),
                _buildDetailRow('Date:',
                    Helper.formatFirestoreTimestamp(transaction.timestamp)),
                _buildDetailRow(
                    'Transaction ID:',
                    transaction.id
                        .toString()
                ),
                _buildDetailRow(
                  'Status:',
                  transaction.status
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase(),
                  valueColor: statusColor,
                ),
                // Safely access metadata
                if (transaction.metadata != null &&
                    transaction.metadata!['reason'] != null)
                  _buildDetailRow('Reason:',
                      transaction.metadata!['reason'].toString().replaceAll(
                          '_', ' ')),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text(
                      'Close',
                      style: GoogleFonts.lato(
                          color: Colors.white70, fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget for the dialog rows
  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.lato(
                color: valueColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRecentTransactions() {
    return FutureBuilder<List<TransactionModel>>(
      future: firebaseServices.getTransactionsForUser(
          userId: _userId, limit: 80),
      builder: (context, snapshot) {
        // ... (your existing waiting, error, and no-data checks are perfect)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ...
        }
        if (snapshot.hasError) {
          // ...
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final allTransactions = snapshot.data!;
        final transactionsToShow = _showAllTransactions
            ? allTransactions
            : allTransactions.take(10).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Text(
                "Recent Transactions",
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Pallet.colorSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactionsToShow.length,
                  itemBuilder: (context, index) {
                    final transaction = transactionsToShow[index];
                    // Wrap the TransactionCard with a GestureDetector
                    return GestureDetector(
                      onTap: () {
                        // Call the dialog method when the card is tapped
                        _showTransactionDetailsDialog(transaction);
                      },
                      child: Material(
                        color: Colors.transparent,
                        // Needed for the ripple effect to show correctly
                        child: TransactionCard(
                          transaction: transaction,
                          isLastItem: index == transactionsToShow.length - 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (allTransactions.length > 5)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllTransactions = !_showAllTransactions;
                      });
                    },
                    child: Text(
                      _showAllTransactions ? 'See Less' : 'See More',
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }


  Widget _buildWithdrawSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Convert and Cashout Loves",
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Earn Loves by sharing new diary sessions, sending positive advises, playing games and anonymous tips from users. "
                  "Claire multiplies your love by your ego and converts the amount to your local currency.",
              style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Pallet.colorSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Amount of love to convert",
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
                  Center(
                    child: Text('Amount X $_rateBadge',
                      style: GoogleFonts.lato(
                          color: Colors.white70, fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallet.colorPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    onPressed: _handleConversion,
                    child: Text("Request Conversion",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleConversion() {
    if (_amountController.text.isEmpty) {
      AppToast.showError("Please enter an amount");
      return;
    }
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppToast.showError("Please enter a valid amount");
      return;
    }

    if (amount > _currentLoveCount) {
      AppToast.showError("You don't have enough loves to convert.");
      return;
    }

    PageRouter.gotoWidget(
        RequestClaireLovesForm(
          loveAmount: amount,
          userId: _userId,
        ),
        context);
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


class TransactionCard extends StatelessWidget {
  // Use your existing TransactionModel
  final TransactionModel transaction;
  final bool isLastItem;

  const TransactionCard({
    Key? key,
    required this.transaction,
    this.isLastItem = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This now correctly references the `type` property from your TransactionModel
    final bool isCredit = transaction.type == TransactionType.credit;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isCredit ? Colors.greenAccent : Colors.redAccent,
            size: 28,
          ),
          title: Text(
            // This now correctly references the `description` property
            transaction.description,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            // Use the correct helper method from your Helper class
            Helper.formatFirestoreTimestamp(transaction.timestamp),
            style: GoogleFonts.lato(color: Colors.white70),
          ),
          trailing: Text(
            // This now correctly references the `amount` property
            '${isCredit ? '+' : '-'}${transaction.amount} ❤️',
            style: GoogleFonts.lato(
              color: isCredit ? Colors.greenAccent : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!isLastItem)
          const Divider(
            color: Colors.white24,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}


