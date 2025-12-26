import 'package:animate_do/animate_do.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

import '../ego-profile/top_up_loves_page.dart'; // Needed for ImageFilter.blur

class HowAlterEgoWorks extends StatefulWidget {
  const HowAlterEgoWorks({Key? key}) : super(key: key);

  @override
  _HowAlterEgoWorksState createState() => _HowAlterEgoWorksState();
}

class _HowAlterEgoWorksState extends State<HowAlterEgoWorks> {
  // Use a PageController for a smoother and more standard slider
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Pallet.colorSecondaryDark : Colors.grey.shade200;
    final primaryTextColor = isDarkMode ? Pallet.colorWhite : Colors.black87;
    final secondaryTextColor = isDarkMode ? Pallet.colorTextGray : Colors.black54;

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
          'About Alter Ego',
          style: GoogleFonts.montserrat(
            fontSize: 22.0,
            color: primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // --- 1. REDESIGNED HERO SLIDER ---
              _buildHeroSlider(),

              const SizedBox(height: 40),

              // --- 2. ANIMATED CONTENT SECTIONS ---
              _buildInfoSection(
                header: AppString.what_is_alter_ego_header,
                paragraph: AppString.what_is_alter_ego_paragraph,
                isDarkMode: isDarkMode,
                delay: 400,
              ),
              _buildInfoSection(
                header: AppString.what_is_alter_ego_mode_header,
                paragraph: AppString.what_is_alter_ego_mode_paragraph,
                isDarkMode: isDarkMode,
                delay: 600,
              ),
              _buildInfoSection(
                header: AppString.how_does_it_work,
                paragraph: AppString.how_does_it_work_paragraph,
                isDarkMode: isDarkMode,
                delay: 800,
              ),
              _buildInfoSection(
                header: AppString.creators_quote,
                paragraph: AppString.creators_quote_paragraph,
                isDarkMode: isDarkMode,
                delay: 1000,
              ),

              const SizedBox(height: 30),

              // --- 3. ENHANCED CTA SECTION ---
              _buildRequestAccessButton(isDarkMode),
              const SizedBox(height: 20),
              _buildDonateButton(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: Hero Slider Widget ---
  Widget _buildHeroSlider() {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageSliderList.length,
            itemBuilder: (context, index) {
              return FadeIn(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Pallet.colorSecondary,
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: AssetImage(imageSliderList[index]),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      imageSliderDescriptionList[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SmoothPageIndicator(
          controller: _pageController,
          count: imageSliderList.length,
          effect: WormEffect(
            dotHeight: 10,
            dotWidth: 10,
            spacing: 12,
            dotColor: Colors.grey.shade400,
            activeDotColor: Pallet.colorSecondary,
          ),
        ),
      ],
    );
  }

  // --- NEW: Glassmorphism Info Section Widget ---
  Widget _buildInfoSection({
    required String header,
    required String paragraph,
    required bool isDarkMode,
    required int delay,
  }) {
    final cardColor = isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4);
    final headingColor = isDarkMode ? Colors.white : Pallet.colorSecondary;

    return FadeInUp(
      from: 50,
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 500),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: GoogleFonts.montserrat(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  paragraph,
                  style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    height: 1.5, // Improved line spacing for readability
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Rebuilt Request Access Button ---
  Widget _buildRequestAccessButton(bool isDarkMode) {
    return FadeInUp(
      from: 50,
      delay: const Duration(milliseconds: 1200),
      child: Material(
        color: Pallet.colorSecondary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final user = await firebaseServices.getUserInfo();
            if (user.currentLoveCount > 2000) {
              Navigator.pushNamed(context, AppRoutes.alterEgoRegistration);
            } else {
              showToast("...but you need 2000 Loves to request access.");
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  AppString.request_access,
                  style: GoogleFonts.montserrat(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "(Requires 2000 Loves)",
                  style: GoogleFonts.lato(
                    fontSize: 12.0,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Rebuilt Donate Button ---
  Widget _buildDonateButton() {
    return FadeInUp(
      from: 50,
      delay: const Duration(milliseconds: 1400),
      child: TextButton(
        onPressed: () {Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TopUpLovesPage(),
          ),
        );
      },
        child: Text(
          "Top Up Loves",
          style: GoogleFonts.lato(
            fontSize: 17.0,
            color: Pallet.colorPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Helper Data and Methods from original file ---
  static List<String> imageSliderList = [
    "assets/images/alter_ego_slide_1.png",
    "assets/images/alter_ego_slide_2.png",
    "assets/images/alter_ego_slide_3.png",
    "assets/images/alter_ego_slide_4.png",
  ];

  static List<String> imageSliderDescriptionList = [
    AppString.about_alter_ego_slide1,
    AppString.about_alter_ego_slide2,
    AppString.about_alter_ego_slide3,
    AppString.about_alter_ego_slide4,
  ];

  void onDonateClicked() {
    final Uri donateUrl = Uri.parse(AppString.donate_url);
    launchUrl(donateUrl);
  }
}
