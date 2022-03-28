import 'package:dear_claire/ui/alter_ego/widgets/alter_ego_session_card.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class NewDiariesPage extends StatefulWidget {
  const NewDiariesPage({Key? key}) : super(key: key);

  @override
  _NewDiariesPageState createState() => _NewDiariesPageState();
}

class _NewDiariesPageState extends State<NewDiariesPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: firebaseServices.getAlterEgoNonAssignedSessions(),
        builder: (context, AsyncSnapshot<List<Session>> session) {
          if (session.connectionState == ConnectionState.waiting) {
            return RotateImage(70, 70);
          }
          if (!session.hasData) {
            return Center(
              child: Text("There are No Sessions",
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
            return Container(
              child: Text(session.error.toString(),
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
            return ListView(
              children: [
                ...session.data!
                    .map((element) => AlterEgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                    .toList(),
              ],
            );
          }
          return Container();
        }
    );
  }
}
