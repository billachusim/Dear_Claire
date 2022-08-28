import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/visited_user_ego_page/send_clairelove_form.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_services.dart';
import '../../utils/constant.dart';
import '../routes/page_router_animation.dart';

class VisitedUserClaireLoves extends StatefulWidget {
  final String visitedUsersID;
  final String visitedEgoName;

  VisitedUserClaireLoves(
      {Key? key, required this.visitedUsersID, required this.visitedEgoName})
      : super(key: key);

  @override
  _VisitedUserClaireLovesState createState() => _VisitedUserClaireLovesState();
}

class _VisitedUserClaireLovesState extends State<VisitedUserClaireLoves> {
  var _withdrawnLoveCount;
  var _currentLoveCount;
  var _currentWithdrawal;
  var _toRequest;
  var _rate;
  var _userType;
  late String _userId;

  bool _showRequestButton = false;


  final TextEditingController _amountController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;



  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }



  /// Set and show current withdrawal available to the user.

  void setWithdrawalAmount() {
    final currentWithdrawal = int.parse(_amountController.text);
    _toRequest = currentWithdrawal * int.parse(_rate.toString());
    _currentWithdrawal = _toRequest;

    logger.d('Got the request love count');
    print('Requested love Count is: $currentWithdrawal');
    print('Current love Count is: $_currentLoveCount');

  }


  /// Ascertain withdrawn available love for the user.

  void ascertainWithdrawnLoveCount() {
    final currentWithdrawal = int.parse(_amountController.text);
    final totalWithdrawal = _withdrawnLoveCount! + currentWithdrawal;
    final withdrawnLoveCount = currentWithdrawal + totalWithdrawal;
    _toRequest = currentWithdrawal * int.parse(_rate.toString());
    _currentWithdrawal = _toRequest;
    final visitedCurrentLoveCount = visitedUserModel.currentLoveCount;
    final newVisitedCurrentLoveCount = visitedCurrentLoveCount + _toRequest;
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.visitedUsersID)
        .set({
      "currentLoveCount": newVisitedCurrentLoveCount,
    },
      SetOptions(merge: true),
    );
    logger.d('Got the withdrawn love count');
    print('Withdrawn love Count is: $withdrawnLoveCount');

  }





  @override
  Widget build(BuildContext context) {
    return
      SafeArea(
        child: Material(
          child: Scaffold(
            backgroundColor: Pallet.colorSecondaryDark,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    child: Text(
                      "Love Wallet 🌺",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Pallet.colorWhite,
                      ),
                    ),
                  ),

                  SizedBox(height: 4,),

                  Container(
                    alignment: Alignment.topLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.visitedEgoName + '\'s',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Pallet.colorWhite,
                          ),
                        ),

                        SizedBox(width: 4,),

                        Text(
                        "Loves",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Pallet.colorWhite,
                        ),
                      ),
                    ]
                    ),
                  ),


                  SizedBox(height: 2,),

                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: getDeviceWidth(context),
                            alignment: Alignment.topCenter,
                            padding: EdgeInsets.only(left: 2, right: 2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                              "Claire converts your data to Loves for sharing time with her and positive vibes around the app.",
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ),

                  SizedBox(height: 7,),

                  Container(
                    width: getDeviceWidth(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 5,),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 45,
                                width: 90,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(widget.visitedUsersID)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var totalLoveCount = data?["totalLoveCount"] ?? "0";
                                      String userId = data?["userId"] ?? "";
                                      _userId = userId;
                                      debugPrint(
                                          " This is the Total number of LOVES earned by this user ${totalLoveCount.toString()}");
                                      return Text(
                                        totalLoveCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      );
                                    }

                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Total",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 5,),

                        Text(
                          "-",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: 5,),

                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 37,
                                width: 70,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(widget.visitedUsersID)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var withdrawnLoveCount = data?["withdrawnLoveCount"] ?? "0";
                                      _withdrawnLoveCount = withdrawnLoveCount;
                                      debugPrint(
                                          " This is the Total number of love withdrawals by this user ${withdrawnLoveCount.toString()}");
                                      return Text(
                                        withdrawnLoveCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      );
                                    }

                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Withdrawn",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 5,),

                        Text(
                          "=",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: 4,),

                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 37,
                                width: 80,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(widget.visitedUsersID)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var currentLoveCount = data?["currentLoveCount"] ?? "0";
                                      debugPrint(
                                          " This is the CURRENT loves for this user ${currentLoveCount.toString()}");
                                      return Text(
                                        currentLoveCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      );
                                    }

                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Current",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 8,)

                      ],
                    ),

                  ),



                  SizedBox(height: 25,),

                  const Divider(
                    thickness: 2,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.white70,
                    height: 3,
                  ),

                  SizedBox(height: 5,),







                  Container(
                    alignment: Alignment.topLeft,
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Send Love",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Pallet.colorWhite,
                            ),
                          ),
                        ]
                    ),
                  ),


                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: getDeviceWidth(context),
                            alignment: Alignment.topCenter,
                            padding: EdgeInsets.only(left: 2, right: 2, top: 2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                              "Claire allows you to send some love anonymously to whomever your ego desires. "
                                  "Note: Only Alter and Super Egos can send loves for now.",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ),

                  SizedBox(height: 6,),


                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8,),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 40,
                                width: 100,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(currentUser?.uid)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var currentLoveCount = data?["currentLoveCount"] ?? "0";
                                      debugPrint(
                                          " This is the CURRENT loves for this user ${currentLoveCount.toString()}");
                                      return Text(
                                        currentLoveCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      );
                                    }

                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Current",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 75,),


                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 40,
                                width: 100,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),

                                child: FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(currentUser?.uid)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var withdrawnLoveCount = data?["withdrawnLoveCount"] ?? "0";
                                      _withdrawnLoveCount = withdrawnLoveCount;
                                      debugPrint(
                                          " This is the Total number of love withdrawals by this user ${withdrawnLoveCount.toString()}");
                                      return Text(
                                        withdrawnLoveCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      );
                                    }

                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Withdrawn",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),

                  ),







                  SizedBox(height: 20,),




                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8,),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 40,
                                width: 100,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: TextField(
                                  cursorColor: Pallet.colorSecondary,
                                  keyboardType: TextInputType.number,
                                  maxLines: 1,
                                  controller: _amountController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                    EdgeInsets.only(left: 22.0, bottom: 13, right: 2.0),
                                    hintText: "000",
                                    hintStyle: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Pallet.grey,
                                      fontSize: 14,
                                    ),
                                    counterText: '',
                                  ),
                                  maxLength: 5,
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Enter Amount",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),


                        SizedBox(width: 5,),

                        Text(
                          "x",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: 4,),

                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 30,
                                width: 60,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(widget.visitedUsersID)
                                      .get(),
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!.data();
                                      var userType = data?["userType"] ?? "REGULAR";
                                      _rate = userType == 'REGULAR'? '1.5' :
                                      userType == 'ADMIN'? '2' :
                                      userType == 'SUPER_ADMIN'? '3' :
                                      '2';
                                      _userType = userType;
                                      debugPrint(
                                          " This is the ego rate used for conversion for this user ${_rate.toString()}");
                                      return Text(
                                        _rate.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      );
                                    }

                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              _userType == 'REGULAR'? 'Ego Rate' :
                              _userType == 'ADMIN'? 'AlterEgo Rate' :
                              _userType == 'SUPER_ADMIN'? 'SuperEgo Rate' :
                              'Ego Rate',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 4,),

                        Text(
                          "=",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: 4,),

                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: EdgeInsets.only(top: 7),
                                height: 40,
                                width: 100,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: TextField(
                                  cursorColor: Pallet.colorSecondary,
                                  keyboardType: TextInputType.number,
                                  maxLines: 1,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                    EdgeInsets.only(left: 22.0, bottom: 13, right: 2.0),
                                    hintText: _currentWithdrawal.toString(),
                                    hintStyle: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Pallet.colorBlack,
                                      fontSize: 20,
                                    ),
                                    counterText: '',
                                  ),
                                  maxLength: 5,
                                ),
                              ),
                            ),
                            SizedBox(height: 2,),
                            Text(
                              "Cash Out",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),


                      ],
                    ),

                  ),

                  SizedBox(height: 8,),

                  Visibility(
                    visible: currentUser?.uid != widget.visitedUsersID,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        Align(
                          alignment: Alignment.center,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {

                              });
                              if (_amountController.text.isNotEmpty) {
                                setState(() {
                                  setWithdrawalAmount();
                                  _showRequestButton = true;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Pallet.colorSecondary,
                              padding: EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text("Show Cash Out",
                                style: GoogleFonts.lato(
                                    fontSize: 12.0, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),

                        SizedBox(width: 10,),

                        Visibility(
                          visible: _showRequestButton,
                          child: OutlinedButton(
                            onPressed: () async {
                              final _user = await firebaseServices.getUserInfo();
                              if (_user.currentLoveCount > _currentWithdrawal) {
                                //ascertainWithdrawnLoveCount();
                                PageRouter.gotoWidget(
                                    SendClaireLoveForm(
                                      amountToSend: _currentWithdrawal.toString(),
                                      userId: _userId.toString(),
                                      visitedUsersId: widget.visitedUsersID,
                                      visitedUser: widget.visitedEgoName,
                                    ), context);

                                print("Requested Amount Is::: $_currentWithdrawal");
                                print("Available Amount Is::: $_currentLoveCount");
                              }
                              else showToast("You can't request higher than current loves.");
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Pallet.colorSecondary,
                              padding: EdgeInsets.all(17),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text("Send Love  🌺",
                                style: GoogleFonts.lato(
                                    fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),

                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      );
  }
}