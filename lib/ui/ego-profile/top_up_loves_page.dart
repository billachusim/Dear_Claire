import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this
import '../../controllers/iap_controller.dart';
import '../../utils/color.dart';
import '../../widgets/toast.dart';
import '../visited_user_ego_page/visited_user_claireloves.dart'; // Ensure this matches your project path

class TopUpLovesPage extends StatelessWidget {
  final IAPController iapController = Get.put(IAPController());

  // Policy Launcher Logic
  void _launchClairePolicySite() async {
    final Uri url = Uri.parse("https://sites.google.com/view/claire-diary/claire-privacy-policy");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      AppToast.showError('Could not launch policy site');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      appBar: AppBar(
        title: Text("Top Up Loves", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (iapController.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: Pallet.colorPrimary));
              }

              if (!iapController.isAvailable.value) {
                return Center(
                  child: Text("Store is currently unavailable",
                      style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: iapController.products.length,
                itemBuilder: (context, index) {
                  final product = iapController.products[index];
                  return Card(
                    color: Pallet.colorSecondary.withValues(alpha: 200),
                    margin: EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Icon(Icons.favorite, color: Colors.redAccent, size: 30),
                      title: Text(
                        product.title.split('(').first,
                        style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text(
                        product.description,
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => iapController.buyProduct(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          product.price,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          // Privacy Policy Footer (Required for Apple/Google Compliance)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                Text(
                  "Payments are processed securely via your Store account.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 12.0,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _launchClairePolicySite,
                  child: Text(
                    "Privacy Policy & Terms of Service",
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
