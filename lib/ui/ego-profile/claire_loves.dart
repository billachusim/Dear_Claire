import 'dart:core';
import 'dart:math';

import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/ego-profile/love_history_chart.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clairediary/data/models/transaction_model.dart';
import '../../utils/helper.dart' as Helper;
import 'request_claire_love_form.dart';

class ClaireLoves extends StatefulWidget {
  @override
  _ClaireLovesState createState() => _ClaireLovesState();
}

class _ClaireLovesState extends State<ClaireLoves> {
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
  bool _showMoreStats = false;
  bool _showAllTransactions = false;

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
    return Scaffold(
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
                  _buildRecentTransactions(),
                  _buildWithdrawSection(),
                ],
              ),
      ),
    );
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
          SizedBox(height: 20),
          SizedBox(
              height: 100,
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
      _buildStatCard("Sessions", "$_sessionCount 📝", Colors.blue),
      _buildStatCard("Advises", "$_adviseCount 💡", Colors.purple),
      _buildStatCard("From Game Wins", "+$fromGameWins ❤️", Colors.green),
      _buildStatCard("For Game Loses", "-$forGameLoses ❤️", Colors.red),
    ];

    // A list for the stats that will be hidden initially
    final List<Widget> secondaryStats = [
      _buildStatCard("From Ego Visits", "+$_profileVisitLove ❤️", Colors.pinkAccent),
      _buildStatCard("To Ego Visits", "-$_loveSentForVisits ❤️", Colors.grey),
      _buildStatCard("Love from Thanks", "+$_loveFromThanks ❤️", Colors.teal),
      _buildStatCard("Love Sent as Thanks", "-$_loveSentForThanks ❤️", Colors.blueGrey),
      _buildStatCard("From Room Visits", "+$_fromRoomVisits ❤️", Colors.cyan),
      _buildStatCard("For Room Visits", "-$_forRoomVisits ❤️", Colors.indigo),
      _buildStatCard("From Reactions", "+$_loveFromReactions ❤️", Colors.amber),
      _buildStatCard("Sent for Reactions", "-$_loveSentForReactions ❤️", Colors.brown),
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
                childAspectRatio: 2,
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


// REPLACE the existing _buildRecentTransactions method with this one.
  Widget _buildRecentTransactions() {
    // This now uses your actual `TransactionModel`
    return FutureBuilder<List<TransactionModel>>(
      // Fetch a larger number of transactions to have them ready for expansion
      future: firebaseServices.getTransactionsForUser(userId: _userId, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading transactions: ${snapshot.error}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Gracefully show nothing if there are no transactions
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final allTransactions = snapshot.data!;
        // Show only the first 5 transactions initially, or all if "See More" is tapped
        final transactionsToShow = _showAllTransactions ? allTransactions : allTransactions.take(5).toList();

        // This Sliver contains the title, the container, the list, and the "See More" button
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              // 1. The Title
              Text(
                "Recent Transactions",
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // 2. The styled Container
              Container(
                decoration: BoxDecoration(
                  color: Pallet.colorSecondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactionsToShow.length,
                  itemBuilder: (context, index) {
                    // 3. The TransactionCard for each item
                    return TransactionCard(
                      transaction: transactionsToShow[index],
                      isLastItem: index == transactionsToShow.length - 1,
                    );
                  },
                ),
              ),

              // 4. The "See More" / "See Less" button
              // Only show the button if there are more transactions than the initial limit
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
              "Convert Loves",
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Earn Loves by sharing new diary sessions, sending positive advises, playing games and anonymous tips from users.",              style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
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


