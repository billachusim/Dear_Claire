import 'dart:async';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: To persist ritual state

class SetupAutoDiary extends StatefulWidget {
  const SetupAutoDiary({Key? key}) : super(key: key);

  @override
  _SetupAutoDiaryState createState() => _SetupAutoDiaryState();
}

class _SetupAutoDiaryState extends State<SetupAutoDiary>
    with TickerProviderStateMixin {
  bool isServiceRunning = false;
  TimeOfDay? _selectedTime;
  TimeOfDay? _dailyRitualTime; // NEW: State for the daily ritual

  late AnimationController _pulseController;
  late AnimationController _narrativeController;
  late Animation<double> _pulseAnimation;

  int _narrativeIndex = 0;
  final List<String> _narratives = [
    "Your real alter ego is within.",
    "Helping you without being seen.",
    "A psychical window to your soul.",
    "Ready to listen, always.",
    "Record your diary... without touching your phone.",
  ];

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadDailyRitual(); // NEW: Load saved ritual time on init

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _narrativeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _narrativeIndex = (_narrativeIndex + 1) % _narratives.length;
        });
        _narrativeController.forward(from: 0);
      }
    });
    _narrativeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _narrativeController.dispose();
    super.dispose();
  }

  // --- NEW: Methods to save, load, and cancel the Daily Ritual ---

  Future<void> _loadDailyRitual() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('dailyRitualHour');
    final minute = prefs.getInt('dailyRitualMinute');
    if (hour != null && minute != null) {
      if (mounted) {
        setState(() {
          _dailyRitualTime = TimeOfDay(hour: hour, minute: minute);
        });
      }
    }
  }

  Future<void> _saveDailyRitual(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyRitualHour', time.hour);
    await prefs.setInt('dailyRitualMinute', time.minute);
  }

  Future<void> _clearDailyRitual() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dailyRitualHour');
    await prefs.remove('dailyRitualMinute');
    final service = FlutterBackgroundService();
    service.invoke('cancelDailyRitual'); // Tell the service to stop the timer
    if (mounted) {
      setState(() {
        _dailyRitualTime = null;
      });
    }
    showToast("Your daily ritual has been cancelled.");
  }


  // --- Existing Methods (with minor updates for new logic) ---

  void _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (mounted) {
      setState(() {
        isServiceRunning = isRunning;
        if (isRunning) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      });
    }
  }

  Future<bool> _requestMicPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      showToast("Microphone permission is required to speak.");
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    }
    return true;
  }

  // Updated to distinguish between one-time and daily schedules
  Future<void> _selectTime(BuildContext context, {bool isDailyRitual = false}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (_dailyRitualTime ?? _selectedTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Pallet.colorSecondary,
              onPrimary: Colors.white,
              surface: Pallet.colorSecondary.withOpacity(0.1),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black.withOpacity(0.8),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isDailyRitual) {
        _scheduleDailyRitual(picked);
      } else {
        setState(() { _selectedTime = picked; });
        _scheduleAutoDiary();
      }
    }
  }

  // UNCHANGED
  void _scheduleAutoDiary() async {
    if (_selectedTime == null) {
      showToast("Please select a time first.");
      return;
    }
    if (!await _requestMicPermission()) return;
    final service = FlutterBackgroundService();
    if (!isServiceRunning) {
      await service.startService();
      await Future.delayed(const Duration(seconds: 1));
    }
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
        now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }
    service.invoke('scheduleRecording', {
      'time': scheduledDateTime.toIso8601String(),
    });
    if (mounted) setState(() { isServiceRunning = true; });
    final formattedDate = DateFormat('MMM d, yyyy').format(scheduledDateTime);
    final formattedTime = _selectedTime!.format(context);
    showToast("An intention is set for $formattedDate at $formattedTime.");
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // UNCHANGED
  void _speakNow() async {
    if (!await _requestMicPermission()) return;
    final service = FlutterBackgroundService();
    if (!isServiceRunning) {
      await service.startService();
      await Future.delayed(const Duration(seconds: 1));
    }
    service.invoke('instantRecording');
    if (mounted) setState(() { isServiceRunning = true; });
    showToast("Your session has begun. Speak freely.");
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // NEW: Function to handle scheduling the daily ritual
  void _scheduleDailyRitual(TimeOfDay time) async {
    if (!await _requestMicPermission()) return;
    final service = FlutterBackgroundService();
    if (!isServiceRunning) {
      await service.startService();
      await Future.delayed(const Duration(seconds: 1));
    }
    service.invoke('scheduleDailyRitual', {
      'hour': time.hour,
      'minute': time.minute,
    });
    await _saveDailyRitual(time); // Save the time to persistent storage
    if (mounted) {
      setState(() {
        isServiceRunning = true;
        _dailyRitualTime = time;
      });
    }
    showToast("Your daily ritual is set for ${time.format(context)} each day.");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('The Sanctuary',
            style: GoogleFonts.lato(color: Colors.white.withOpacity(0.8))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeartbeatOrb(),
                const SizedBox(height: 40),

                // All three action buttons
                _buildActionButton(
                  onTap: _speakNow,
                  icon: Icons.mic_none_rounded,
                  label: 'Speak Now',
                  color: Colors.cyan.withOpacity(0.7),
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  onTap: () => _selectTime(context, isDailyRitual: false),
                  icon: Icons.watch_later_outlined,
                  label: 'Whisper Later',
                  color: Pallet.colorSecondary.withOpacity(0.7),
                ),
                const SizedBox(height: 25),

                // NEW: Daily Ritual Button
                _dailyRitualTime == null
                    ? _buildActionButton(
                  onTap: () => _selectTime(context, isDailyRitual: true),
                  icon: Icons.sync_rounded,
                  label: 'Set Daily Ritual',
                  color: Colors.amber.withOpacity(0.7),
                )
                    : _buildActiveRitualDisplay(), // Show this if a ritual is active

                const SizedBox(height: 60),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // --- NEW: Widget to display the active daily ritual ---
  Widget _buildActiveRitualDisplay() {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withOpacity(0.7), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_rounded, color: Colors.amber),
          const SizedBox(width: 12),
          Text('Ritual at ${_dailyRitualTime!.format(context)}',
              style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9))),
          const SizedBox(width: 8),
          // Add a small cancel button
          GestureDetector(
            onTap: _clearDailyRitual,
            child: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  // --- Unchanged Helper Methods ---
  Widget _buildAnimatedBackground() {
    return Stack(
      children: List.generate(30, (index) {
        final size = Random().nextDouble() * 3;
        final top = Random().nextDouble() * MediaQuery.of(context).size.height;
        final left = Random().nextDouble() * MediaQuery.of(context).size.width;
        return Positioned(
          top: top,
          left: left,
          child: CircleAvatar(
            radius: size,
            backgroundColor: Colors.white.withOpacity(Random().nextDouble() * 0.5),
          ),
        );
      }),
    );
  }

  Widget _buildHeartbeatOrb() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isServiceRunning
                  ? Pallet.colorSecondary.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.4),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
            child: Icon(
              Icons.psychology_alt_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 60,
            )),
      ),
    );
  }

  Widget _buildActionButton(
      {required VoidCallback onTap,
        required IconData icon,
        required String label,
        required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: Column(
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: _narrativeController, curve: Curves.easeIn),
            ),
            child: Text(
              _narratives[_narrativeIndex],
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (isServiceRunning && _dailyRitualTime == null)
            GestureDetector(
              onTap: () {
                final service = FlutterBackgroundService();
                service.invoke('stopService');
                if (mounted) {
                  setState(() {
                    isServiceRunning = false;
                    _pulseController.stop();
                  });
                }
                showToast("The connection has been paused.");
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Text("Pause Connection",
                    style: GoogleFonts.lato(
                        color: Colors.red.withOpacity(0.8))),
              ),
            ),
        ],
      ),
    );
  }
}
