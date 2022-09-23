import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../utils/color.dart';
import '../../routes/page_router_animation.dart';
import '../ego_mode_session_detail.dart';
import '../model/session.dart';

class AudioStatusPlaying extends StatefulWidget {
  final Session element;


  AudioStatusPlaying({Key? key, required this.element}) : super(key: key);

  _AudioStatusPlayingState createState() => _AudioStatusPlayingState();
}

class _AudioStatusPlayingState extends State<AudioStatusPlaying>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller =
    AnimationController(vsync: this, duration: Duration(seconds: 3))
      ..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: child,
          );
        },
        child: Container(
          width: 75,
          height: 75,
          margin: EdgeInsets.all(2),
          child: GestureDetector(
            onTap: (){
              PageRouter.gotoWidget(
                  EgoModeSessionDetail(featuredSessionModel: widget.element),
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
                    imageUrl: widget.element.userAvatarUrl!,
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
                      "assets/images/brown_boy_mask.png",
                      width: 20,
                      height: 20,
                    ) //Icon(Icons.error),
                ),
              ),
            ),
          ),
        )
      ),
    );
  }
}
