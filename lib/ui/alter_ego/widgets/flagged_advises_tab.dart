import 'package:clairediary/ui/alter_ego/widgets/alter_ego_session_card.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/helper.dart';
import '../../routes/routes.dart';
import '../../splash_screen/custom_rotate_bacground.dart';

class FlaggedAdvisesTab extends StatefulWidget {
  const FlaggedAdvisesTab({Key? key}) : super(key: key);

  @override
  _FlaggedAdvisesTabState createState() => _FlaggedAdvisesTabState();
}

class _FlaggedAdvisesTabState extends State<FlaggedAdvisesTab> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(

        onWillPop: (){
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.alterEgoHomepage);
          return Future.value(false);
        },
        child: Scaffold(
          body: Stack(
              children: [
                CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

                FutureBuilder(
                    future: firebaseServices.getFlaggedSessions(),
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
                                .map((element) => AlterEgoModeSessionCard(element: element, visitedEgoName: '', visitedUsersID: '',))
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
