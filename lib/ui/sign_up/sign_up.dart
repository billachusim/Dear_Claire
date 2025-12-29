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
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../utils/helper.dart';
import '../splash_screen/rotate_logo.dart';

// Preserving your existing state management and ad logic
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
  TextEditingController _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }

  void _launchClairePolicySite() async {
    final Uri url =
    Uri.parse("https://sites.google.com/view/claire-diary/claire-privacy-policy");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showToast('Could not launch policy site');
    }
  }

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
  void dispose() {
    _emailController.dispose();
    _secretCodeController.dispose();
    _egoNameController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Pallet.colorWhite),
      ),
      body: Container(
        width: getDeviceWidth(context),
        height: getDeviceHeight(context),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorPrimary, Pallet.colorSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        AppString.create_ego_welcome,
                        speed: Duration(milliseconds: 150),
                        textAlign: TextAlign.center,
                        textStyle: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Pallet.colorWhite,
                        ),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    stopPauseOnTap: true,
                  ),
                  SizedBox(height: 15),
                  Text(
                    AppString.create_ego_note,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorWhite.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildTextField(
                    controller: _egoNameController,
                    labelText: AppString.egoName_label_text,
                    hintText: AppString.egoName_hint_text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please choose a name for your Ego";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    labelText: "Your email address",
                    hintText: "enter your full email address",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@') || !value.contains('.')) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  BuildPasswordField(controller: _secretCodeController),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _referralController,
                    labelText: "Referred by (Optional ID)",
                    hintText: "Enter the ID of who referred you",
                  ),
                  SizedBox(height: 40),
                  _buildCreateEgoButton(),
                  SizedBox(height: 20),
                  _buildTermsAndPolicyText(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.lato(color: Pallet.colorWhite),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.7)),
        hintStyle: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorWhite.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorWhite),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorPink),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorPink, width: 2),
        ),
        filled: true,
        fillColor: Pallet.colorWhite.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildCreateEgoButton() {
    // Re-using your original logic but applying the new button style
    return GestureDetector(
      onTap: () async {
        if (isSigningIn) return;
        if (_formKey.currentState!.validate()) {
          setState(() {
            isSigningIn = true;
          });
          // Your existing firebase call
          await _firebaseServices.register(
            context,
            _emailController.text,
            _secretCodeController.text,
            _egoNameController.text,
            referredBy: _referralController.text.trim(),
          );
          // Ad logic as per your original file
          Future.delayed(Duration(seconds: 4), () {
            _showInterstitialAd();
          });
          if (mounted) {
            setState(() {
              isSigningIn = false;
            });
          }
        } else {
          showToast(AppString.open_up_error);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Pallet.colorWhite,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: isSigningIn
              ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Pallet.colorPrimary,
              strokeWidth: 3,
            ),
          )
              : Text(
            AppString.create_ego,
            style: GoogleFonts.lato(
              fontSize: 18.0,
              color: Pallet.colorPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPolicyText() {
    return Column(
      children: [
        Text(
          "By tapping Create Ego, you are accepting Dear Claire's Terms Of Use and Privacy Policy",
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 12.0,
            color: Pallet.colorWhite.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _launchClairePolicySite,
          child: Text(
            "Tap to view Terms & Policy",
            style: GoogleFonts.lato(
              fontSize: 12.0,
              color: Pallet.colorWhite,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Pallet.colorWhite,
            ),
          ),
        ),
      ],
    );
  }
}


// Redesigned BuildPasswordField to match the new UI
class BuildPasswordField extends StatefulWidget {
  final TextEditingController controller;

  BuildPasswordField({required this.controller});

  @override
  _BuildPasswordFieldState createState() => _BuildPasswordFieldState();
}

class _BuildPasswordFieldState extends State<BuildPasswordField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isHidden,
      validator: (value) {
        if (value == null || value.length < 6) {
          return "Secret code must be at least 6 characters";
        }
        return null;
      },
      style: GoogleFonts.lato(color: Pallet.colorWhite),
      decoration: InputDecoration(
        labelText: "Your secret code",
        hintText: "At least 6 characters",
        labelStyle: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.7)),
        hintStyle: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.5)),
        suffixIcon: IconButton(
          icon: Icon(
            _isHidden ? Icons.visibility_off : Icons.visibility,
            color: Pallet.colorWhite.withValues(alpha: 0.7),
          ),
          onPressed: () {
            setState(() {
              _isHidden = !_isHidden;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorWhite.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorWhite),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorPink),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Pallet.colorPink, width: 2),
        ),
        filled: true,
        fillColor: Pallet.colorWhite.withValues(alpha: 0.1),
      ),
    );
  }
}

