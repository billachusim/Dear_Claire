// 1. Re-add background service import, remove unused constant import
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

// We no longer call AutoDiary directly from here
// import 'package:clairediary/Automations/auto_diary.dart';

class SetupAutoDiary extends StatefulWidget {
  const SetupAutoDiary({Key? key}) : super(key: key);

  @override
  _SetupAutoDiaryState createState() => _SetupAutoDiaryState();
}

class _SetupAutoDiaryState extends State<SetupAutoDiary> {
  // 2. State variable to track the service status
  bool isServiceRunning = false;

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
    _checkServiceStatus();
  }

  void _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (mounted) {
      setState(() {
        isServiceRunning = isRunning;
      });
    }
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
                'Auto Diary will automatically record moments for you in the background.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    fontSize: 16.0, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              // Display the current status of the service
              Text(
                isServiceRunning ? "Service is RUNNING" : "Service is STOPPED",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    fontSize: 16.0,
                    color: isServiceRunning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // --- BUTTON 1: ACTIVATE (Background Task) ---
              OutlinedButton(
                onPressed: () async {
                  if (!await _requestMicPermission()) return;

                  final service = FlutterBackgroundService();
                  var isRunning = await service.isRunning();
                  if (!isRunning) {
                    showToast("Starting background service...");
                    await service.startService();
                  }

                  // Give the service a moment to be ready before invoking
                  await Future.delayed(const Duration(seconds: 2));

                  // Send the command to start recording
                  service.invoke('startRecording');

                  if (mounted) setState(() { isServiceRunning = true; });

                  Navigator.of(context).pop();
                  showToast("Auto Diary has been activated!");
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Pallet.colorSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: Text("ACTIVATE ONCE 🌺",
                    style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // --- BUTTON 2: STOP ---
              OutlinedButton(
                onPressed: () {
                  final service = FlutterBackgroundService();
                  // Invoke our custom 'stopService' event
                  service.invoke('stopService');
                  if (mounted) setState(() { isServiceRunning = false; });
                  showToast("Auto Diary service stopped.");
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: Text("STOP SERVICE",
                    style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

