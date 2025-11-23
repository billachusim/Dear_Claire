import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlterEgoLoginPage extends StatefulWidget {
  const AlterEgoLoginPage({Key? key}) : super(key: key);

  @override
  _AlterEgoLoginPageState createState() => _AlterEgoLoginPageState();
}

class _AlterEgoLoginPageState extends State<AlterEgoLoginPage> {
  final _emailController = TextEditingController();
  final _secretCodeController = TextEditingController();
  final _firebaseServices = FirebaseServices();
  final _formKey = GlobalKey<FormState>();

  // --- NEW STATE VARIABLES FOR ENHANCED UI ---
  bool _isLoading = false;
  bool _areFieldsFilled = false;
  final FocusNode _claireIdFocus = FocusNode();
  final FocusNode _secretCodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen to changes in the text fields to enable/disable the login button
    _emailController.addListener(_updateButtonState);
    _secretCodeController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _areFieldsFilled =
          _emailController.text.isNotEmpty && _secretCodeController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _secretCodeController.dispose();
    _claireIdFocus.dispose();
    _secretCodeFocus.dispose();
    super.dispose();
  }

  // --- NEW: Central Login Logic ---
  void _handleLogin() async {
    if (!_formKey.currentState!.validate() || !_areFieldsFilled || _isLoading) return;

    setState(() => _isLoading = true);

    final claireId = _emailController.text.trim();
    final secretCode = _secretCodeController.text.trim();

    final isLoginSuccessful = await _firebaseServices.getUserAlterEgo(context, claireId, secretCode);

    // Only save credentials if login was truly successful
    if (isLoginSuccessful) {
      // The navigation is handled inside getUserAlterEgo.
      // But we save the credentials here after confirmation.
      sharedPreference.setAlterEgoId(claireId);
      sharedPreference.setAlterEgoAccessCode(secretCode);
      print("Alter Ego credentials verified and saved.");
    } else {
      // If login failed, show an error and stop the loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Failed. Please check your credentials."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
    // Note: No need to set _isLoading to false on success, as the page will be replaced.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark, // Darker theme for immersion
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Alter Ego',
          style: GoogleFonts.montserrat( // New, more stylish font
            fontSize: 22.0,
            color: Pallet.colorWhite.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // --- NEW: Animated Keyhole/Lock Icon ---
                Icon(
                  Icons.key_rounded,
                  size: 60,
                  color: Pallet.colorSecondary.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                // --- NEW: Evocative Welcome Text ---
                Text(
                  "The other side awaits.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 24.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Enter your credentials to switch.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    color: Pallet.colorTextGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 60),
                // --- IMPROVED TextFields ---
                _buildTextFormField(
                  controller: _emailController,
                  focusNode: _claireIdFocus,
                  hintText: "Your unique ClaireId",
                  labelText: "ClaireId",
                  icon: Icons.person_search_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "ClaireId cannot be empty";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                _buildTextFormField(
                  controller: _secretCodeController,
                  focusNode: _secretCodeFocus,
                  hintText: "Your secret code",
                  labelText: "Secret Code",
                  icon: Icons.password_rounded,
                  isSecret: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Secret Code cannot be empty";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                // --- NEW: Smart, Animated SignIn Button ---
                _signInBtn(),
                const SizedBox(height: 50),
                // --- IMPROVED "Request Access" flow ---
                Text(
                  "Don't have access?",
                  style: TextStyle(
                    color: Pallet.colorTextGray,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                _requestAccessBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Reusable TextFormField Widget for clean code ---
  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required String labelText,
    required IconData icon,
    bool isSecret = false,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isSecret,
      validator: validator,
      textInputAction: isSecret ? TextInputAction.done : TextInputAction.next,
      style: GoogleFonts.lato(color: Pallet.colorWhite, fontSize: 16.0),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Pallet.colorTextGray, size: 20),
        labelStyle: TextStyle(color: Pallet.colorTextGray),
        hintStyle: TextStyle(color: Pallet.colorTextGray.withOpacity(0.5)),
        filled: true,
        fillColor: Pallet.colorPrimary.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Pallet.colorTextGray.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Pallet.colorSecondary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      ),
    );
  }

  // --- REBUILT SignIn Button ---
  Widget _signInBtn() {
    return Material(
      color: _areFieldsFilled ? Pallet.colorSecondary : Pallet.colorTextGray,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: _handleLogin,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: double.infinity,
          height: 55,
          alignment: Alignment.center,
          child: _isLoading
              ? const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3.0,
          )
              : Text(
            'SWITCH',
            style: GoogleFonts.montserrat(
              fontSize: 16.0,
              color: _areFieldsFilled ? Pallet.colorWhite : Colors.black54,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- REBUILT Request Access Button ---
  Widget _requestAccessBtn() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks);
      },
      child: Text(
        'Learn More & Request Access',
        style: GoogleFonts.lato(
          fontSize: 17.0,
          color: Pallet.colorSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
