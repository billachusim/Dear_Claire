import 'package:clairediary/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnfollowButton extends StatelessWidget {
  Function()? onPressed;

  UnfollowButton({Key? key, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Pallet.colorWhite)),
          child: Row(
            children: [
              Icon(
                Icons.minimize,
                size: 14,
                color: Pallet.colorWhite,
              ),
              Text(
                ' Unfollow',
                style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w900)
              ),
            ],
          ),
        ),
        onPressed: onPressed);
  }
}