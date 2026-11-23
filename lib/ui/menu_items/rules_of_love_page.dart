import 'package:animate_do/animate_do.dart';
import 'package:clairediary/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RulesOfLovePage extends StatelessWidget {
  const RulesOfLovePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Pallet.colorSecondaryDark : Colors.grey.shade100;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'The Rules Of Love ❤️',
          style: GoogleFonts.montserrat(
            fontSize: 22.0,
            color: primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleSection(
              delay: 200,
              icon: Icons.favorite_border_rounded,
              title: "How Sessions & Advises Are Counted",
              content:
              "For a diary session to be counted, it must contain the phrase 'Dear Claire' and be more than 50 characters long.\n\n"
                  "For an advise to be counted, it must contain the word 'Darling', be at least 20 characters long, and be sent within 24 hours of the diary session.\n\n"
                  "Claire reserves the right to adjust counts during verification processes.",
            ),
            _RuleSection(
              delay: 300,
              icon: Icons.card_giftcard_rounded,
              title: "How Thanksgiving Works",
              content:
              "It's great to give 'Thanks' to show appreciation for helpful advises. When you thank an advise:\n\n"
                  "• The receiving Ego gets 1 Love ❤️\n"
                  "• An advising Alter Ego gets 3 Loves ❤️❤️❤️\n"
                  "• Claire gets 2 Loves ❤️❤️",
            ),
            _RuleSection(
              delay: 400,
              icon: Icons.sentiment_satisfied_alt_rounded,
              title: "How 'Me2' & Other Reactions Work",
              content:
              "Reactions are a quick way to show empathy and connect with a session. The available reactions are based on the mood set by the user during session creation.\n\n"
                  "Choosing the right reaction shows you understand, and it gives the session owner 1 Love ❤️.",
            ),
            _RuleSection(
              delay: 500,
              icon: Icons.visibility_rounded,
              title: "Visiting Egos (Profiles)",
              content:
              "An 'Ego' is a user's profile. You can visit another user's Ego to see their public activities and send them love directly.\n\n"
                  "Each visit costs a 'kola' of 1 Love ❤️.",
            ),
            _RuleSection(
              delay: 600,
              icon: Icons.groups_rounded,
              title: "Joining Rooms & Corners",
              content:
              "Rooms are public spaces for discussion hosted by Claire. Joining one of Claire's rooms costs 1 Love ❤️.\n\n"
                  "Inside a room, users can create their own 'Corners' for more focused chats. To join a user's Corner, it costs 2 Loves ❤️, which are sent directly to the Corner's creator, and 1 Love ❤️ to Claire.",
            ),
            _RuleSection(
              delay: 700,
              icon: Icons.send_rounded,
              title: "Sending & Receiving Love",
              content:
              "Love ❤️ is the currency of the Dear Claire world. You can send love directly to a user's wallet by visiting their Ego.\n\n"
                  "You can also use your wallet to initiate instant love transfers, receive payments, or conclude business transactions within the app's ecosystem.",
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final int delay;
  final IconData icon;
  final String title;
  final String content;

  const _RuleSection({
    Key? key,
    required this.delay,
    required this.icon,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDarkMode ? Pallet.colorPink : Pallet.colorSecondary;
    final textColor = isDarkMode ? Colors.white70 : Colors.black.withValues(alpha: 0.7);
    final cardColor = isDarkMode ? Colors.black.withValues(alpha: 0.15) : Colors.white;

    return FadeInUp(
      from: 40,
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 25.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: isDarkMode
              ? []
              : [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: headingColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              content,
              style: GoogleFonts.lato(
                fontSize: 15.0,
                color: textColor,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
