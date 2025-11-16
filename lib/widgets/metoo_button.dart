import 'package:flutter/material.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/featured/model/session.dart';

class MetooButton extends StatelessWidget {
  final Function(String, int) onReactionChanged;
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
    // Map your reactions to integer values
    final emojiPreset = StaticEmojiPreset([
      /*StaticEmoji(image: 'assets/images/cheers.svg', value: 1),
      StaticEmoji(image: 'assets/images/thanks.svg', value: 2),
      StaticEmoji(image: 'assets/images/sorry.svg', value: 3),
      StaticEmoji(image: 'assets/images/me2.svg', value: 4),*/
    ]);

    // Map integers back to labels for callback
    final valueToLabel = {
      1: 'Cheers👍',
      2: 'Thanks💕',
      3: 'Sorry🖐',
      4: 'Me2🌺',
    };

    // Determine default rating based on session.moodId
    int defaultRating;
    switch (session.moodId) {
      case -1:
      case 0:
      case 1:
      case 11:
      case 17:
        defaultRating = 4;
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
        defaultRating = 3;
        break;
      case 3:
      case 4:
      case 7:
      case 16:
        defaultRating = 1;
        break;
      default:
        defaultRating = 4;
    }

    return EmojiFeedback(
      emojiPreset: emojiPreset,
      initialRating: defaultRating,
      elementSize: 50,
      showLabel: true,
      labelTextStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
      onChanged: (value) {
        // value is int from 1 to 4
        final label = valueToLabel[value]!;
        int count;
        switch (value) {
          case 1:
            count = cheers ?? 0;
            break;
          case 2:
            count = thanks ?? 0;
            break;
          case 3:
            count = sorry ?? 0;
            break;
          case 4:
            count = me2 ?? 0;
            break;
          default:
            count = 0;
        }
        onReactionChanged(label, count);
      },
    );
  }
}
