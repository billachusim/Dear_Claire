import 'dart:math' as math;

import 'package:flutter/material.dart';

class RotateImage extends StatefulWidget {
  late final double height;
  late final double width;

  RotateImage(this.height, this.width);

  _RotateImageState createState() => _RotateImageState(height, width);
}

class _RotateImageState extends State<RotateImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double height;
  late final double width;

  _RotateImageState(this.height, this.width);

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
        child: Image.asset(
          "assets/images/claire_icon.png",
          height: height,
          width: width,
        ),
      ),
    );
  }
}
