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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/toast_helper.dart';
import '../../services/firebase_services.dart';
import '../../services/user_model.dart';
import '../../utils/mood.dart';
import '../create_session/session_model.dart';
import '../dairy/diary.dart';
import '../routes/routes.dart';

class ArchiveWidget extends StatefulWidget {
  final ScrollController scrollController;

  const ArchiveWidget({Key? key, required this.scrollController}) : super(key: key);

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

  final String _quickSessionDateKey = 'quick_session_selected_date';
  Future<void> _saveDateToLocal(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quickSessionDateKey, date.toIso8601String());
  }

  Future<DateTime?> _getDateFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_quickSessionDateKey);
    if (dateString != null) {
      await prefs.remove(_quickSessionDateKey);
      return DateTime.parse(dateString);
    }
    return null;
  }

  /// Example events.
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


  void _handleDaySelection(DateTime selectedDay, DateTime focusedDay) async {
    // Check if there are already sessions for this day
    List<Session> sessionsOnDay = _getSessionForDay(selectedDay);

    if (sessionsOnDay.isEmpty) {
      // If no sessions, this is a "quick add" action.
      // 1. Save the selected date to local storage immediately.
      await _saveDateToLocal(selectedDay);
      // 2. Show the popup. Do NOT pass the date.
      _showQuickEntryPopup();
    } else {
      // If sessions exist, navigate to the archive page for that day.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArchivedSessions(
            sessions: sessionsOnDay,
            selectedDate: selectedDay,
            suggestion: null,
          ),
        ),
      );
    }
  }



  void _createQuickCalendarSession({
    required String title,
    required String message,
    required int moodId,
  }) async {
    if (currentUser == null) return;

    final correctDate = await _getDateFromLocal();

    if (correctDate == null) {
      showToast(message: "Error: Could not retrieve the selected date.");
      return;
    }

    showToast(message: "Adding quick session...");

    final correctTimestamp = Timestamp.fromDate(correctDate);

    try {
      userModel = await _firebaseServices.getUserInfo();
      String sessionId = uuid.v4();
      final randomColor = AppConstants.DIARY_COLORS_HEXCODE[Random().nextInt(AppConstants.DIARY_COLORS_HEXCODE.length)];
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
        timeCreated: correctTimestamp,
        timeLastActivity: correctTimestamp,
        moodId: moodId,
        colorHex: randomColor,
      );
      await _firebaseServices.createSession(session: sessionData);
      Navigator.of(context).pop(); // Pops mood dialog
      await _firebaseServices.updateUserMoods(moodId);
      await _firebaseServices.saveUserActivity(
        activityType: 'session',
        activityMessage: "You started a quick diary session: '$title'.",
        sessionId: sessionId,
      );
      if (currentUser!.displayName != null) {
        _firebaseServices.subscribeToYourSession(currentUser!.displayName!, sessionData);
        _firebaseServices.notifyClaireForSession(currentUser!.displayName!, sessionData);
      }

      showToast(message: "Quick session saved!");

      setState(() {
        _focusedDay = correctDate; // Focus the day where the session was added
      });

      Navigator.of(context).pop(); // Pops quick entry dialog

      Future.delayed(Duration(seconds: 2), () {
        _showQuickInterstitialAd();
      });

    } catch (e) {
      showToast(message: "Error: Could not save session.");
      print("Error creating quick session: $e");
    }
  }



  // Method to show the popup with quick entry options
  void _showQuickEntryPopup() {
    // Pre-defined templates for the popup, categorized for clarity
    final Map<String, Map<String, String>> categorizedTemplates = {
      'Cycle Tracking': {
        '🩸 Period Start': 'Dear Claire, my period just started today.',
        '🩸 Period End': 'Dear Claire, my period ended today.',
      },
      'Mood & Feelings': {
        '😊 Feeling Happy': 'Dear Claire, I\'m feeling genuinely happy and content today.',
        '😥 Feeling Sad': 'Dear Claire, a wave of sadness came over me today.',
        '🧘 Feeling Calm': 'Dear Claire, I felt a sense of calm and peace today.',
        '⚡️ Feeling Energized': 'Dear Claire, I had so much energy and motivation today!',
      },
      'Mental Wellness': {
        '😰 Feeling Anxious': 'Dear Claire, I\'m feeling very anxious and on edge today.',
        '😫 Feeling Stressed': 'Dear Claire, I feel stressed and overwhelmed.',
        '🧘‍♀️ Self-Care Day': 'Dear Claire, I dedicated today to self-care and rest.',
        '🎉 Small Victory': 'Dear Claire, I want to celebrate a small win today!',
      },
      'Lifestyle & Events': {
        '✈️ Traveled Today': 'Dear Claire, I went on a trip today!',
        '❤️ Date Night': 'Dear Claire, it was date night tonight.',
        '☀️ Beautiful Day': 'Dear Claire, the weather was so beautiful today, it lifted my spirits.',
        '🤒 Feeling Unwell': 'Dear Claire, I haven\'t been feeling well today.',
      }
    };

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Pallet.colorPrimary.withValues(alpha: 0.9), // Base for glass effect
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          title: Center(
            child: Text(
              'Add Quick Session To Date',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categorizedTemplates.entries.map((category) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
                            child: Text(
                              category.key,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: category.value.length,
                            itemBuilder: (context, index) {
                              final title = category.value.keys.elementAt(index);
                              final message = category.value.values.elementAt(index);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showMoodSelectionDialog(title, message);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  // method to show the mood selection dialog
  void _showMoodSelectionDialog( String title, String message) {
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
                    HapticFeedback.lightImpact();
                    _createQuickCalendarSession(
                      title: title,
                      message: message,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        showToast(message: "Press back again to exit.");
      },
      child: FutureBuilder<List<Session>>(
        future: firebaseServices.getUserSessionByDate(startDate: kFirstDay),
        builder: (context, AsyncSnapshot<List<Session>> userSessions) {
          if (userSessions.connectionState == ConnectionState.waiting) {
            return Center(child: RotateImage(70, 70));
          }

          if (userSessions.hasError) {
            return Center(
              child: Text(
                userSessions.error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 15.0, color: Colors.red),
              ),
            );
          }

          // If data exists, or even if it's empty, we build the scroll view
          if (userSessions.hasData) {
            extractDatesFromSession(userSessions);
          }

          // Use NestedScrollView for the main structure
          return NestedScrollView(
            controller: widget.scrollController, // Use the controller from the parent
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              // These are the widgets that will scroll away.
              return <Widget>[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 2, 8.0, 0),
                        child: Text(
                          "Browse your sessions by calendar.",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: calendarWidget(), // Your existing calendar widget
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: Text(
                          "Browse your sessions by mood.",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ArchiveMoodStream(),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: Text(
                          "Browse your sessions by categories.",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      UsersArchiveCategories(),
                      const SizedBox(height: 8),
                      // This is the header for the part that will NOT scroll away
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text("Recent Diary Sessions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ];
            },
            // The body is the part that remains and scrolls internally.
            body: DiaryPage(title: "Recent Diary Sessions", showAppBar: false),
          );
        },
      ),
    );
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

            onDaySelected: _handleDaySelection,
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
