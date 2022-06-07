import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:dear_claire/widgets/ego_mode_session_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/routes.dart';

class FollowedPage extends StatefulWidget {
  FollowedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FollowedPageState createState() => _FollowedPageState();
}

class _FollowedPageState extends State<FollowedPage> {
  List<Session>? _sessionList = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(

        onWillPop: (){
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.home);
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: Pallet.colorSecondaryDark,
          body: Stack(
            children: [
              //CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

              StreamBuilder(
              stream: firebaseServices.getFollowingSessions(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return RotateImage(50, 50);
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

                  session.data!.docs
                      .map((e) => _sessionList!.add(Session.fromJson(e.data())))
                      .toList();
                  return Scrollbar(
                    child: ListView(
                      children: [
                        FollowedSessionNotice(),
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
        ]
          ),
        ),
      ),
    );
  }
}

/// This shows a notice header about followed sessions.
class FollowedSessionNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Text(
          "Diary sessions you followed. You'll get notifications.\n"
              "Follow your own diary sessions too. Unfollow to stop notifications.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
