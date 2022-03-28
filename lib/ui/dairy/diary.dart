import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/widgets/ego_mode_session_card.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/cupertino.dart';

import '../routes/routes.dart';


class DiaryPage extends StatefulWidget {
  DiaryPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {

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
          body: FutureBuilder(
              future: firebaseServices.getDiarySessions(),
              builder: (context, AsyncSnapshot<List<Session>> session) {
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

                if (session.hasError) {
                  return Container();
                }

                if (session.hasData) {
                  return ListView(
                    children: [
                      ...session.data!
                          .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                          .toList(),
                    ],
                  );
                }
                return Container();
              }
              ),
        ),
      ),
    );
  }
}