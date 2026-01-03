import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'empty_session_widget.dart';



class ArchivedSessions extends StatefulWidget {
  const ArchivedSessions({
    Key? key,
    required this.sessions,
    required this.selectedDate,
    this.suggestion
  }) : super(key: key);

  final List<Session> sessions;
  final DateTime selectedDate;
  final String? suggestion;

  @override
  _ArchivedSessionsState createState() => _ArchivedSessionsState();
}

class _ArchivedSessionsState extends State<ArchivedSessions> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Pallet.colorPrimary,
        title: Text("Sessions: ${widget.selectedDate.day}/${widget.selectedDate.month}"),
        elevation: 0,
      ),
      body: widget.sessions.isNotEmpty
          ? ListView(
        children: widget.sessions
            .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: ''))
            .toList(),
      )
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptySessionWidget(),
              if (widget.suggestion != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.suggestion!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}


