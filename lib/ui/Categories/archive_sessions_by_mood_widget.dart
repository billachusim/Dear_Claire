import 'dart:ui';
import 'package:clairediary/ui/Categories/archive_mood_sessions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/color.dart';
import '../../utils/helper.dart';
import '../../utils/mood.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class ArchiveMoodStreamWidget extends StatelessWidget {
  final Session element;

  const ArchiveMoodStreamWidget({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure color is valid, provide a fallback if not
    final Color chipColor = HexColor.fromHex(element.colorHex ?? '#808080');

    return GestureDetector(
      onTap: () {
        if (element.moodId != null) {
          PageRouter.gotoWidget(
              ArchiveMoodSessions(sessionMood: element.moodId!),
              context);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0), // Rounded corners for the glass effect
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  chipColor.withValues(alpha: 0.6),
                  chipColor.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Text(
                Mood.getMood(element.moodId).toString(),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: Offset(1, 1),
                      ),
                    ]
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
