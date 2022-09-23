import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/featured/model/session.dart';

class MetooButton extends StatelessWidget {
  final Function(Reaction, int) onReactionChanged;
  final int? cheers;
  final int? thanks;
  final int? sorry;
  final int? me2;
  final Color color;
  final Session session;

  const MetooButton({
    Key? key,
    required this.onReactionChanged,
    this.cheers,
    this.thanks,
    this.sorry,
    this.me2,
    required this.color,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterReactionButton(
      onReactionChanged: onReactionChanged,
      reactions: [
        Reaction(
            icon: Text('${cheers ?? 0} Cheers👍',
                style: GoogleFonts.lato(
                    fontSize: 16.0,
                    color: Colors.amber,
                    fontWeight: FontWeight.w900))),
        Reaction(
            icon: Text('${thanks ?? 0} Thanks💕',
                style: GoogleFonts.lato(
                    fontSize: 16.0,
                    color: Colors.red,
                    fontWeight: FontWeight.w900))),
        Reaction(
            icon: Text('${sorry ?? 0} Sorry🖐',
                style: GoogleFonts.lato(
                    fontSize: 16.0,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w900))),
        Reaction(
            icon: Text('${me2 ?? 0} Me2🌺',
                style: GoogleFonts.lato(
                    fontSize: 16.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w900))),
      ],
      initialReaction:
      session.moodId == -1
          ? Reaction(
          icon: Text('${me2 ?? 0} Me2🌺',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

      : session.moodId == 0
          ? Reaction(
          icon: Text('${me2 ?? 0} Me2🌺',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 1
          ? Reaction(
          icon: Text('${me2 ?? 0} Me2🌺',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 2
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 3
          ? Reaction(
          icon: Text('${cheers ?? 0} Cheers👍',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 4
          ? Reaction(
          icon: Text('${cheers ?? 0} Cheers👍',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 5
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 6
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 7
          ? Reaction(
          icon: Text('${cheers ?? 0} Cheers👍',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 8
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 9
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 10
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 11
          ? Reaction(
          icon: Text('${me2 ?? 0} Me2🌺',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 12
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 13
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 14
          ? Reaction(
          icon: Text('${sorry ?? 0} Sorry🖐',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 15
          ? Reaction(
          icon: Text('${thanks ?? 0} Thanks💕',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 16
          ? Reaction(
          icon: Text('${cheers ?? 0} Cheers👍',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))

          : session.moodId == 17
          ? Reaction(
          icon: Text('${me2 ?? 0} Me2🌺',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)))


          : Reaction(
          icon: Text('${me2 ?? 0}  🌺Me2',
              style: GoogleFonts.lato (
                  fontSize: 16.0,
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
