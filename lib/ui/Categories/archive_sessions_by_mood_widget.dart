import 'package:clairediary/ui/Categories/archive_mood_sessions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/color.dart';
import '../../utils/helper.dart';
import '../../utils/mood.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class ArchiveMoodStreamWidget extends StatefulWidget {
  Session element;

  ArchiveMoodStreamWidget({Key? key, required this.element}) : super(key: key);

  @override
  _ArchiveMoodStreamWidget createState() => _ArchiveMoodStreamWidget();
}

class _ArchiveMoodStreamWidget extends State<ArchiveMoodStreamWidget> {

  @override
  Widget build(BuildContext context) {
    return
      Container(
        margin: const EdgeInsets.only(top: 4),
        height: 40,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: <Widget>[

            GestureDetector(onTap: (){
              setState(() {
                int? featuredSessionMood = Mood.getMoodId(widget.element.moodId);
                int? moodId = featuredSessionMood;
                PageRouter.gotoWidget(
                    ArchiveMoodSessions(sessionMood: moodId!),
                    context);
              });
            },
              child: Container(
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: HexColor.fromHex(widget.element.colorHex!),
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(Mood.getMood(widget.element.moodId).toString(),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      style: GoogleFonts.lato(
                          fontSize: 18.0,
                          color: Pallet.colorWhite,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      );
  }
}