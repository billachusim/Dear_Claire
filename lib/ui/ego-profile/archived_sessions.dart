import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import 'empty_session_widget.dart';



class ArchivedSessions extends StatefulWidget {
  const ArchivedSessions({Key? key, required this.sessions}) : super(key: key);
  final List<Session> sessions;

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
    title: Text("Sessions Since Chosen Date"),
    elevation: 0,
    ),
    body: (widget.sessions.length!=0) ?ListView(
      children: [
        ...widget.sessions
            .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
            .toList(),
      ],
    ):
    EmptySessionWidget(),
    );
  }
}

