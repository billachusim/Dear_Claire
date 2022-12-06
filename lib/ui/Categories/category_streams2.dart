import 'package:dear_claire/ui/Categories/category_sessions.dart';
import 'package:flutter/material.dart';
import '../../utils/helper.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class CategoryStreams2 extends StatefulWidget {
  Session element;

  CategoryStreams2({Key? key, required this.element}) : super(key: key);

  @override
  _CategoryStreams2State createState() => _CategoryStreams2State();
}

class _CategoryStreams2State extends State<CategoryStreams2> {

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
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: widget.element.category1.toString()),
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
                  padding: const EdgeInsets.all(6.0),
                  child: Text(widget.element.category1.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}