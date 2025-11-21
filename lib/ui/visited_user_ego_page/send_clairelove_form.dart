import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/notification_service.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clairediary/services/data/notification_model.dart' as pushNotification;
import 'package:url_launcher/url_launcher.dart';

class SendClaireLoveForm extends StatefulWidget {
  final String amountToSend;
  final String userId; //This is the visited user's ID
  final String visitedUsersId;
  final String visitedUser;

  const SendClaireLoveForm(
      {Key? key,
      required this.amountToSend,
      required this.userId,
      required this.visitedUsersId,
      required this.visitedUser})
      : super(key: key);

  @override
  _SendClaireLoveFormState createState() => _SendClaireLoveFormState();
}

class _SendClaireLoveFormState extends State<SendClaireLoveForm> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amountToSend;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimary,
        elevation: 0,
        title: Text('Send Love to ${widget.visitedUser}',
            style: GoogleFonts.lato(color: Colors.white)),
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
        onStepCancel: _currentStep == 0
            ? null
            : () => setState(() => _currentStep -= 1),
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Pallet.colorPrimary),
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
                  controller: _amountController,
                  label: "Amount to Send",
                  isNumeric: true),
              _buildTextField(
                  controller: _reasonController,
                  label: "Reason for sending love"),
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

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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
          if (isNumeric && int.tryParse(value) == null) {
            return 'Please enter a valid number';
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
        Text("You are about to send:",
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 8),
        Text("${_amountController.text} ❤️ to ${widget.visitedUser}",
            style: GoogleFonts.lato(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        _buildConfirmationDetail("Reason", _reasonController.text),
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
            TextSpan(
                text: "$title: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
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
          title: Text("Proceed with sending love?",
              style: TextStyle(color: Colors.white)),
          content: Text(
              "This will send a request to the admin for approval. This action cannot be undone.",
              style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Proceed", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Pallet.colorPrimary),
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

  Future<void> _sendRequest() async {
    final String payload = _getPayload();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dearclaireapp@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Love Transfer Request from ${currentUser?.displayName}',
        'body': payload,
      }),
    );

    try {
      await launchUrl(emailLaunchUri);
      await _pushSendLoveNotification();
      AppToast.show("Love send request sent successfully! Check your email app.");
      Navigator.pop(context); // Go back to the wallet
    } catch (e) {
      AppToast.showError("Could not complete the request. Please try again.");
    }
  }

  String _getPayload() {
    return """
    Love Transfer Request:
    --------------------------------
    From User ID: ${currentUser?.uid}
    To User ID: ${widget.visitedUsersId}
    To User Ego Name: ${widget.visitedUser}
    Amount to Send: ${_amountController.text} ❤️
    
    Reason:
    ${_reasonController.text}
    """
        .trim();
  }

  Future<void> _pushSendLoveNotification() async {
    final sender = await firebaseServices.getUserInfo();
    final senderName = sender.nickname;

    final notificationModel = pushNotification.NotificationModel(
        topic: widget.visitedUsersId,
        data: pushNotification.Data(id: widget.visitedUsersId, route: 'wallet'),
        notification: pushNotification.Notification(
            title: "You've Received Love!",
            body: "$senderName has sent you ${_amountController.text} ❤️"));
    await notificationService.sendNotification(notificationModel.toJson());

    //Also notify admin
     final adminNotification = pushNotification.NotificationModel(
        topic: 'admin',
        data: pushNotification.Data(id: 'admin', route: 'admin_panel'),
        notification: pushNotification.Notification(
            title: "Love Transfer Request",
            body: "$senderName wants to send ${_amountController.text} ❤️ to ${widget.visitedUser}"));
    await notificationService.sendNotification(adminNotification.toJson());
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
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
