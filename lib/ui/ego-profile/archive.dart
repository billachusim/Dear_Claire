import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:clairediary/ui/Categories/archive_mood_stream.dart';
import 'package:clairediary/ui/ego-profile/archived_sessions.dart';
import 'package:clairediary/ui/ego-profile/utils.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/ui/featured/public_sessions.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/toast_helper.dart';
import '../../services/firebase_services.dart';
import '../../services/user_model.dart';
import '../../utils/mood.dart';
import '../create_session/session_model.dart';

class ArchiveWidget extends StatefulWidget {
  const ArchiveWidget({Key? key}) : super(key: key);

  @override
  State<ArchiveWidget> createState() => _ArchiveWidgetState();
}

class _ArchiveWidgetState extends State<ArchiveWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final FirebaseServices _firebaseServices = FirebaseServices();
  var currentUser = FirebaseAuth.instance.currentUser;
  var uuid = Uuid();
  final List<Session> sessions = [];
  final List<DateTime> _dateLists = [];
  int maxFailedLoadAttempts = 3;
  late Future<UserModel> _userFuture;
  bool _isPremium = false;

  DateTime? _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _userFuture = _firebaseServices.getUserInfo();
    _userFuture.then((user) {
      if (mounted) {
        setState(() {
          _isPremium = user.isPremium;
        });
        if (!_isPremium) {
          _createQuickInterstitialAd();
        }
      }
    });
  }

  @override
  void dispose() {
    _quickInterstitialAd?.dispose();
    super.dispose();
  }


  // Using a `LinkedHashSet` is recommended due to equality comparison override
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  /// Example events.
  ///
  /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
  final kEvents = LinkedHashMap<DateTime, List<Session>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  List<Session> _getSessionForDay(DateTime day) {
    // TableCalendar passes dates with various times; we normalize to midnight
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return kEvents[normalizedDay] ?? [];
  }


  // Helper to extract emoji from mood string
  String _getEmoji(int? moodId) {
    String? moodStr = Mood.getMood(moodId);
    if (moodStr == null || moodStr.isEmpty) return "📝";
    // Regex to find the first emoji in the string
    final emojiRegex = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
    final match = emojiRegex.firstMatch(moodStr);
    return match?.group(0) ?? "📝";
  }

  void extractDatesFromSession(AsyncSnapshot<List<Session>> userSessions) {
    // Clear existing data to prevent duplicates on rebuild
    sessions.clear();
    _dateLists.clear();
    _selectedDays.clear();kEvents.clear();

    sessions.addAll(userSessions.data!);

    for (var element in userSessions.data!) {
      if (element.dateTime != null) {
        _dateLists.add(element.dateTime!);
        _selectedDays.add(element.dateTime!);

        // Normalize the date (remove time) to use as a Map key
        DateTime dateKey = DateTime(element.dateTime!.year, element.dateTime!.month, element.dateTime!.day);

        if (kEvents[dateKey] == null) {
          kEvents[dateKey] = [];
        }
        kEvents[dateKey]!.add(element);
      }
    }
  }

  InterstitialAd? _quickInterstitialAd;
  int _quickInterstitialLoadAttempts = 0;

  // Create quick session interstitial ad.

  void _createQuickInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/8800174899"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/1147263196"
          : '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _quickInterstitialAd = ad;
          _quickInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _quickInterstitialLoadAttempts += 1;
          _quickInterstitialAd = null;
          if (_quickInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createQuickInterstitialAd();
          }
        },
      ),
    );
  }

  void _showQuickInterstitialAd() {
    if (_quickInterstitialAd == null || _isPremium) return;
      _quickInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createQuickInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createQuickInterstitialAd();
        },
      );
      _quickInterstitialAd!.show();
  }


  _onDateTapped(DateTime selectedDay, DateTime focusedDay) {
    List<Session> selectedSessions = _getSessionForDay(selectedDay);

    if (selectedSessions.isEmpty) {
      // If no sessions exist on this day, show the quick entry popup.
      _showQuickEntryPopup(selectedDay);
    } else {
      // If sessions exist, navigate to the archived sessions page as before.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ArchivedSessions(
                sessions: selectedSessions,
                selectedDate: selectedDay,
                suggestion: null, // No suggestion needed as sessions exist
              ),
        ),
      );
    }
  }

  // Method to create the session, adapted from create_session_page.dart
  void _createQuickCalendarSession({
    required String title,
    required String message,
    required DateTime selectedDate,
    required int moodId, // Now required
  }) async {
    if (currentUser == null) return;

    // Show a loading indicator or toast
    showToast(message: "Creating quick session...");

    try {
      userModel = await _firebaseServices.getUserInfo();
      String sessionId = uuid.v4();
      final randomColor = Constant.DIARY_COLORS_HEXCODE[Random().nextInt(Constant.DIARY_COLORS_HEXCODE.length)];

      final sessionData = CreateSessionModel(
        sessionId: sessionId,
        userId: userModel.userId,
        userAvatarUrl: userModel.avatarUrl,
        userNickname: userModel.nickname,
        title: title,
        message: message,
        location: '#QuickSession',
        featured: false,
        private: false,
        repliesEnabled: false,
        timeCreated: Timestamp.now(),
        timeLastActivity: Timestamp.now(),
        moodId: moodId,
        colorHex: randomColor,
      );

      await _firebaseServices.createSession(session: sessionData);

      // --- ADDING THE REQUESTED METHODS ---

      // 1. Update user moods
      await _firebaseServices.updateUserMoods(moodId);

      // 2. Save user activity
      await _firebaseServices.saveUserActivity(
        activityType: 'session',
        activityMessage: "You started a quick diary session: '$title'.",
        sessionId: sessionId,
      );

      // 3. Handle notifications for Claire and the user
      if (currentUser!.displayName != null) {
        _firebaseServices.subscribeToYourSession(currentUser!.displayName!, sessionData);
        _firebaseServices.notifyClaireForSession(currentUser!.displayName!, sessionData);
      }

      // --- END OF ADDED METHODS ---

      // Refresh the calendar data after creating the session
      setState(() {
        _focusedDay = selectedDate; // Focus the day where the session was added
      });

      // Pop the dialog (will pop twice: once for mood, once for main dialog)
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      showToast(message: "Quick session saved!");

      // Show ad after a delay
      Future.delayed(Duration(seconds: 2), () {
        _showQuickInterstitialAd();
      });

    } catch (e) {
      showToast(message: "Error: Could not save session.");
      print("Error creating quick session: $e");
    }
  }



  // Method to show the popup with quick entry options
  void _showQuickEntryPopup(DateTime selectedDate) {
    // Pre-defined templates for the popup
    final templates = {
      'Period Start': 'Dear Claire, my period just started today.',
      'Period Stop': 'Dear Claire, my period ended today.',
      'Ovulation Start': 'Dear Claire, I think I\'m ovulating today.',
      'Ovulation Stop': 'Dear Claire, my ovulation should be over now.',
      'Feeling Happy': 'Dear Claire, I\'m feeling genuinely happy today. 😊',
      'Feeling Stressed': 'Dear Claire, I\'m feeling very stressed and overwhelmed today.',
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Pallet.colorSecondary.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Add a Quick Entry',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: templates.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key, style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    // Show mood selection dialog
                    _showMoodSelectionDialog(selectedDate, entry.key, entry.value);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // New method to show the mood selection dialog
  void _showMoodSelectionDialog(DateTime selectedDate, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Pallet.colorSecondary.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          title: Text(
            'How are you feeling?',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: Mood.MOODS.length,
              itemBuilder: (context, index) {
                Mood.MOODS.elementAt(index);
                final moodString = Mood.getMood(index) ?? '';
                final emoji = _getEmoji(index);
                return GestureDetector(
                  onTap: () {
                    _createQuickCalendarSession(
                      title: title,
                      message: message,
                      selectedDate: selectedDate,
                      moodId: index,
                    );
                  },
                  child: Tooltip(
                    message: moodString.replaceAll(emoji, '').trim(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Back', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: firebaseServices.getUserSessionByDate(startDate: kFirstDay),
        builder: (context, AsyncSnapshot<List<Session>> userSessions) {
          if (userSessions.connectionState == ConnectionState.waiting) {
            return RotateImage(70, 70);
          }
          if (!userSessions.hasData) {
            return ListView(children: [calendarWidget()]);
          }

          if (userSessions.hasError) {
            return Container(
              child: Text(userSessions.error.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorBlack,
                      //fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w600)),
            );
          }

          if (userSessions.hasData) {
            extractDatesFromSession(userSessions);
            return ListView(children: [
              Text(
                "Browse your sessions by calendar.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4,),
              calendarWidget(),
              SizedBox(height: 4,),
              Text(
                "Browse your sessions by mood.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              ArchiveMoodStream(),
              SizedBox(height: 4,),
              Text(
                "Browse your sessions by categories.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              UsersArchiveCategories(),
            ]);
          }
          return Container();
        });
  }

  Widget calendarWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // Glassmorphism Gradient
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Pallet.colorPrimary.withValues(alpha: 0.9),
                Pallet.colorSecondary.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            // The signature "iOS Glass Border"
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: TableCalendar(
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              weekendStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white),
              weekendTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white70),
              outsideTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white24),

              // Today's Date style
              todayDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),

              // Selected Session Dates (The dots/markers)
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.greenAccent, Colors.green.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),

              // Marker for events (tiny dots below date)
              markerDecoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
            ),
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay!,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return _selectedDays.contains(day);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  // Cast events to Session list
                  final daySessions = events as List<Session>;
                  final session = daySessions.first;

                  return Container(
                    margin: const EdgeInsets.only(top: 22), // Push emoji below the date number
                    alignment: Alignment.center,
                    child: Text(
                      _getEmoji(session.moodId),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            onDaySelected: _onDateTapped,
            eventLoader: _getSessionForDay,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
          ),
        ),
      ),
    );
  }

}
