import 'package:clairediary/ui/ego-profile/empty_session_widget.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';

import '../../widgets/toast.dart';
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          showToast("Press back again to exit.");
        },
        child: Scaffold(
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        child: Text(
          "ONLY YOUR Diary Sessions appear here. Archive can be found on Ego page.\n"
              "Open Up, write or record, share or save it and Claire will be there for you.",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}