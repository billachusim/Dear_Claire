import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/color.dart';

class CustomRotateImage extends StatefulWidget {
  late final double height;
  late final double width;

  CustomRotateImage(this.height, this.width);

  _CustomRotateImageState createState() => _CustomRotateImageState(height, width);
}

class _CustomRotateImageState extends State<CustomRotateImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double height;
  late final double width;

  _CustomRotateImageState(this.height, this.width);

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
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      body: Center(
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
      ),
    );
  }
}
