import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/followed/empty_followed_screen_widget.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:dear_claire/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import '../../widgets/toast.dart';
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
        onWillPop: () {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          showToast("Press back again to exit.");
          return Future.value(false);
        },
        child: Scaffold(
          body: Stack(
            children: [

              StreamBuilder(
              stream: firebaseServices.getFollowingSessions(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return RotateImage(50, 50);
                }
                if (session.data?.docs.length == 0) {
                  return EmptyFollowedSessionWidget();
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
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
