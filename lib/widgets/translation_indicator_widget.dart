import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TranslationIndicator extends StatelessWidget {
  final Color textColor;

  const TranslationIndicator({
    Key? key,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.translate,
            size: 14,
            color: textColor.withOpacity(0.7),
          ),
          SizedBox(width: 5),
          Text(
            'Translated',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
