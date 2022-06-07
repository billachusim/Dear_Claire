import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/color.dart';
import '../../utils/helper.dart';
import '../../utils/mood.dart';
import '../featured/ego_mode_session_detail.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class UsersMoodStreamWidget extends StatefulWidget {
  Session element;

  UsersMoodStreamWidget({Key? key, required this.element}) : super(key: key);

  @override
  _UsersMoodStreamWidget createState() => _UsersMoodStreamWidget();
}

class _UsersMoodStreamWidget extends State<UsersMoodStreamWidget> {

  @override
  Widget build(BuildContext context) {
    return
      Container(
        margin: const EdgeInsets.only(top: 4),
        height: 33,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: <Widget>[

            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = widget.element.category1.toString();
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    EgoModeSessionDetail(featuredSessionModel: widget.element),
                    context);
              });
            },
              child: Container(
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: HexColor.fromHex(widget.element.colorHex!),
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Text(Mood.getMood(widget.element.moodId).toString(),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 17.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}