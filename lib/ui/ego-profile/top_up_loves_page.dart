import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/iap_controller.dart';
import '../../utils/color.dart';
import '../../utils/strings.dart';
import '../visited_user_ego_page/visited_user_claireloves.dart';

class TopUpLovesPage extends StatefulWidget {
  @override
  State<TopUpLovesPage> createState() => _TopUpLovesPageState();
}

class _TopUpLovesPageState extends State<TopUpLovesPage> {
  final IAPController iapController = Get.put(IAPController());
  late PageController _pageController;
  double _currentPage = 0.0;

  static List<String> imageSliderList = [
    "assets/images/alter_ego_slide_1.png",
    "assets/images/alter_ego_slide_2.png",
    "assets/images/alter_ego_slide_3.png",
    "assets/images/alter_ego_slide_4.png",
  ];

  final List<String> perks = [
    "Automatic Diary & Monitoring Spirit",
    "Voice & Video Calls With Claire",
    "Unlock Alter Ego Mode & Cashout",
    "Anonymous Public Diary Access",
    "Send Love Anonymously & Chatrooms",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppToast.showError('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Top Up Love",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated Background Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Pallet.colorPrimary.withValues(alpha: 0.15),
              ),
            ),
          ),

          Obx(() {
            if (iapController.isLoading.value) {
              return Center(child: CircularProgressIndicator(color: Pallet.colorPrimary));
            }

            if (!iapController.isAvailable.value) {
              return _buildErrorState("Store Connection Failed");
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 120),

                  // Circular Rolling Carousel
                  SizedBox(
                    height: 500,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: iapController.products.length,
                      itemBuilder: (context, index) {
                        final product = iapController.products[index];
                        // Animation Logic
                        double scale = (1 - ((_currentPage - index).abs() * 0.15)).clamp(0.0, 1.0);
                        double opacity = (1 - ((_currentPage - index).abs() * 0.5)).clamp(0.4, 1.0);

                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: _buildProductCard(product, index),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Donate Button (Green Glass Card)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildGlassCard(
                      icon: Icons.volunteer_activism_rounded,
                      title: "Donate To Support Claire",
                      subtitle: "Support the Dear Claire Project and get your donations back as Loves in your wallet.",
                      color: Pallet.deepGreen,
                      onTap: () {
                        final Uri donateUrl = Uri.parse(AppString.donate_url);
                        launchUrl(donateUrl);
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Legal Footer
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Pallet.colorSecondary,
            Pallet.colorSecondaryDark.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Pallet.colorPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Background Image Asset
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  imageSliderList[index % imageSliderList.length],
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 24),
                      ),
                      Text(
                        product.price,
                        style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    product.title.split('(').first.toUpperCase(),
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
                  ),
                  const SizedBox(height: 10),
                  ...perks.take(3).map((perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Pallet.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(perk, style: GoogleFonts.lato(color: Colors.white70, fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => iapController.buyProduct(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallet.colorPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: Text("Top Up", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text("Secure store payment encryption enabled.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _launchUrl("https://sites.google.com/view/claire-diary/claire-privacy-policy"),
            child: Text("Terms & Privacy Policy",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
