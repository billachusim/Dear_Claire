import 'dart:async';
import 'dart:math';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/transaction_model.dart' as t_model;
import '../services/user_model.dart' as t_model;

enum _SanctuaryView { main, whisper, ritual, configure }

class SetupAutoDiary extends StatefulWidget {
  const SetupAutoDiary({Key? key}) : super(key: key);

  @override
  _SetupAutoDiaryState createState() => _SetupAutoDiaryState();
}

class _SetupAutoDiaryState extends State<SetupAutoDiary>
    with TickerProviderStateMixin {
  // --- UI & Service State ---
  bool _isProcessing = false;
  bool isServiceRunning = false;
  TimeOfDay? _dailyRitualTime;
  _SanctuaryView _currentView = _SanctuaryView.main;
  TimeOfDay? _tempSelectedTime;

  // --- Animation State ---
  late AnimationController _pulseController;
  late AnimationController _narrativeController;
  late AnimationController _introNarrativeController;
  late Animation<double> _pulseAnimation;
  int _narrativeIndex = 0;
  int _introNarrativeIndex = 0;

  final List<String> _introNarratives = [
    "Activate your inner companion.",
    "Let your spirit listen and guide you.",
    "Journals your day, even without you touching your phone.",
    "Your alter ego is always within."
  ];

  final List<String> _footerNarratives = [
    "Your real alter ego is within.",
    "Helping you without being seen.",
    "A psychical window to your soul.",
    "Ready to listen, always.",
  ];

  // --- User Settings State ---
  final TextEditingController _titleController = TextEditingController();
  String _selectedMood = Constant.USER_SESSION_MOODS[0];
  bool _isPrivate = false;
  bool _repliesEnabled = true;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadDailyRitual();
    _loadSettings();

    // --- Animation Setup ---
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
        setState(() =>
        _narrativeIndex = (_narrativeIndex + 1) % _footerNarratives.length);
        _narrativeController.forward(from: 0);
      }
    });
    _narrativeController.forward();

    _introNarrativeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _introNarrativeIndex =
            (_introNarrativeIndex + 1) % _introNarratives.length);
        _introNarrativeController.forward(from: 0);
      }
    });
    _introNarrativeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _narrativeController.dispose();
    _introNarrativeController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // --- Settings & Location Methods ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      String savedTitle = prefs.getString('autoDiaryTitle') ?? "";

      // If no title is saved, generate the dynamic date-based default
      if (savedTitle.isEmpty) {
        final now = DateTime.now();
        // Format: 10 am Wednesday, July 17, 2025
        final datePart = DateFormat("EEEE, MMMM d, yyyy").format(now);
        final timePart = DateFormat("h a").format(now).toLowerCase();
        savedTitle = "From Auto Diary Mode At $timePart $datePart";
      }

      setState(() {
        _titleController.text = savedTitle;
        _isPrivate = prefs.getBool('autoDiaryIsPrivate') ?? false;
        _repliesEnabled = prefs.getBool('autoDiaryRepliesEnabled') ?? true;
        _locationEnabled = prefs.getBool('autoDiaryLocationEnabled') ?? false;
        int moodId = prefs.getInt('autoDiaryMoodId') ?? 0;
        _selectedMood = Constant.USER_SESSION_MOODS[moodId];
      });
    }
  }


  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoDiaryTitle', _titleController.text);
    await prefs.setBool('autoDiaryIsPrivate', _isPrivate);
    await prefs.setBool('autoDiaryRepliesEnabled', _repliesEnabled);
    await prefs.setBool('autoDiaryLocationEnabled', _locationEnabled);
    await prefs.setInt(
        'autoDiaryMoodId', Constant.USER_SESSION_MOODS.indexOf(_selectedMood));

    if (!_locationEnabled) {
      await prefs.remove('autoDiaryLocationData');
    }

    showToast("Your Spirit's configuration is saved.");
    setState(() {
      _currentView = _SanctuaryView.main;
    });
  }

  Future<void> _determinePositionAndSave() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showToast('Location services are disabled.');
      if (mounted) setState(() => _locationEnabled = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showToast('Location permissions are denied.');
        if (mounted) setState(() => _locationEnabled = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showToast('Location permissions are permanently denied.');
      openAppSettings();
      if (mounted) setState(() => _locationEnabled = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      String locationString = "in ${place.administrativeArea}, ${place.country}";

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('autoDiaryLocationData', locationString);
      showToast("Location captured: $locationString");
    } catch (e) {
      showToast("Could not determine location.");
      if (mounted) setState(() => _locationEnabled = false);
    }
  }

  // --- Core Auto Diary Methods (Narrative Updated) ---
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
    service.invoke('cancelDailyRitual');
    if (mounted) {
      setState(() {
        _dailyRitualTime = null;
      });
    }
    showToast("Your daily ritual has been cancelled.");
  }

  void _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (mounted) {
      setState(() {
        isServiceRunning = isRunning;
        if (isRunning)
          _pulseController.repeat(reverse: true);
        else
          _pulseController.stop();
      });
    }
  }

  Future<bool> _requestMicPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      showToast("Microphone permission is required for Claire to listen.");
      if (status.isPermanentlyDenied) openAppSettings();
      return false;
    }
    return true;
  }

  void _scheduleOneTime(TimeOfDay time) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (!await _requestMicPermission()) return;
      if (!await _handleLovesTransaction()) return;

      final service = FlutterBackgroundService();
      if (!isServiceRunning) {
        await service.startService();
        await Future.delayed(const Duration(seconds: 1));
      }
      final now = DateTime.now();
      var scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }
      service.invoke('scheduleRecording', {'time': scheduledDateTime.toIso8601String()});
      if (mounted) setState(() => isServiceRunning = true);
      showToast("Claire scheduled for ${DateFormat.jm().format(scheduledDateTime)}. (1,000 Loves deducted)");

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop();
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _listenNow() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (!await _requestMicPermission()) return;
      if (!await _handleLovesTransaction()) return;

      final service = FlutterBackgroundService();
      if (!isServiceRunning) {
        await service.startService();
        await Future.delayed(const Duration(seconds: 1));
      }
      service.invoke('instantRecording');
      if (mounted) setState(() => isServiceRunning = true);
      showToast("Claire is now monitoring you. (1,000 Loves deducted)");

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop();
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _scheduleDaily(TimeOfDay time) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (!await _requestMicPermission()) return;
      if (!await _handleLovesTransaction()) return;

      final service = FlutterBackgroundService();
      if (!isServiceRunning) {
        await service.startService();
        await Future.delayed(const Duration(seconds: 1));
      }
      service.invoke('scheduleDailyRitual', {'hour': time.hour, 'minute': time.minute});
      await _saveDailyRitual(time);
      if (mounted) {
        setState(() {
          isServiceRunning = true;
          _dailyRitualTime = time;
          _currentView = _SanctuaryView.main;
        });
      }
      showToast("Daily monitoring set for ${time.format(context)}. (1,000 Loves deducted)");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }



  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Monitoring Spirit',
            style: GoogleFonts.lato(color: Colors.white.withValues(alpha: 0.8))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _currentView != _SanctuaryView.main
            ? IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () =>
              setState(() => _currentView = _SanctuaryView.main),
        )
            : null,
        actions: [
          if (_currentView == _SanctuaryView.configure)
            IconButton(
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 28),
              onPressed: _saveSettings,
            ),
          if (_currentView != _SanctuaryView.configure)
            const SizedBox(width: 56)
        ],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildCurrentView(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case _SanctuaryView.whisper:
        return _buildTimePickerView(isDaily: false);
      case _SanctuaryView.ritual:
        return _buildTimePickerView(isDaily: true);
      case _SanctuaryView.configure:
        return _buildSettingsView();
      case _SanctuaryView.main:
      default:
        return _buildMainActionsView();
    }
  }

  Widget _buildMainActionsView() {
    return Column(
      key: const ValueKey('mainActions'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIntroNarrative(),
        _buildHeartbeatOrb(),
        const SizedBox(height: 30),
        _buildActionButton(
          onTap: _listenNow,
          icon: Icons.hearing_rounded,
          label: 'Monitor Now',
          color: Pallet.colorPrimary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 25),
        _buildActionButton(
          onTap: () {
            setState(() {
              _tempSelectedTime = null;
              _currentView = _SanctuaryView.whisper;
            });
          },
          icon: Icons.schedule_rounded,
          label: 'Schedule Monitor',
          color: Pallet.colorSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 25),
        _dailyRitualTime == null
            ? _buildActionButton(
          onTap: () {  setState(() {
            _tempSelectedTime = null;
            _currentView = _SanctuaryView.ritual;
          });
          },

          icon: Icons.sync_rounded,
          label: 'Set Daily Monitor',
          color: Pallet.colorPrimary.withValues(alpha: 0.7),
        )
            : _buildActiveRitualDisplay(),
        const SizedBox(height: 25),
        _buildActionButton(
          onTap: () => setState(() => _currentView = _SanctuaryView.configure),
          icon: Icons.settings_outlined,
          label: 'Configure Your Spirit',
          color: Pallet.colorSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildTimePickerView({required bool isDaily}) {
    // Initialize the persistent temp variable only if it's currently null
    _tempSelectedTime ??= _dailyRitualTime ?? TimeOfDay.now();

    return Column(
      key: ValueKey(isDaily ? 'ritualPicker' : 'whisperPicker'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isDaily
              ? 'Set your daily monitoring time'
              : 'Set a time for Claire to monitor',
          style: GoogleFonts.lato(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle:
                  TextStyle(color: Colors.white, fontSize: 20)),
            ),
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: Duration(
                  hours: _tempSelectedTime!.hour, minutes: _tempSelectedTime!.minute),
              onTimerDurationChanged: (Duration d) {
                // Update the class-level variable directly
                _tempSelectedTime = TimeOfDay(hour: d.inHours % 24, minute: d.inMinutes % 60);
              },
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          onTap: () {
            final timeToSchedule = _tempSelectedTime!;
            // Clear temp time after scheduling so next entry re-initializes
            _tempSelectedTime = null;

            if (isDaily) {
              _scheduleDaily(timeToSchedule);
            } else {
              _scheduleOneTime(timeToSchedule);
            }
          },
          icon: isDaily ? Icons.sync_rounded : Icons.check_circle_outline,
          label: isDaily ? 'Start Daily Monitor' : 'Schedule Monitor',
          color: isDaily
              ? Pallet.colorPrimary.withValues(alpha: 0.7)
              : Pallet.colorSecondary.withValues(alpha: 0.7),
        ),
      ],
    );
  }


  Widget _buildSettingsView() {
    return SingleChildScrollView(
      key: const ValueKey('settings'),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _titleController,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 20, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Default Session Title',
              labelStyle:
              GoogleFonts.lato(color: Colors.white.withValues(alpha: 0.6)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Pallet.colorSecondary)),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white38)),
            child: DropdownButton<String>(
              value: _selectedMood,
              isExpanded: true,
              dropdownColor: Colors.black,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              style: GoogleFonts.lato(fontSize: 16, color: Colors.white),
              onChanged: (String? v) => setState(() => _selectedMood = v!),
              items: Constant.USER_SESSION_MOODS
                  .map<DropdownMenuItem<String>>(
                      (String v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsToggle(
              label: "Allow Replies From Other Users",
              value: _repliesEnabled,
              onChanged: (v) => setState(() => _repliesEnabled = v)),
          const SizedBox(height: 15),
          _buildSettingsToggle(
              label: "Allow Replies From Claire",
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v)),
          const SizedBox(height: 15),
          _buildSettingsToggle(
              label: "Do you want to tag your location?",
              value: _locationEnabled,
              onChanged: (val) {
                setState(() => _locationEnabled = val);
                if (val) _determinePositionAndSave();
              }),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildIntroNarrative() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1500),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Text(
          _introNarratives[_introNarrativeIndex],
          key: ValueKey<int>(_introNarrativeIndex),
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
              fontSize: 16.0,
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildSettingsToggle(
      {required String label,
        required bool value,
        required ValueChanged<bool> onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 16)),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Pallet.colorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRitualDisplay() {
    return Container(
      width: 280, // Adjusted width for longer text
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Pallet.colorPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Pallet.colorPrimary.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_rounded, color: Pallet.colorPrimary),
          const SizedBox(width: 12),
          Flexible(
            child: Text('Daily at ${_dailyRitualTime!.format(context)}',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                    fontSize: 16.0, // Adjusted font size
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9))),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearDailyRitual,
            child: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

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
                  ? Pallet.colorSecondary.withValues(alpha: 0.6)
                  : Colors.grey.withValues(alpha: 0.4),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
            child: RotateImage(60, 60)),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap, // Disable tap when processing
      child: Opacity(
        opacity: _isProcessing ? 0.6 : 1.0,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                const CupertinoActivityIndicator(color: Colors.white, radius: 10)
              else
                Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                _isProcessing ? "Processing..." : label,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1500),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              _footerNarratives[_narrativeIndex],
              key: ValueKey<int>(_narrativeIndex),
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Colors.white.withValues(alpha: 0.6),
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
                showToast("The connection to alter ego has been paused.");
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Text("Pause Connection",
                    style: GoogleFonts.lato(
                        color: Pallet.colorPrimary.withValues(alpha: 0.8))),
              ),
            ),
        ],
      ),
    );
  }

  // --- Validation & Deduction Logic ---
  Future<bool> _handleLovesTransaction() async {
    final String? userId = await firebaseServices.getUsersId();
    if (userId == null) {
      showToast("User session not found.");
      return false;
    }

    try {
      // 1. Fetch current balance using the UserModel pattern
      final t_model.UserModel user =
      await firebaseServices.getUserWithId(id: userId);
      final int currentLoves = user.currentLoveCount ?? 0;

      // 2. Check for 10,000 threshold requirement
      if (currentLoves < 10000) {
        showToast("You need at least 10,000 Loves to access this technology.");
        return false;
      }

      // 3. Check if they can afford the 1,000 cost
      if (currentLoves < 1000) {
        showToast("Insufficient Loves. Each activation costs 1,000.");
        return false;
      }

      // 4. Deduct 1,000 Loves
      bool success = await firebaseServices.updateTreasuryAndUser(
        userId: userId,
        amount: 1000,
        type: t_model.TransactionType.debit,
        userTransactionDescription: "Monitoring Spirit Service Fee",
      );

      if (success) {

        // 5. Save User Activity as 'monitor'
        await firebaseServices.saveUserActivity(
          activityType: 'monitor',
          activityMessage: "You activated the Monitoring Spirit service.",
        );
        return true;
      } else {
        showToast("Transaction failed. Please try again.");
        return false;
      }
    } catch (e) {
      debugPrint("Balance Error: $e");
      showToast("Error verifying balance.");
      return false;
    }
  }


}
