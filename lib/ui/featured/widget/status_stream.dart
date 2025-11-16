import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/ui/featured/ego_mode_session_detail.dart';
import 'package:flutter/material.dart';

import '../../../utils/color.dart';


class StatusStreamWidget extends StatelessWidget {
  final Session element;


  StatusStreamWidget({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      height: 75,
      margin: EdgeInsets.all(2),
      child: GestureDetector(
        onTap: (){
          PageRouter.gotoWidget(
              EgoModeSessionDetail(featuredSessionModel: element),
              context);
        },
        child:
        Container(
          decoration: BoxDecoration(
            color: Pallet.colorPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
          margin: EdgeInsets.only(left: 0),
          child: Container(
            height: 75,
            width: 75,
            margin: EdgeInsets.all(4),
            child: CachedNetworkImage(
                width: 70,
                height: 70,
                imageUrl: element.userAvatarUrl!,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    color: Pallet.colorWhite,
                    borderRadius: BorderRadius.circular(100),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Image.asset(
                  "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                  width: 20,
                  height: 20,
                ) //Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

}
