import 'package:dear_claire/ui/alter_ego/widgets/alter_ego_session_card.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:dear_claire/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvisedPage extends StatefulWidget {
  const AdvisedPage({Key? key}) : super(key: key);

  @override
  _AdvisedPageState createState() => _AdvisedPageState();
}

class _AdvisedPageState extends State<AdvisedPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: firebaseServices.getAssignedSessions(),
        builder: (context, AsyncSnapshot<List<Session>> session) {
          if (session.connectionState == ConnectionState.waiting) {
            return RotateImage(70, 70);
          }
          if (!session.hasData) {
            return Center(
              child: Text("You have not advised any Session yet",
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
