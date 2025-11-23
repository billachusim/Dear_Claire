import 'package:animate_do/animate_do.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- SERVICE AND ROUTE IMPORTS (ASSUMED) ---
// import 'package:clairediary/services/firebase_services.dart';
// import 'package:clairediary/ui/routes/routes.dart';

class AlterEgoRegistration extends StatefulWidget {
  const AlterEgoRegistration({Key? key}) : super(key: key);

  @override
  _AlterEgoRegistrationState createState() => _AlterEgoRegistrationState();
}

class _AlterEgoRegistrationState extends State<AlterEgoRegistration> {
  // --- FORM CONTROLLERS AND KEYS ---
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Personal Details
  final _fullNameController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _ageController = TextEditingController();
  final _nameOfSchoolController = TextEditingController();

  // Step 2: Contact & Socials
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameOfBestFriendController = TextEditingController();
  final _bestFriendNumController = TextEditingController();
  final _facebookNameController = TextEditingController();
  final _instagramUserNameController = TextEditingController();
  final _twitterUserNameController = TextEditingController();

  // Step 3: The Pledge
  final _shortBioController = TextEditingController();
  Map<String, bool> _pledgeValues = {
    "value1": false,
    "value2": false,
    "value3": false,
    "value4": false,
    "value5": false,
    "value6": false,
    "value7": false,
  };

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _fullNameController.dispose();
    _fullAddressController.dispose();
    _ageController.dispose();
    _nameOfSchoolController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nameOfBestFriendController.dispose();
    _bestFriendNumController.dispose();
    _facebookNameController.dispose();
    _instagramUserNameController.dispose();
    _twitterUserNameController.dispose();
    _shortBioController.dispose();
    super.dispose();
  }

  // --- SUBMISSION LOGIC ---
  void _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      // Check if all pledges are checked
      if (_pledgeValues.containsValue(false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must agree to all pledges to proceed.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // --- TODO: REPLACE WITH YOUR FIREBASE LOGIC ---
      // This is where you would collect all the data and send it to Firebase.
      // Example:
      // final success = await firebaseServices.submitAlterEgoApplication(
      //   fullName: _fullNameController.text,
      //   ...etc
      // );

      // For demonstration, we'll simulate a network call
      await Future.delayed(const Duration(seconds: 2));
      final success = true; // Assume success

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Pallet.colorPrimary,
        title: Text("Initiation Complete", style: GoogleFonts.montserrat(color: Pallet.colorSecondary, fontWeight: FontWeight.bold)),
        content: Text("Welcome to the inner circle. Your ClaireId and Secret Code will be sent to your email within 24 hours.", style: GoogleFonts.lato(color: Colors.white, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Navigator.of(context).pushReplacementNamed(AppRoutes.home); // Navigate home
            },
            child: Text("RETURN TO EGO", style: TextStyle(color: Pallet.colorSecondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final stepperBackgroundColor = isDarkMode ? Pallet.colorSecondaryDark : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: stepperBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Pallet.colorSecondaryDark : Pallet.colorSecondary,
        elevation: 0,
        centerTitle: true,
        title: Text('Alter Ego Initiation',
            style: GoogleFonts.montserrat(
                fontSize: 22.0,
                color: Pallet.colorWhite,
                fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
                primary: Pallet.colorSecondary,
                onPrimary: Colors.white
            ),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              final isLastStep = _currentStep == getSteps().length - 1;
              if (isLastStep) {
                _submitApplication();
              } else {
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
            onStepTapped: (step) => setState(() => _currentStep = step),
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == getSteps().length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Pallet.colorSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text(isLastStep ? 'SUBMIT PLEDGE' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    if (_currentStep != 0)
                      const SizedBox(width: 12),
                    if (_currentStep != 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              );
            },
            steps: getSteps(),
          ),
        ),
      ),
    );
  }

  List<Step> getSteps() => [
    Step(
      isActive: _currentStep >= 0,
      title: Text('Personal Details',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            Text(AppString.alter_ego_orientation_first_header,
                style: GoogleFonts.lato(
                    color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 24),
            _buildTextFormField(
                controller: _fullNameController,
                labelText: "Full Name",
                hintText: "e.g. Mercy Ezulumalu Achusim"),
            _buildTextFormField(
                controller: _fullAddressController,
                labelText: "Full Address",
                hintText: "e.g. No 16 Solo Ogun street..."),
            _buildTextFormField(
                controller: _ageController,
                labelText: "Age",
                hintText: "e.g. 16",
                keyboardType: TextInputType.number),
            _buildTextFormField(
                controller: _nameOfSchoolController,
                labelText: "School or Occupation",
                hintText: "e.g. University Of Mumbai"),
          ],
        ),
      ),
    ),
    Step(
      isActive: _currentStep >= 1,
      title: Text('Contact & Socials',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            Text(
                "Provide secure ways for us to verify and contact you. Your information is kept confidential.",
                style: GoogleFonts.lato(
                    color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 24),
            _buildTextFormField(
                controller: _phoneController,
                labelText: "Phone Number",
                hintText: "e.g. +2348188578955",
                keyboardType: TextInputType.phone),
            _buildTextFormField(
                controller: _emailController,
                labelText: "Email Address",
                hintText: "This will be used for your login",
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                v!.isEmpty || !v.contains('@') ? "Enter a valid email" : null),
            _buildTextFormField(
                controller: _nameOfBestFriendController,
                labelText: "Name of Best Friend or Relative"),
            _buildTextFormField(
                controller: _bestFriendNumController,
                labelText: "Their Phone Number",
                keyboardType: TextInputType.phone),
            _buildTextFormField(
                controller: _facebookNameController,
                labelText: "Facebook Name (Optional)",
                isRequired: false),
            _buildTextFormField(
                controller: _instagramUserNameController,
                labelText: "Instagram Handle (Optional)",
                isRequired: false),
            _buildTextFormField(
                controller: _twitterUserNameController,
                labelText: "Twitter Handle (Optional)",
                isRequired: false),
          ],
        ),
      ),
    ),
    Step(
      isActive: _currentStep >= 2,
      title: Text('The Pledge',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Being an Alter Ego is a responsibility. You are a guide, a confidant, and a protector of this space. Answer the questions below to proceed.",
                style: GoogleFonts.lato(
                    color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 12),
            _buildTextFormField(
                controller: _shortBioController,
                labelText: "Your Motivation",
                hintText:
                "Briefly describe why you want to be an Alter Ego",
                maxLines: 3),
            const SizedBox(height: 20),
            Text('The Initiation Questions:',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // --- FIX STARTS HERE ---
            // Replaced the placeholder pledges with your original questions.
            _buildPledgeCheckbox("value1",
                "Are you truly interested in becoming an Alter-Ego not just to read random people's Diary Sessions but to reply to them with happy vibes and good advises?"),
            _buildPledgeCheckbox("value2",
                "Do you believe that the world will be a better place if people treat other people like themselves wish to be treated?"),
            _buildPledgeCheckbox("value3",
                "Do you believe that humility and selfless leadership are good practises for life?"),
            _buildPledgeCheckbox("value4",
                "Did you first learn about Claire on social media?"),
            _buildPledgeCheckbox("value5",
                "Have you rated Dear Claire five stars with a short review?"),
            _buildPledgeCheckbox("value6",
                "Do you truly believe in the Claire Project? That everyone deserves a true friend in need and indeed?"),
            _buildPledgeCheckbox(
                "value7", "Are you ready to become Claire now?"),
            // --- FIX ENDS HERE ---
          ],
        ),
      ),
    ),
  ];



  // Reusable widget for text fields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool isRequired = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return '$labelText cannot be empty';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          alignLabelWithHint: true,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.black.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Pallet.colorSecondary, width: 2),
          ),
        ),
      ),
    );
  }

  // Reusable widget for pledge checkboxes
  Widget _buildPledgeCheckbox(String key, String title) {
    // --- NEW: Added dark mode check for better text color ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.grey.shade300 : Colors.black87;

    return CheckboxListTile(
      value: _pledgeValues[key],
      onChanged: (bool? value) {
        setState(() {
          _pledgeValues[key] = value ?? false;
        });
      },
      title: Text(title, style: GoogleFonts.lato(color: textColor, height: 1.4)), // Applied color and improved line height
      activeColor: Pallet.colorSecondary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

}

