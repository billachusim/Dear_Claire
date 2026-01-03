import 'dart:collection';
import 'dart:ui';
import 'package:clairediary/ui/Categories/archive_mood_stream.dart';
import 'package:clairediary/ui/ego-profile/archived_sessions.dart';
import 'package:clairediary/ui/ego-profile/utils.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/ui/featured/public_sessions.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../utils/mood.dart';

class ArchiveWidget extends StatefulWidget {
  const ArchiveWidget({Key? key}) : super(key: key);

  @override
  State<ArchiveWidget> createState() => _ArchiveWidgetState();
}

class _ArchiveWidgetState extends State<ArchiveWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final List<Session> sessions = [];
  final List<DateTime> _dateLists = [];

  DateTime? _focusedDay = DateTime.now();


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


  _onDateTapped(DateTime selectedDay, DateTime focusedDay) {
    List<Session> selectedSessions = sessions.where((element) =>
        isSameDay(element.dateTime, selectedDay)).toList();

    String? suggestion;
    if (selectedSessions.isEmpty && _dateLists.isNotEmpty) {
      // Find the closest date with a session
      _dateLists.sort();
      DateTime closest = _dateLists.first;
      int minDiff = (selectedDay
          .difference(closest)
          .abs()
          .inDays);

      for (var date in _dateLists) {
        int diff = (selectedDay
            .difference(date)
            .abs()
            .inDays);
        if (diff < minDiff) {
          minDiff = diff;
          closest = date;
        }
      }
      suggestion =
      "No sessions on this day. The closest date with a session is ${closest
          .day}/${closest.month}/${closest.year}.";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ArchivedSessions(
              sessions: selectedSessions,
              selectedDate: selectedDay,
              suggestion: suggestion,
            ),
      ),
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
                    color: Colors.green.withOpacity(0.4),
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
