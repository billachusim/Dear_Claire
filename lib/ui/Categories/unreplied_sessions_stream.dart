import 'package:dear_claire/ui/alter_ego/widgets/alter_ego_mode_session_detail.dart';
import 'package:flutter/material.dart';
import '../../utils/helper.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class UnrepliedSessionsStream extends StatefulWidget {
  Session element;

  UnrepliedSessionsStream({Key? key, required this.element}) : super(key: key);

  @override
  _UnrepliedSessionsStream createState() => _UnrepliedSessionsStream();
}

class _UnrepliedSessionsStream extends State<UnrepliedSessionsStream> {

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
                    AlterEgoModeSessionDetail(featuredSessionModel: widget.element),
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
                    Text(widget.element.title.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        fontSize: 17,
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