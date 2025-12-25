import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/toast.dart';
import '../splash_screen/rotate_logo.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

const int maxFailedLoadAttempts = 3;
bool isSigningIn = false;

class _LoginPage extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();
  late String _theEmail;

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }

  void _launchClairePolicySite() async {
    final Uri url = Uri.parse("https://sites.google.com/view/claire-diary/claire-privacy-policy");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showToast('Could not launch policy site');
    }
  }

  void launchEmailApp() {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dearclaireapp@gmail.com',
      query: encodeQueryParameters(<String, String>{'subject': 'Dear Claire, What\'s My Ego Code? My Email is: $_theEmail'}),
    );
    launchUrl(emailLaunchUri);
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? "ca-app-pub-2404156870680632/7375897682" : Platform.isIOS ? "ca-app-pub-2404156870680632/9223046415" : '',
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

  Future<void> _showForgotEgoCodeDialog() async {
    final TextEditingController _dialogEmailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Pallet.colorSecondaryDark.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            AppString.retrieve_ego_code_header,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(color: Pallet.colorWhite, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your email to request your code.",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.8), fontSize: 14),
              ),
              SizedBox(height: 20),
              _buildDialogTextField(_dialogEmailController),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.7))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Request Code', style: GoogleFonts.lato(color: Pallet.colorWhite, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (_dialogEmailController.text.isNotEmpty && _dialogEmailController.text.contains('@')) {
                  _theEmail = _dialogEmailController.text;
                  launchEmailApp();
                  Navigator.of(context).pop();
                } else {
                  showToast("Please enter a valid email");
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _secretCodeController.dispose();
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
                  SizedBox(height: 40),
                  RotateImage(80, 80),
                  SizedBox(height: 20),
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        AppString.ego_login_welcome,
                        speed: Duration(milliseconds: 150),
                        textAlign: TextAlign.center,
                        textStyle: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold, color: Pallet.colorWhite),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    stopPauseOnTap: true,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Welcome back to your secret space.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(fontSize: 15.0, color: Pallet.colorWhite.withValues(alpha: 0.85), fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 40),
                  _buildTextField(
                    controller: _emailController,
                    labelText: "Your secret email",
                    hintText: "Enter your registered email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@') || !value.contains('.')) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  BuildSecretCodeField(controller: _secretCodeController),
                  SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _showForgotEgoCodeDialog,
                      child: Text(
                        "Forgot Ego Code?",
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          color: Pallet.colorWhite,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Pallet.colorWhite,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildOpenUpButton(),
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorWhite.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorWhite)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorPink)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorPink, width: 2)),
        filled: true,
        fillColor: Pallet.colorWhite.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.lato(color: Pallet.colorWhite),
      decoration: InputDecoration(
        hintText: "Your registered email...",
        hintStyle: GoogleFonts.lato(color: Pallet.colorWhite.withValues(alpha: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorWhite.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorWhite)),
        filled: true,
        fillColor: Pallet.colorWhite.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildOpenUpButton() {
    return GestureDetector(
      onTap: () async {
        if (isSigningIn) return; // Prevent multiple taps
        if (_formKey.currentState!.validate()) {
          setState(() {
            isSigningIn = true;
          });
          await _firebaseServices.signIn(context, _emailController.text, _secretCodeController.text);
          // Your original ad logic and timing
          Future.delayed(Duration(seconds: 4), () {
            _showInterstitialAd();
          });
          // The firebase service handles navigation, so we just need to reset the state
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
        decoration: BoxDecoration(color: Pallet.colorWhite, borderRadius: BorderRadius.circular(30)),
        child: Center(
          child: isSigningIn
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Pallet.colorPrimary, strokeWidth: 3))
              : Text(
            AppString.open_up,
            style: GoogleFonts.lato(fontSize: 18.0, color: Pallet.colorPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPolicyText() {
    return Column(
      children: [
        Text(
          "By tapping Open Up, you are accepting Dear Claire's Terms Of Use and Privacy Policy",
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 12.0, color: Pallet.colorWhite.withValues(alpha: 0.7)),
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

// Redesigned BuildSecretCodeField to match the new UI
class BuildSecretCodeField extends StatefulWidget {
  final TextEditingController controller;

  BuildSecretCodeField({required this.controller});

  @override
  _BuildSecretCodeFieldState createState() => _BuildSecretCodeFieldState();
}

class _BuildSecretCodeFieldState extends State<BuildSecretCodeField> {
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
          icon: Icon(_isHidden ? Icons.visibility_off : Icons.visibility, color: Pallet.colorWhite.withValues(alpha: 0.7)),
          onPressed: () => setState(() => _isHidden = !_isHidden),
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorWhite.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorWhite)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorPink)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Pallet.colorPink, width: 2)),
        filled: true,
        fillColor: Pallet.colorWhite.withValues(alpha: 0.1),
      ),
    );
  }
}
