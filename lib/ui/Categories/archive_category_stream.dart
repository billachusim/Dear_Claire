import 'dart:ui';
import 'package:clairediary/ui/Categories/archive_category_sessions.dart';
import 'package:clairediary/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/helper.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class ArchiveCategoryStream extends StatelessWidget {
  final Session element;

  const ArchiveCategoryStream({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure color is valid, provide a fallback if not
    final Color chipColor = HexColor.fromHex(element.colorHex ?? '#808080');

    return GestureDetector(
      onTap: () {
        if (element.category1 != null) {
          PageRouter.gotoWidget(
              ArchiveCategorySessions(visitedCategory: element.category1!),
              context);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0), // Rounded corners
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
                element.category1.toString(),
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
