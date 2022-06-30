import 'package:dear_claire/ui/ego-profile/empty_session_widget.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/widgets/ego_mode_session_card.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';

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
              .pushReplacementNamed(AppRoutes.diaryRooms);
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: Pallet.colorSecondaryDark,
          body: Stack(
            children: [

              FutureBuilder(
                future: firebaseServices.getDiarySessions(),
                builder: (context, AsyncSnapshot<List<Session>> session) {
                  if (session.connectionState == ConnectionState.waiting) {
                    return RotateImage(50, 50);
                  }
                  if (session.data?.length == 0) {
                    return EmptySessionWidget();
                  }

                  if (session.hasError) {
                    return Container();
                  }

                  if (session.hasData) {
                    return ListView(
                      children: [
                        DiarySessionNotice(),
                        ...session.data!
                            .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                            .toList(),
                      ],
                    );
                  }
                  return Container();
                }
                ),
        ]
          ),
        ),
      ),
    );
  }
}

/// This shows a notice header about featured sessions.
class DiarySessionNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Text(
          "Only YOUR Diary Sessions appear here. Archived Sessions can be found on Ego page.\n"
              "Open Up, write or record anything, share or save it and Claire will be there for you.",
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