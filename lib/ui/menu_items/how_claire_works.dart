import 'dart:ui'; // Needed for BackdropFilter
import 'package:animate_do/animate_do.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ego-profile/top_up_loves_page.dart';

class HowClaireWorks extends StatefulWidget {
  const HowClaireWorks({Key? key}) : super(key: key);

  @override
  State<HowClaireWorks> createState() => _HowClaireWorksState();
}

class _HowClaireWorksState extends State<HowClaireWorks> {
  String? _expandedCardKey;

  void _handleCardTap(String cardKey) {
    setState(() {
      if (_expandedCardKey == cardKey) {
        _expandedCardKey = null;
      } else {
        _expandedCardKey = cardKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorPrimary,
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'How Claire Works',
          style: GoogleFonts.montserrat(
            fontSize: 22.0,
            color: Pallet.colorWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Image.asset("assets/images/how_claire_works_icon.png", width: 50),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          AppString.how_claire_works_header,
                          style: GoogleFonts.montserrat(
                            fontSize: 24.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- MAIN EXPANDABLE CONTENT ---
              _ExpandableContentCard(
                title: AppString.what_is_claire2,
                body: AppString.how_claire_works_paragraph2,
                isExpanded: _expandedCardKey == AppString.what_is_claire2,
                onTap: () => _handleCardTap(AppString.what_is_claire2),
                delay: 400,
              ),
              _ExpandableContentCard(
                title: AppString.who_needs_claire,
                body: AppString.how_claire_works_paragraph3,
                isExpanded: _expandedCardKey == AppString.who_needs_claire,
                onTap: () => _handleCardTap(AppString.who_needs_claire),
                delay: 500,
              ),
              _ExpandableContentCard(
                title: AppString.how_does_claire_work,
                body: AppString.how_claire_works_paragraph4,
                isExpanded: _expandedCardKey == AppString.how_does_claire_work,
                onTap: () => _handleCardTap(AppString.how_does_claire_work),
                delay: 600,
              ),
              _ExpandableContentCard(
                title: AppString.creators_quote_how_claire_works,
                body: AppString.how_claire_works_paragraph5,
                isExpanded: _expandedCardKey == AppString.creators_quote_how_claire_works,
                onTap: () => _handleCardTap(AppString.creators_quote_how_claire_works),
                delay: 700,
              ),
              _ExpandableContentCard(
                title: AppString.quick_tips,
                body: '${AppString.how_claire_works_paragraph6}\n\n${AppString.how_claire_works_paragraph7}\n\n${AppString.how_claire_works_paragraph8}\n\n${AppString.how_claire_works_paragraph9}\n\n${AppString.how_claire_works_paragraph10}\n\n${AppString.how_claire_works_paragraph11}',
                isExpanded: _expandedCardKey == AppString.quick_tips,
                onTap: () => _handleCardTap(AppString.quick_tips),
                delay: 800,
              ),

              // --- "Learn the Rules of Love" - NEW IMMERSIVE GUIDE ---
              _buildGlassCard(
                icon: Icons.favorite_rounded, // Changed Icon
                title: "Learn The Rules Of Love ❤️", // New Title
                subtitle: "Understand how Sessions, Advises, Thanks, and Loves work.", // New Subtitle
                color: const Color.fromRGBO(182, 31, 107, 1), // A distinct, lovely color
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.rulesOfLove), // Navigate to the new page
                delay: 900,
              ),

              const SizedBox(height: 8),

              // --- SECONDARY ACTIONS (STATIC GLASS CARDS) ---
              _buildGlassCard(
                icon: Icons.people_alt_rounded,
                title: "How Alter Ego Works",
                subtitle: "Discover the role of a trusted friend within the Claire community.",
                color: Pallet.colorSecondary,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks),
                delay: 1000,
              ),
              _buildGlassCard(
                icon: Icons.volunteer_activism_rounded,
                title: "Top Up Your Loves",
                subtitle: "Support the Dear Claire Project and get your donations back as Loves in your wallet.",
                color: Pallet.deepGreen,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TopUpLovesPage(),
                    ),
                  );
                },
                delay: 1100,
              ),
              _buildGlassCard(
                icon: Icons.feedback_rounded,
                title: "Send Feedback",
                subtitle: "Experienced something you don't understand? Let us know.",
                color: const Color.fromRGBO(114, 31, 182, 1),
                onTap: () {
                  String? encodeQueryParameters(Map<String, String> params) {
                    return params.entries.map((e) =>'${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
                  }
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'dearclaireapp@gmail.com',
                    query: encodeQueryParameters(<String, String>{'subject': 'Feedback About Dear Claire'}),
                  );
                  launchUrl(emailLaunchUri);
                },
                delay: 1200,
              ),

              // --- FOOTER ---
              FadeInUp(
                delay: const Duration(milliseconds: 1300),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: Center(
                    child: Text(
                      '© #DearClaire #SocialFaculty #ClaireToTheWorld',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- buildGlassCard remains the same ---
  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return FadeInUp(
      from: 50,
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color,
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ENHANCED Custom Expandable Card Widget ---
class _ExpandableContentCard extends StatelessWidget {
  final String title;
  final String body;
  final bool isExpanded;
  final VoidCallback onTap;
  final int delay;
  final IconData? icon; // Optional Icon
  final String? subtitle; // Optional Subtitle

  const _ExpandableContentCard({
    Key? key,
    required this.title,
    required this.body,
    required this.isExpanded,
    required this.onTap,
    required this.delay,
    this.icon, // Added to constructor
    this.subtitle, // Added to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      from: 50,
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Material(
            color: Colors.white.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onTap,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isExpanded ? Pallet.colorSecondary : Colors.transparent,
                        width: 4.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // If an icon is provided, show it
                          if (icon != null) ...[
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color.fromRGBO(87, 38, 2, 1.0),
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 17.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // If a subtitle is provided, show it
                                if (subtitle != null) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle!,
                                    style: GoogleFonts.lato(
                                      fontSize: 13.0,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 28),
                          ),
                        ],
                      ),
                      // The main body, which expands/collapses
                      if (isExpanded) ...[
                        const SizedBox(height: 15),
                        Text(
                          body,
                          style: GoogleFonts.lato(
                            fontSize: 15.0,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
