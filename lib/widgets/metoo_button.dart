import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:google_fonts/google_fonts.dart';

class MetooButton extends StatelessWidget {
  final Function(Reaction, int) onReactionChanged;
  final int? cheers;
  final int? thanks;
  final int? sorry;
  final int? me2;
  final Color color;

  const MetooButton({
    Key? key,
    required this.onReactionChanged,
    this.cheers,
    this.thanks,
    this.sorry,
    this.me2,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterReactionButton(
      onReactionChanged: onReactionChanged,
      reactions: [
        Reaction(
            icon: Text('${cheers ?? 0} Cheers👍',
                style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: Colors.amber,
                    fontWeight: FontWeight.w900))),
        Reaction(
            icon: Text('${thanks ?? 0} Thanks💕',
                style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: Colors.red,
                    fontWeight: FontWeight.w900))),
        Reaction(
            icon: Text('${sorry ?? 0} Sorry🖐',
                style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w900))),
        Reaction(
            icon: Text('${me2 ?? 0} Me2🌺',
                style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: Colors.pink,
                    fontWeight: FontWeight.w900))),
      ],
      initialReaction: Reaction(
          icon: Text('${me2 ?? 0}  🌺Me2',
              style: GoogleFonts.lato (
                  fontSize: 13.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900))),

      boxColor: Colors.white,
      boxRadius: 15,
      boxPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      boxPosition: Position.BOTTOM,
      boxDuration: Duration(milliseconds: 300),
      boxItemsSpacing: 9,
      boxAlignment: AlignmentDirectional.bottomStart,
      boxElevation: 12,
    );
  }
}
