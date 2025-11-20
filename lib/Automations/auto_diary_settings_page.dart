import 'package:clairediary/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auto_diary_service.dart';

class AutoDiarySettingsPage extends StatefulWidget {
  const AutoDiarySettingsPage({Key? key}) : super(key: key);

  @override
  _AutoDiarySettingsPageState createState() => _AutoDiarySettingsPageState();
}

class _AutoDiarySettingsPageState extends State<AutoDiarySettingsPage> {
  bool _isAutoDiaryEnabled = false;
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);
  final AutoDiaryService _autoDiaryService = AutoDiaryService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoDiaryEnabled = prefs.getBool('autoDiaryEnabled') ?? false;
      final startHour = prefs.getInt('autoDiaryStartHour') ?? 9;
      final startMinute = prefs.getInt('autoDiaryStartMinute') ?? 0;
      final endHour = prefs.getInt('autoDiaryEndHour') ?? 17;
      final endMinute = prefs.getInt('autoDiaryEndMinute') ?? 0;
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  Future<void> _updateEnabled(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification permission is required for Auto Diary.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        // The user opted to never see the permission request again.
        // Open app settings to allow them to grant the permission.
        openAppSettings();
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();

    if (value) {
      if (_endTime.hour < _startTime.hour || (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End time must be after start time.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Don't enable if the time is invalid
      }
      _autoDiaryService.scheduleAutoDiaryNotifications(startHour: _startTime.hour, endHour: _endTime.hour);
    } else {
      _autoDiaryService.cancelAllNotifications();
    }

    await prefs.setBool('autoDiaryEnabled', value);
    setState(() {
      _isAutoDiaryEnabled = value;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
        builder: (context, child) {
            return Theme(
                data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                        primary: Pallet.colorPrimary, // header background color
                        onPrimary: Colors.white, // header text color
                        onSurface: Colors.black, // body text color
                    ),
                    textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                            foregroundColor: Pallet.colorPrimary, // button text color
                        ),
                    ),
                ),
                child: child!,
            );
        },
    );

    if (picked != null) {
       if (!isStartTime && (picked.hour < _startTime.hour || (picked.hour == _startTime.hour && picked.minute <= _startTime.minute))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End time must be after start time.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          prefs.setInt('autoDiaryStartHour', picked.hour);
          prefs.setInt('autoDiaryStartMinute', picked.minute);
        } else {
          _endTime = picked;
          prefs.setInt('autoDiaryEndHour', picked.hour);
          prefs.setInt('autoDiaryEndMinute', picked.minute);
        }
      });
      // Reschedule notifications if the feature is already enabled
      if (_isAutoDiaryEnabled) {
        _autoDiaryService.scheduleAutoDiaryNotifications(startHour: _startTime.hour, endHour: _endTime.hour);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtleTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Diary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Pallet.colorPrimary,
      ),
      backgroundColor: isDarkMode ? Colors.black : Color(0xFFF5F3F7), // A soft background color
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textColor, subtleTextColor),
            SizedBox(height: 30),
            _buildEnableSwitch(cardColor, textColor, subtleTextColor),
            SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _isAutoDiaryEnabled ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: _isAutoDiaryEnabled ? _buildTimeSettings(textColor, subtleTextColor, cardColor) : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subtleTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome,
          color: Pallet.colorPrimary.withOpacity(0.8),
          size: 50,
        ),
        SizedBox(height: 16),
        Text(
          'Let Claire be your companion',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Enable Auto Diary and she will send you thoughtful prompts throughout the day. Tap the notification, speak your mind, and find clarity.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: subtleTextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEnableSwitch(Color? cardColor, Color textColor, Color subtleTextColor) {
    return Card(
      elevation: 2.0,
      color: cardColor,
      shadowColor: Pallet.colorPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SwitchListTile(
        title: Text(
          'Enable Auto Diary',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          _isAutoDiaryEnabled ? 'Claire is listening' : 'Claire is waiting',
          style: TextStyle(color: subtleTextColor),
        ),
        value: _isAutoDiaryEnabled,
        onChanged: _updateEnabled,
        activeColor: Pallet.colorPrimary,
        secondary: Icon(
          _isAutoDiaryEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: Pallet.colorPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }

  Widget _buildTimeSettings(Color textColor, Color subtleTextColor, Color? cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Hours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Claire will only send you prompts during this time window.',
          style: TextStyle(color: subtleTextColor),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimePickerCard(isStartTime: true, cardColor: cardColor, textColor: textColor, subtleTextColor: subtleTextColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.arrow_forward, color: Pallet.colorPrimary.withOpacity(0.6)),
            ),
            _buildTimePickerCard(isStartTime: false, cardColor: cardColor, textColor: textColor, subtleTextColor: subtleTextColor),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePickerCard({required bool isStartTime, required Color? cardColor, required Color textColor, required Color subtleTextColor}) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectTime(context, isStartTime),
        borderRadius: BorderRadius.circular(20),
        child: Card(
          elevation: 2.0,
          color: cardColor,
          shadowColor: Pallet.colorPrimary.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Icon(
                  isStartTime ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                  color: Pallet.colorPrimary,
                  size: 30,
                ),
                SizedBox(height: 8),
                Text(
                  isStartTime ? 'From' : 'To',
                  style: TextStyle(color: subtleTextColor, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  isStartTime ? _startTime.format(context) : _endTime.format(context),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
