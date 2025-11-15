import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/Categories/category_streams.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'model/session.dart';
import '../../widgets/ego_mode_session_card.dart';

class FeaturedPage extends StatefulWidget {
  const FeaturedPage({super.key, required this.title});

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firebaseServices.getFeaturedSession(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const RotateImage(70, 70);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No Session data",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 15.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final sessionList = snapshot.data!.docs.map((doc) => Session.fromJson(doc.data())).toList();

        return Scrollbar(
          child: ListView.builder(
            itemCount: sessionList.length + 2, // +2 for CategoryStreams
            itemBuilder: (context, index) {
              if (index == 0 || index == sessionList.length + 1) {
                return const CategoryStreams();
              }
              final session = sessionList[index - 1];
              return EgoModeSessionCard(element: session, visitedUsersID: '');
            },
          ),
        );
      },
    );
  }
}
