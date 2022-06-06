import 'package:dear_claire/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentsButton extends StatelessWidget {
  Function()? onPressed;
  int? count;

  CommentsButton({Key? key, required this.count, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white)),
          child: Row(
            children: [
              Text(
                  '$count ',
                  style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w900)
              ),
              Icon(
                Icons.chat,
                size: 15,
                color: Pallet.colorWhite,
              ),
              Text(
                  'Advises',
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
