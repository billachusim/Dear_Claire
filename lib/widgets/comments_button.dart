import 'package:clairediary/utils/color.dart';
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
        child: Row(
          children: [
            Text(
                '$count ',
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w900)
            ),
            Text(
                'Advises',
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w900)
            ),
            Icon(
              Icons.mark_unread_chat_alt_outlined,
              size: 17,
              color: Pallet.colorWhite,
            ),
          ],
        ),
        onPressed: onPressed);
  }
}
