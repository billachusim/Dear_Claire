// 1. REMOVE background service import, ADD auto_diary import
import 'package:clairediary/Automations/auto_diary.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/constant.dart';

class SetupAutoDiary extends StatefulWidget {
  const SetupAutoDiary({Key? key}) : super(key: key);

  @override
  _SetupAutoDiaryState createState() => _SetupAutoDiaryState();
}

class _SetupAutoDiaryState extends State<SetupAutoDiary> {
  // 2. NEW STATE VARIABLE for the loading indicator
  bool _isRecording = false;

  /// Asks for microphone permission. Returns true if granted, false otherwise.
  Future<bool> _requestMicPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      showToast("Microphone permission is required for Auto Diary.");
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Just request permission on init. No need to check service status now.
    _requestMicPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallet.colorSecondary,
        centerTitle: false,
        automaticallyImplyLeading: true,
        title: Text('Auto Diary Mode',
            textAlign: TextAlign.start,
            maxLines: 1,
            style: GoogleFonts.lato(
                fontSize: 24.0,
                color: Pallet.colorWhite,
                fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Auto Diary Foreground Test',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 32),

              // --- BUTTON 1: ACTIVATE (FOREGROUND TEST) ---
              OutlinedButton(
                // 3. COMPLETELY NEW onPressed LOGIC
                onPressed: _isRecording
                    ? null // Disable button while recording
                    : () async {
                  if (!await _requestMicPermission()) return;

                  // Start loading indicator
                  setState(() {
                    _isRecording = true;
                  });

                  showToast("Recording started... please wait 15 seconds.");

                  // Call the recording method directly
                  await AutoDiary.startRecording();

                  showToast("Process complete! A new diary session has been created.");

                  // Stop loading indicator
                  setState(() {
                    _isRecording = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Pallet.colorSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                // 4. Show loading indicator or text
                child: _isRecording
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : Text("START FOREGROUND TEST 🌺",
                    style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(height: 20),
              // We can hide the STOP button as it's not needed for this test
            ],
          ),
        ),
      ),
    );
  }
}
