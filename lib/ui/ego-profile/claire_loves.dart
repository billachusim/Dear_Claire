import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/material.dart';

import '../../utils/strings.dart';

class ClaireLoves extends StatefulWidget {
  @override
  _ClaireLovesState createState() => _ClaireLovesState();
}

class _ClaireLovesState extends State<ClaireLoves> {

  @override
  Widget build(BuildContext context) {
    return
      SafeArea(
        child: Material(
          child: Scaffold(
            backgroundColor: Pallet.colorSecondaryDark,
            body: Column(
              children: [
                SizedBox(height: 4,),
                Container(
                  child: Text(
                    "Clairelove 🌺",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Pallet.colorWhite,
                    ),
                  ),
                ),

                SizedBox(height: 8,),

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
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                          "Claire converts your data to cash as reward for sharing time with her and positive vibes around the app.",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
                                "1234",
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
                                "1234",
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
                                "20",
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
                                "1234",
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
              ],
            ),
          ),
        ),
      );
  }
}