import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/Categories/category_streams.dart';
import 'package:dear_claire/ui/featured/ego_stream.dart';
import 'package:dear_claire/ui/featured/model/featured_session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/strings.dart';
import '../featured/model/session.dart';
import '../../widgets/ego_mode_session_card.dart';

class CategorySessions extends StatelessWidget {
  final String visitedCategory;

  CategorySessions({Key? key, required this.visitedCategory}) : super(key: key);

  List<Session>? _sessionList = [];

  /// Get sessions from the category and have been marked to receive public replies.
  /// But not flagged or even archived
  /// and does not have the [userId] found in the followers field
  Stream<QuerySnapshot<Map<String, dynamic>>> getCategorySessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: visitedCategory.toString())
        .where("repliesEnabled", isEqualTo: true)
        .limit(100)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text(visitedCategory,
          style: TextStyle(
              fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
          ),
        ),
        body: StreamBuilder(
          stream: getCategorySessions(),
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
