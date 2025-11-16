import 'package:clairediary/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FollowButton extends StatelessWidget {
  Function()? onPressed;
  int? count;
  String? text;

  FollowButton({Key? key, required this.onPressed, required this.count, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Icon(
              Icons.add_circle,
              size: 17,
              color: Pallet.colorWhite,
            ),
            Text(
              '$text $count',
              style: GoogleFonts.lato(
                  fontSize: 15.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w900)
            ),
          ],
        ),
        onPressed: onPressed);
  }
}

class FollowNoCountButton extends StatelessWidget {
  Function()? onPressed;

  FollowNoCountButton({Key? key, required this.onPressed,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Pallet.colorWhite)),
          child: Row(
            children: [
              Text(
                  ' Follow',
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w900)
              ),
            ],
          ),
        ),
        onPressed: onPressed);
  }
}