import 'dart:collection';
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
    // Implementation mobymagic
    return kEvents[day] ?? [];
  }

  void extractDatesFromSession(AsyncSnapshot<List<Session>> userSessions) {
    sessions.addAll(userSessions.data!);
    userSessions.data!;
    userSessions.data!.forEach((element) {
      _dateLists.add(element.timeCreated!.toDate());
      _selectedDays.add(element.dateTime!);
    });

    debugPrint(_dateLists.toString());

    ///After getting sessions, create events based on the sessions in each datetime Object
    // createEvents();
  }

  _onDateTapped(DateTime selectedDay, DateTime focusedDay) {
    debugPrint("tapped date is ${selectedDay.toIso8601String()}");
    debugPrint("tapped date is ${selectedDay.toString()}");
    List<Session> selectedSessions = [];
    sessions.forEach((element) {
      if (DateTime(element.dateTime!.year, element.dateTime!.month,
              element.dateTime!.day)
          .isAtSameMomentAs(
              DateTime(selectedDay.year, selectedDay.month, selectedDay.day))) {
        selectedSessions.add(element);
      }
    });

    debugPrint("length is ${selectedSessions.length}");
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ArchivedSessions(
                  sessions: selectedSessions,
                )));
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
    return Container(
      decoration: BoxDecoration(color: Pallet.colorPrimary),
      child: TableCalendar(
        daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white),
            weekendStyle: TextStyle(color: Colors.white)),
        calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(color: Colors.white),
            selectedDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: Colors.white)),
        firstDay: kFirstDay,
        lastDay: kLastDay,
        focusedDay: _focusedDay!,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          // Use values from Set to mark multiple days as selected
          return _selectedDays.contains(day);
        },
        onDaySelected: _onDateTapped,
        eventLoader: _getSessionForDay,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {},
      ),
    );
  }
}
