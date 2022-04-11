import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_services.dart';
import '../../utils/constant.dart';
import '../../utils/strings.dart';
import '../routes/routes.dart';

class ClaireLoves extends StatefulWidget {
  @override
  _ClaireLovesState createState() => _ClaireLovesState();
}

class _ClaireLovesState extends State<ClaireLoves> {
  final TextEditingController _amountController = TextEditingController();





  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getUser() async {
    userModel = await firebaseServices.getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return
      SafeArea(
        child: Material(
          child: Scaffold(
            backgroundColor: Pallet.colorSecondaryDark,
            body: SingleChildScrollView(
              child: Expanded(
                child: Column(
                  children: [
                    Container(
                      child: Text(
                        "Clairelove Wallet 🌺",
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
                      child: Text(
                        "Convert",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Pallet.colorWhite,
                        ),
                      ),
                    ),

                    const Divider(
                      thickness: 2,
                      indent: 0,
                      endIndent: 280,
                      color: Colors.white70,
                      height: 3,
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
                              "Claire converts your data to cash as reward for sharing time with her and positive vibes around the app.",
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ),

                    SizedBox(height: 7,),

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
                                  height: 30,
                                  width: 60,
                                  decoration: BoxDecoration(
                                      color: Pallet.colorWhite,
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Text(
                                    "---",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "Sessions",
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
                            "+",
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
                                  height: 30,
                                  width: 60,
                                  decoration: BoxDecoration(
                                      color: Pallet.colorWhite,
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Text(
                                    userModel.adviseCount.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "Advises",
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
                                  height: 30,
                                  width: 60,
                                  decoration: BoxDecoration(
                                      color: Pallet.colorWhite,
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Text(
                                    "N10",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "Rate",
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
                                  height: 30,
                                  width: 60,
                                  decoration: BoxDecoration(
                                      color: Pallet.colorWhite,
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Text(
                                    "---",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "Total Loves",
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
                      child: Text(
                        "Withdraw",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Pallet.colorWhite,
                        ),
                      ),
                    ),

                    const Divider(
                      thickness: 2,
                      indent: 0,
                      endIndent: 280,
                      color: Colors.white70,
                      height: 3,
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
                                "Claire pays you back the cost of vibes and times you spent on the app. Isn't that cool! "
                                    "Note: Only Alter and Super Egos can request cash for now.",
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
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
                                  child: Text(
                                    userModel.currentLoveCount.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
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
                                  child: Text(
                                    userModel.currentLoveCount.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "Withdraw",
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
                                      hintText: "30000",
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
                                  width: 40,
                                  decoration: BoxDecoration(
                                      color: Pallet.colorWhite,
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: Text(
                                    "1.5",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "Ego",
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
                                  child: Text(
                                    "---",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2,),
                              Text(
                                "To Request",
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

                    Column(
                      children: [
                        Align(
                          alignment: Alignment.center,
                            child: OutlinedButton(
                              onPressed: (){
                                Navigator.pushNamed(context, AppRoutes.howAlterEgoWorks);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Pallet.colorSecondary,
                                padding: EdgeInsets.all(17),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25)),
                              ),
                              child: Text("Request Cash  🌺",
                                  style: GoogleFonts.lato(
                                      fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}