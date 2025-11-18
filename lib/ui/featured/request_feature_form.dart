import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../helpers/toast_helper.dart';
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

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      final _user = await firebaseServices.getUserInfo();
      if (_user.currentLoveCount < 1000) {
        showToast(message: 'You need at least 1000 Loves to submit a feature request.');
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
        showToast(message: 'Your request contains inappropriate language and cannot be submitted.');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      await firebaseServices.deductLoves(1000);
      await firebaseServices.featureSession(widget.session.sessionId!);

      showToast(message: 'Your session has been featured successfully!');
      Navigator.pop(context);

      setState(() {
        _isProcessing = false;
      });
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
