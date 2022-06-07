import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/Categories/similar_sessions_stream.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/color.dart';
import '../../utils/strings.dart';
import '../featured/model/session.dart';

/// This is a stream class showing public sessions based on their categories.


class SimilarCategorySessions extends StatelessWidget {
  Session element;

  SimilarCategorySessions({Key? key, required this.element}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured session for the trending category.
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> similarCategorySessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("repliesEnabled", isEqualTo: true)
        .where("category1", isEqualTo: element.category1.toString())
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(50)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }




  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
              stream: similarCategorySessions(),
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
                    child: SizedBox(height: 33,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              SimilarSessionsStream(element: element))
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


