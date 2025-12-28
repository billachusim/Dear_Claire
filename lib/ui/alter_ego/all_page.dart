import 'package:clairediary/ui/alter_ego/widgets/alter_ego_session_card.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/helper.dart';
import '../Categories/category_streams.dart';
import '../routes/routes.dart';
import '../splash_screen/custom_rotate_bacground.dart';

class AllDiariesPage extends StatefulWidget {
  const AllDiariesPage({Key? key}) : super(key: key);

  @override
  _AllDiariesPageState createState() => _AllDiariesPageState();
}

class _AllDiariesPageState extends State<AllDiariesPage> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.alterEgoHomepage);
        },
        child: Scaffold(
          body: Stack(
            children: [
              CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

              FutureBuilder(
                future: firebaseServices.getAllSessions(),
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
                      shrinkWrap: true,
                      children: [
                        CategoryStreams(),
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
