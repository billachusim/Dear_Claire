import 'package:flutter/material.dart';
import '../../utils/helper.dart';
import '../featured/ego_mode_session_detail.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class SimilarSessionsStream extends StatefulWidget {
  Session element;

  SimilarSessionsStream({Key? key, required this.element}) : super(key: key);

  @override
  _SimilarSessionsStream createState() => _SimilarSessionsStream();
}

class _SimilarSessionsStream extends State<SimilarSessionsStream> {

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
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(widget.element.title.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}