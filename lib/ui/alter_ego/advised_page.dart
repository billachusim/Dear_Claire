import 'package:clairediary/ui/alter_ego/empty_advising_screen_widget.dart';
import 'package:clairediary/ui/alter_ego/widgets/alter_ego_session_card.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';

import '../../utils/helper.dart';
import '../routes/routes.dart';
import '../splash_screen/custom_rotate_bacground.dart';

class AdvisedPage extends StatefulWidget {
  const AdvisedPage({Key? key}) : super(key: key);

  @override
  _AdvisedPageState createState() => _AdvisedPageState();
}

class _AdvisedPageState extends State<AdvisedPage> {
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
          body: Stack(
            children: [
              CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

              FutureBuilder(
                future: firebaseServices.getAssignedSessions(),
                builder: (context, AsyncSnapshot<List<Session>> session) {
                  if (session.connectionState == ConnectionState.waiting) {
                    return RotateImage(70, 70);
                  }
                  if (session.data?.length == 0) {
                    return EmptyAdvisingSessionWidget();
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
                ),
        ]
          ),
        ),
      ),
    );
  }
}
