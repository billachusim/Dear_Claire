import 'dart:io';

import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/helper.dart';
import '../splash_screen/rotate_logo.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPage createState() => _SignUpPage();
}

const int maxFailedLoadAttempts = 3;

bool isSigningIn = false;



class _SignUpPage extends State<SignUpPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _secretCodeController = TextEditingController();
  TextEditingController _egoNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();


  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }


  void _launchClairePolicySite() async {
    final Uri url = Uri.parse("https://sites.google.com/view/claire-diary/claire-privacy-policy");
    await canLaunchUrl(url)
        ? await launchUrl(url)
        : throw 'Could not launch site';
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  // Create interstitial ad.

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/6980026455"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/1979266624"
          : '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createInterstitialAd();
          }
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimary,
        centerTitle: true,
        title: Text('Create Ego',
            textAlign: TextAlign.start,
            maxLines: 1,
            style: GoogleFonts.lato(
                fontSize: 26.0,
                color: Pallet.colorWhite,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Container(
                height: getDeviceHeight(context),
                width: getDeviceWidth(context),
                decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    AppImages.appChatBg,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    //mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            AppString.create_ego_welcome,
                            speed: Duration(milliseconds: 250),
                            textStyle: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Pallet.colorPrimaryDark,
                            ),
                          ),
                        ],
                        isRepeatingAnimation: false,
                        stopPauseOnTap: true,
                      ),

                      SizedBox(
                        height: 2,
                      ),
                      Text(AppString.create_ego_note,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.lato(
                              fontSize: 15.0,
                              color: Pallet.colorSecondaryDark,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 25,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(AppString.create_ego_sub_note,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400)),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          Container(
                            color: Pallet.colorWhite,
                            child: TextFormField(
                                onChanged: (value) {},
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Enter Email";
                                  } else if (value.length < 4) {
                                    return "Email should be up to 4 digits";
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                                controller: _emailController,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(RegExp("[ ]")),
                                ],
                                decoration: new InputDecoration(
                                  hintText: "sososo@sososo.com",
                                  labelText: "Type a full Email Address",
                                  labelStyle:
                                      TextStyle(color: Pallet.colorTextGray),
                                  focusedBorder: new OutlineInputBorder(
                                      borderSide: new BorderSide(
                                          color: Pallet.colorPrimary)),
                                  enabledBorder: new OutlineInputBorder(
                                      borderSide: new BorderSide(
                                          color: Pallet.colorTextGray)),
                                  contentPadding:
                                      EdgeInsets.only(right: 15, left: 15),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Pallet.colorBlack,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w400)),
                          ),

                          SizedBox(
                            height: 25,
                          ),

                          Container(
                            color: Pallet.colorWhite,
                            child: TextFormField(
                                onChanged: (value) {},
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Enter nickname";
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                controller: _egoNameController,
                                decoration: new InputDecoration(
                                  hintText: AppString.egoName_hint_text,
                                  labelText: AppString.egoName_label_text,
                                  labelStyle:
                                  TextStyle(color: Pallet.colorTextGray),
                                  focusedBorder: new OutlineInputBorder(
                                      borderSide: new BorderSide(
                                          color: Pallet.colorPrimary)),
                                  enabledBorder: new OutlineInputBorder(
                                      borderSide: new BorderSide(
                                          color: Pallet.colorTextGray)),
                                  contentPadding:
                                  EdgeInsets.only(right: 15, left: 15),
                                ),
                                keyboardType: TextInputType.text,
                                cursorColor: Pallet.colorBlack,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w400)),
                          ),

                          SizedBox(
                            height: 25,
                          ),
                          Container(
                            color: Pallet.colorWhite.withAlpha(20),
                            child: BuildPasswordField(
                                "******", _secretCodeController),
                          ),


                          SizedBox(height: 5,),

                          Container(
                            alignment: Alignment.center,
                            child: Text("By tapping Create Ego, you are accepting Dear Claire's Terms Of Use and Privacy Policy",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorPrimary,
                                    fontWeight: FontWeight.w600)),
                          ),
                          GestureDetector(
                            onTap: _launchClairePolicySite,
                            child: Container(

                              alignment: Alignment.center,
                              child: Text("Tap here to open Terms Of Use and Privacy Policy",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.lato(
                                      fontSize: 10.0,
                                      color: Pallet.colorBlue,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),

                          SizedBox(
                            height: 35,
                          ),

                          Visibility(
                            visible: isSigningIn,
                            child: Center(
                              child: Column(
                                children: [
                                  RotateImage(45, 45),
                                  Text('Creating Ego...')
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 6,),

                          GestureDetector(
                            onTap: () async {
                              var validate = _formKey.currentState!.validate();
                              if (validate) {
                                isSigningIn = true;
                                setState(() {});
                                _createInterstitialAd();
                                await _firebaseServices.register(
                                    context,
                                    _emailController.text,
                                    _secretCodeController.text,
                                    _egoNameController.text);
                              }
                              else showToast(AppString.open_up_error);
                              isSigningIn = false;
                              Future.delayed(Duration(seconds: 4), () {
                                _showInterstitialAd();
                              });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: Pallet.colorWhite,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6)),
                                  gradient: LinearGradient(colors: [
                                    Pallet.colorPrimary,
                                    Pallet.colorPrimaryDark
                                  ])),
                              child: Center(
                                child: Text(AppString.create_ego,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        fontSize: 16.0,
                                        color: Pallet.colorWhite,
                                        //fontStyle: FontStyle.normal,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 44,),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.login);
                          },
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppString.i_already_have_ego,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        fontSize: 12.0,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500)),
                                SizedBox(
                                  width: 2,
                                ),
                                Text(AppString.open_up,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        fontSize: 13.0,
                                        color: Pallet.colorPrimaryDark,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
            ),
          ),

        ]),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _secretCodeController.dispose();
    isSigningIn = false;
    _interstitialAd?.dispose();
    super.dispose();
  }
}

class BuildPasswordField extends StatefulWidget {
  final hintText;
  final _secretCodeController;

  BuildPasswordField(this.hintText, this._secretCodeController);

  @override
  _BuildPasswordFieldState createState() => _BuildPasswordFieldState();
}

class _BuildPasswordFieldState extends State<BuildPasswordField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Pallet.colorWhite,
      child: TextFormField(
        onChanged: (value) {
        },
        validator: (value) {
          if (value!.isEmpty) {
            return "Enter Ego code. Ego Code means password.";
          } else if (value.length < 4) {
            return "Ego code should be up to 4 digits";
          }
          return null;
        },
        textInputAction: TextInputAction.next,
        controller: widget._secretCodeController,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: "Choose Ego Code, up to 6 digits. It means password.",
          labelStyle: TextStyle(color: Pallet.colorTextGray),
          focusedBorder: new OutlineInputBorder(
              borderSide: new BorderSide(color: Pallet.colorPrimary)),
          enabledBorder: new OutlineInputBorder(
              borderSide: new BorderSide(
            color: Pallet.colorTextGray,
          )),
          suffixIcon: Container(
            width: 55,
            child: IconButton(
              color: Pallet.colorTextGray,
              onPressed: _togglePasswordView,
              icon: _isHidden
                  ? const Icon(Icons.visibility)
                  : const Icon(Icons.visibility_off),
            ),
          ),
          contentPadding: EdgeInsets.only(right: 15, left: 15),
        ),
        keyboardType: TextInputType.text,
        cursorColor: Pallet.colorBlack,
        style: GoogleFonts.lato(
            fontSize: 12.0,
            color: Pallet.colorBlack,
            //fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400),
        obscureText: _isHidden,
      ),
    );
  }

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }
}
