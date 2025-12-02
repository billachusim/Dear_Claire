import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../data/models/transaction_model.dart' as t_model;
import '../../helpers/toast_helper.dart';
import '../../services/data/notification_model.dart' as push_notification;
import '../../services/notification_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/constant.dart';

class RequestFeatureForm extends StatefulWidget {
  final Session session;
  const RequestFeatureForm({Key? key, required this.session}) : super(key: key);

  @override
  _RequestFeatureFormState createState() => _RequestFeatureFormState();
}

class _RequestFeatureFormState extends State<RequestFeatureForm> {
  final TextEditingController _whyFeatureController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  final TransactionService _transactionService = TransactionService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Pallet.colorPrimaryDark : Pallet.colorPrimary,
        centerTitle: true,
        title: Text('Request Feature',
            style: GoogleFonts.lato(
                fontSize: 26.0,
                color: Pallet.colorWhite,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildInfoSection(isDarkMode),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _whyFeatureController,
                labelText: 'Write A Short Explanation',
                hintText: 'I will like to...',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Explain Why Feature';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSubmitButton(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey[800] : Pallet.colorGrey.withOpacity(0.3),
      padding: const EdgeInsets.all(20.0),
      child: Text(AppString.request_feature_form_header,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
              fontSize: 13.0,
              color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildSubmitButton(bool isDarkMode) {
    return ElevatedButton(
      onPressed: _submitRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? Pallet.colorPrimaryDark : Pallet.colorPrimary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Submit Request',
        style: GoogleFonts.lato(
            fontSize: 18, color: Pallet.colorWhite, fontWeight: FontWeight.bold),
      ),
    );
  }


  // In /lib/ui/featured/request_feature_form.dart

  // In /lib/ui/featured/request_feature_form.dart

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // --- Love count check remains the same ---
      final _user = await firebaseServices.getUserInfo();
      if (_user.currentLoveCount < 1000) {
        showToast(
            message:
            'You need at least 1000 Loves to submit a feature request.');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final title = widget.session.title!;
      final message = _whyFeatureController.text;
      final egoName = widget.session.userNickname!;

      final isAbusive = await _checkForAbusiveLanguage(title, message, egoName);

      if (isAbusive) {
        showToast(
            message:
            'Your request contains inappropriate language and cannot be submitted.');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (_currentUser != null) {
        // --- 1. PERFORM THE TREASURY TRANSACTION ---
        final bool success = await firebaseServices.updateTreasuryAndUser(
          userId: _currentUser!.uid,
          amount: 1000,
          type: t_model.TransactionType.debit,
          userTransactionDescription: "1000❤️ paid to feature a session.",
          metadata: {
            'sessionId': widget.session.sessionId,
            'sessionTitle': widget.session.title,
            'reason': 'feature_request'
          },
          forLoveTransfer: 1000, // Stat tracking
        );

        // --- 2. PROCEED ONLY IF TRANSACTION WAS SUCCESSFUL ---
        if (success) {
          // --- START: NEW TARGETED NOTIFICATION LOGIC ---
          try {
            // Fetch the current user's document to get their FCM token.
            // The `_user` object from `getUserInfo()` already has it.
            final userToken = _user.fcmId;

            if (userToken != null && userToken.isNotEmpty) {
              await notificationService.sendNotification({
                "token": userToken,
                "notification": {
                  "title": "Session Feature Request Submitted!",
                  "body":
                  "1000 ❤️ were successfully used to feature your session."
                },
                "data": {
                  // Navigate user to their wallet to see the deduction
                  "route": "wallet"
                }
              });
              logger.d("Successfully sent 'Feature Session' notification.");
            }
          } catch (e) {
            print("Failed to send 'Feature Session' push notification: $e");
          }
          // --- END: NEW TARGETED NOTIFICATION LOGIC ---

          // 3. Feature the session and provide feedback.
          await firebaseServices.featureSession(widget.session.sessionId!);
          showToast(message: 'Your session has been featured successfully!');
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          showToast(
              message: "Transaction failed. Please check your Love balance.");
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }





  Future<bool> _checkForAbusiveLanguage(String title, String message, String egoName) async {
    const apiKey = 'AIzaSyA2Nh3m4lupDBewWT_Z0ZBkwpjXY9x6Fi4';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Is the following text abusive, illicit, or harmful in any way? Answer with only "true" or "false".\n\n$title. $message. $egoName'
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['candidates'][0]['content']['parts'][0]['text'];
      return result.toLowerCase() == 'true';
    } else {
      // Safely assume not abusive if API fails
      return false;
    }
  }
}
