import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/Categories/archive_sessions_by_mood_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/color.dart';
import '../../utils/strings.dart';
import '../featured/model/session.dart';

/// This is a stream class showing public sessions based on their moods.


class ArchiveMoodStream extends StatelessWidget {

  ArchiveMoodStream({Key? key}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured session for the trending category.
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> archiveSessionsByMoods() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("moodId", isNotEqualTo: null)
        .limit(50)
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }




  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
              stream: archiveSessionsByMoods(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return Text("");
                }
                if (!session.hasData) {
                  return Center(
                    child: Text("No Session data",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 3.0,
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
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              ArchiveMoodStreamWidget(element: element))
                              .toList(),
                        ],
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      );
  }

}
