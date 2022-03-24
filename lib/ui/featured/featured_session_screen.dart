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

import 'model/session.dart';
import '../../widgets/ego_mode_session_card.dart';

class FeaturedPage extends StatefulWidget {
  FeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {
  List<Session>? _sessionList = [];
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firebaseServices.getFeaturedSession(),
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
                CategoryStreams(),
                ..._sessionList!
                    .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '',))
                    .toList(),
                CategoryStreams(),
              ],
            ),
          );
        }
        return Container();
      },
    );
  }
}
