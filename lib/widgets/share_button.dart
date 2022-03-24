import 'package:dear_claire/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareButton extends StatelessWidget {
  Function()? onPressed;
  Color color;
  ShareButton({Key? key, required this.onPressed, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, )),
          child: Row(
            children: [
              Icon(
                Icons.share_rounded,
                size: 15,
                color: Pallet.colorWhite,
              ),              Text(
                '  Share',
                style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        onPressed: onPressed);
  }
}
