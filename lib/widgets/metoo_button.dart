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
    List<Reaction> reactions = [
      Reaction(
        icon: Text('${cheers ?? 0} Cheers👍',
            style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Colors.amber,
                fontWeight: FontWeight.w900)),
        value: 'Cheers👍',
      ),
      Reaction(
        icon: Text('${thanks ?? 0} Thanks💕',
            style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Colors.red,
                fontWeight: FontWeight.w900)),
        value: 'Thanks💕'
      ),
      Reaction(
        icon: Text('${sorry ?? 0} Sorry🖐',
            style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w900)),
          value: 'Sorry🖐'
      ),
      Reaction(
        icon: Text('${me2 ?? 0} Me2🌺',
            style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Colors.black,
                fontWeight: FontWeight.w900)),
          value: 'Me2🌺'
      ),
    ];


    switch (session.moodId) {
      case -1:
      case 0:
      case 1:
      case 11:
      case 17:
// Me2
        break;
      case 2:
      case 5:
      case 6:
      case 8:
      case 9:
      case 10:
      case 12:
      case 13:
      case 14:
// Sorry
        break;
      case 3:
      case 4:
      case 7:
      case 16:
// Cheers
        break;
      default:
// Default to Me2
    }

    void onReactionChanged(Reaction<dynamic>? reaction) {
      if (reaction != null) {
        reaction = reaction.value;
      }
    }

    return ReactionButton(
      onReactionChanged: onReactionChanged,
      reactions: reactions,
      boxColor: Colors.white,
      boxRadius: 15,
      boxPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      boxElevation: 12,
      itemSize: const Size(40, 60),
    );
  }
}
