import 'package:dear_claire/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThanksButton extends StatelessWidget {
  Function()? onPressed;
  int? count;
  Color color;

  ThanksButton({Key? key, required this.count, required this.onPressed, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Align(
      alignment: Alignment.topRight,
    );
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text(
          '$count Thanks 💕',
          style: GoogleFonts.lato(
              fontSize: 13.0,
              color: Pallet.colorPrimary,
              fontWeight: FontWeight.w900),
        ),
        onPressed: onPressed);
  }
}
