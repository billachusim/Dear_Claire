import 'package:clairediary/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FollowButton extends StatelessWidget {  final Function()? onPressed;
final int? count;
final String? text;
final bool isLoading; // New parameter

const FollowButton({
  Key? key,
  required this.onPressed,
  required this.count,
  required this.text,
  this.isLoading = false, // Default to false
}) : super(key: key);

@override
Widget build(BuildContext context) {
  return CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: isLoading ? null : onPressed, // Disable button when loading
    child: isLoading
        ? const SizedBox(
      width: 17,
      height: 17,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_circle,
          size: 17,
          color: Pallet.colorWhite,
        ),
        const SizedBox(width: 4),
        Text(
          '$text $count',
          style: GoogleFonts.lato(
            fontSize: 15.0,
            color: Pallet.colorWhite,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
}