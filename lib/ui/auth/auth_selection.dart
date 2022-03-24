import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthSelectionPage extends StatelessWidget {

  CollectionReference tests =
  FirebaseFirestore.instance.collection('tests');

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Pallet.colorSplashScreen,
      body: SafeArea(
        child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Pallet.colorSplashScreen,
            child: Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset(
                      "assets/images/ic_signup_bck.png",
                      fit: BoxFit.fill,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 130,
                      ),
                      RotateImage(78, 78),
                      SizedBox(
                        height: 11,
                      ),
                      Center(
                        child: Text("Dear Claire",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 20.0,
                                color: Pallet.colorWhite,
                                //fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w800)),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Center(
                        child: Text("Secret Diary Chat",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorWhite,
                                //fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w400)),
                      ),
                      SizedBox(
                        height: 168,
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 64.0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: (){
                              Navigator.of(context).pushNamed(AppRoutes.signUp);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Container(
                                alignment: Alignment.bottomCenter,
                                width: MediaQuery.of(context).size.width,
                                height: 38,
                                decoration: BoxDecoration(
                                    color: Pallet.colorWhite,
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(6))),
                                child: Center(
                                  child: Text("Sign Up",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lato(
                                          fontSize: 12.0,
                                          color: Pallet.colorSplashScreen,
                                          //fontStyle: FontStyle.normal,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 13),
                            child: Container(
                              alignment: Alignment.bottomCenter,
                              width: MediaQuery.of(context).size.width,
                              height: 38,
                              child: Center(
                                child: ButtonTheme(
                                  minWidth: MediaQuery.of(context).size.width,
                                  child: RaisedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(AppRoutes.login);
                                    },
                                    color: Colors.transparent,
                                    shape: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: new BorderSide(color: Pallet.colorWhite)),
                                    child: Text("Login",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.lato(
                                            fontSize: 12.0,
                                            color: Pallet.colorWhite,
                                            //fontStyle: FontStyle.normal,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),

                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ])),
      ),
    );
  }
}