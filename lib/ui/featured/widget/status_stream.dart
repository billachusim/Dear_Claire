import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/ui/create_session/sound/status_stream_audio_player.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/featured/ego_mode_session_detail.dart';
import 'package:flutter/material.dart';


class StatusStreamWidget extends StatelessWidget {
  Session element;


  StatusStreamWidget({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      margin: EdgeInsets.all(2),
      child: Center(
        child: Stack(
          children: [

            GestureDetector(
              onTap: (){
                PageRouter.gotoWidget(
                    EgoModeSessionDetail(featuredSessionModel: element),
                    context);
              },
              child: CachedNetworkImage(
                  width: 70,
                  height: 70,
                  imageUrl: element.userAvatarUrl!,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Image.asset(
                    "assets/images/brown_boy_mask.png",
                    width: 20,
                    height: 20,
                  ) //Icon(Icons.error),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
                child: StatusSoundPlayWidget(filePath: element.audioUrl)),

          ]
        ),
      ),
    );
  }

}
