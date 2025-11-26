import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firebase_services.dart';

class RequestClaireLovesForm extends StatefulWidget {
  final int loveAmount;
  final String userId;

  const RequestClaireLovesForm(
      {Key? key, required this.loveAmount, required this.userId})
      : super(key: key);

  @override
  _RequestClaireLovesFormState createState() => _RequestClaireLovesFormState();
}

class _RequestClaireLovesFormState extends State<RequestClaireLovesForm> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _nameOnAccountController = TextEditingController();
  final TextEditingController _whyRequestController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimary,
        elevation: 0,
        title: Text('Request Conversion', style: GoogleFonts.lato(color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: Pallet.colorSecondaryDark,
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_formKey.currentState!.validate()) {
              setState(() => _currentStep += 1);
            }
          } else if (_currentStep == 1) {
            _showConfirmationDialog();
          }
        },
        onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
        steps: _getSteps(),
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('BACK', style: TextStyle(color: Colors.white70)),
                  ),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(backgroundColor: Pallet.colorPrimary),
                  child: Text(_currentStep == 0 ? 'NEXT' : 'CONFIRM', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: Text('Details', style: TextStyle(color: Colors.white)),
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                  controller: _accountNumberController, label: "Account Number"),
              _buildTextField(controller: _bankNameController, label: "Bank Name"),
              _buildTextField(
                  controller: _nameOnAccountController, label: "Name on Account"),
              _buildTextField(
                  controller: _whyRequestController, label: "Reason for request"),
            ],
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text('Confirm', style: TextStyle(color: Colors.white)),
        content: _buildConfirmationStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Pallet.colorPrimary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("You are requesting to convert:", style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 8),
        Text("${widget.loveAmount} ❤️", style: GoogleFonts.lato(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        _buildConfirmationDetail("Account Number", _accountNumberController.text),
        _buildConfirmationDetail("Bank Name", _bankNameController.text),
        _buildConfirmationDetail("Account Name", _nameOnAccountController.text),
        _buildConfirmationDetail("Reason", _whyRequestController.text),
      ],
    );
  }

  Widget _buildConfirmationDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.white70),
          children: <TextSpan>[
            TextSpan(text: "$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Pallet.colorSecondary,
          title: Text("Proceed with request?", style: TextStyle(color: Colors.white)),
          content: Text(
              "Your request will be sent for review. This action cannot be undone.", style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Proceed", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Pallet.colorPrimary),
              onPressed: () {
                _sendRequest();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendRequest() async {
    final String payload = _getPayload();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dearclaireapp@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Love Conversion Request from ${widget.userId}',
        'body': payload,
      }),
    );

    try {
      await launchUrl(emailLaunchUri);
      AppToast.show("Request sent successfully! Check your email app.");
      // Save the activity
      final firebaseServices = FirebaseServices();
      await firebaseServices.saveUserActivity(
        activityType: 'cash_out',
        activityMessage: "You requested a cash out of ${widget.loveAmount} ❤️.",
      );
      Navigator.pop(context); // Go back to the wallet
    } catch (e) {
      AppToast.showError("Could not launch email app.");
    }
  }

  String _getPayload() {
    return """
    Love Conversion Request Details:
    --------------------------------
    User ID: ${widget.userId}
    Amount to Convert: ${widget.loveAmount} ❤️
    
    Bank Details:
    - Account Number: ${_accountNumberController.text}
    - Bank Name: ${_bankNameController.text}
    - Account Name: ${_nameOnAccountController.text}
    
    Reason for Request:
    ${_whyRequestController.text}
    """
        .trim();
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _nameOnAccountController.dispose();
    _whyRequestController.dispose();
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
