import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/iap_controller.dart';
import '../../utils/color.dart';
import '../visited_user_ego_page/visited_user_claireloves.dart';

class TopUpLovesPage extends StatefulWidget {
  final String? feature;
  const TopUpLovesPage({Key? key, this.feature}) : super(key: key);

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

  // --- MODIFIED: Added new premium perks ---
  final List<String> allPerks = [
    "No Ads & All Access",
    "Get 10,000 Loves Monthly",
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
      if (_pageController.hasClients && _pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!;
        });
      }
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Top Up Love",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Pallet.colorPrimary.withAlpha(38),
              ),
            ),
          ),
          Obx(() {
            if (iapController.isLoading.value && iapController.products.isEmpty) {
              return Center(child: CircularProgressIndicator(color: Pallet.colorPrimary));
            }

            if (!iapController.isAvailable.value) {
              return _buildErrorState("Store Connection Failed");
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  _buildFeatureAd(),
                  SizedBox(
                    height: 500,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: iapController.products.length,
                      itemBuilder: (context, index) {
                        final product = iapController.products[index];
                        double scale = (1 - ((_currentPage - index).abs() * 0.15)).clamp(0.85, 1.0);
                        double opacity = (1 - ((_currentPage - index).abs() * 0.5)).clamp(0.5, 1.0);
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
                  const SizedBox(height: 60),
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

  Widget _buildProductCard(ProductDetails product, int index) {
    // --- MODIFIED: Logic to identify premium product ---
    final bool isPremium = product.id == IAPController.premiumProductId;
    final String title = isPremium ? "Premium Plan" : product.title.split('(').first.toUpperCase();
    final List<String> perksToShow = isPremium ? allPerks : allPerks.sublist(2, 5);
    final String buttonText = isPremium ? "Subscribe" : "Top Up";
    final IconData cardIcon = isPremium ? Icons.star_purple500_sharp : Icons.auto_awesome;
    final Color iconColor = isPremium ? Colors.yellowAccent : Colors.amberAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Pallet.colorSecondary,
            Pallet.colorSecondaryDark.withAlpha(204),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Pallet.colorPrimary.withAlpha(76),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  imageSliderList[index % imageSliderList.length],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: Icon(cardIcon, color: iconColor, size: 24),
                      ),
                      Text(
                        product.price,
                        style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 10),
                  ...perksToShow.map((perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Pallet.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(perk, style: GoogleFonts.lato(color: Colors.white70, fontSize: 13))),
                      ],
                    ),
                  )).toList(),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      // --- MODIFIED: Call correct purchase method ---
                      onPressed: iapController.isLoading.value
                          ? null
                          : () {
                        if (isPremium) {
                          iapController.buySubscription(product);
                        } else {
                          iapController.buyProduct(product);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPremium ? Pallet.colorPrimaryDark : Pallet.colorPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: Obx(() {
                        if (iapController.isLoading.value) {
                          return const CupertinoActivityIndicator(color: Colors.white);
                        } else {
                          return Text(buttonText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.5));
                        }
                      }),
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
            child: const Text("Terms & Privacy Policy",
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
          const Icon(Icons.cloud_off, color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFeatureAd() {
    if (widget.feature == null) return const SizedBox.shrink();

    Map<String, dynamic> ad;
    switch (widget.feature) {
      case 'renew_subscription':
        ad = {
          'title': 'Your Premium Subscription Has Expired',
          'desc': 'Renew now to continue enjoying an ad-free experience, monthly loves, and all-access features!',
          'icon': Icons.star_purple500_sharp,
          'color': Pallet.colorSecondary,
        };
        break;
      case 'autodiary':
        ad = {
          'title': 'Activate Monitoring Spirit',
          'desc': 'Auto Diary, AKA Monitoring Spirit requires Loves each time you use it, so top up loves to your wallet and unlock the magical feature of recording your diary and getting advises without touching your phone.',
          'icon': Icons.auto_awesome,
          'color': Colors.purpleAccent
        };
        break;
      case 'companion_call':
        ad = {
          'title': 'Unlock Voice Calls With Claire',
          'desc': 'Connect deeply with Claire to discuss your current situation and receive guidance. Audio calls require a small Love contribution.',
          'icon': Icons.phone_in_talk,
          'color': Colors.pinkAccent
        };
        break;
      case 'live_call':
        ad = {
          'title': 'Show Claire What Is Going On',
          'desc': 'Enter a Live Video session to show Claire what you are dealing with. Premium presence requires Love tokens.',
          'icon': Icons.videocam,
          'color': Colors.blueAccent
        };
        break;
      case 'alterego':
        ad = {
          'title': 'Access The Very Powerful Alter Ego Mode',
          'desc': 'Unlock the ultimate power of this app. Alter and Super Ego Access gives you access to a whole new side of this app that regular users can not see or use.',
          'icon': Icons.psychology,
          'color': Colors.orangeAccent
        };
        break;
      case 'diary_rooms':
        ad = {
          'title': 'Enter Diary Rooms With Love And Vibes',
          'desc': 'Join the collective consciousness in Diary Rooms. Entry fee always required to access different room corners so you must have enough love.',
          'icon': Icons.meeting_room_rounded,
          'color': Pallet.deepGreen
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (ad['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (ad['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(ad['icon'], color: ad['color'], size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 4),
                Text(ad['desc'], style: GoogleFonts.lato(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
