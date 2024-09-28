import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/strings.dart';
import '../featured/model/session.dart';
import '../../widgets/ego_mode_session_card.dart';
import '../../utils/mood.dart';


class ArchiveMoodSessions extends StatelessWidget {
  final int sessionMood;

  ArchiveMoodSessions({Key? key, required this.sessionMood}) : super(key: key);

  List<Session>? _sessionList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;


  /// Get sessions from the category and have been marked to receive public replies.
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> getArchiveMoodSessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("userId", isEqualTo: currentUser!.uid.toString())
        .where("moodId", isEqualTo: Mood.getMoodId(sessionMood))
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text(Mood.getMood(sessionMood).toString(),
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: StreamBuilder(
          stream: getArchiveMoodSessions(),
          builder: (context, AsyncSnapshot<QuerySnapshot> session) {
            if (session.connectionState == ConnectionState.waiting) {
              return RotateImage(70, 70);
            }
            if (!session.hasData) {
              return Center(
                child: Text("No Session data",
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
            if (session.hasData) {
              // clear list
              _sessionList!.clear();

              session.data!.docs.map((e) {
                _sessionList!.add(Session.fromJson(e.data()));
              }).toList();

              return Scrollbar(
                child: ListView(
                  children: [
                    ..._sessionList!
                        .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                        .toList(),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

}
