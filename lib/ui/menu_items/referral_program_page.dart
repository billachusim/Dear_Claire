import 'package:animate_do/animate_do.dart';
import 'package:clairediary/helpers/toast_helper.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../services/user_model.dart';
import '../ego-profile/claire_loves.dart';

class ReferralProgramPage extends StatefulWidget {
  @override
  _ReferralProgramPageState createState() => _ReferralProgramPageState();
}

class _ReferralProgramPageState extends State<ReferralProgramPage> {
  final FirebaseServices _services = FirebaseServices();
  bool _isLoading = true;
  int _referralCount = 0;
  int _lovesEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  _loadStats() async {
    final stats = await _services.getReferralStats();
    setState(() {
      _referralCount = stats['count'];
      _lovesEarned = stats['earned'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String uid = _services.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Rewards Program",
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Pallet.colorPrimary, Pallet.colorSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: FadeInDown(
                    child: Icon(Icons.card_giftcard, size: 80, color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsDashboard(),
                  20.heightBox,
                  _buildReferralCodeCard(uid),
                  30.heightBox,
                  "Earning Programs".text.bold.size(20).make(),
                  15.heightBox,
                  _buildProgramCard(
                    title: "Standard Referral",
                    subtitle: "Earn 1,000 Loves for every friend who joins.",
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    onTap: () => _shareApp(uid),
                  ),
                  15.heightBox,
                  FadeInUp(
                    delay: Duration(milliseconds: 200),
                    child: _buildProgramCard(
                      title: "Micro-Influencer Program",
                      subtitle: "Share Claire on TikTok/IG and earn up to 50,000 Loves weekly.",
                      icon: Icons.stars,
                      color: Colors.orange,
                      isHot: true,
                      onTap: () => _showInfluencerDetails(),
                    ),
                  ),
                  40.heightBox,
                  _buildHowItWorks(),
                  80.heightBox,
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Adapts to theme
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor))
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Pallet.colorPrimary,
            minimumSize: Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () => _shareApp(uid),
          child: "Invite Friends Now".text.white.bold.size(16).make(),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Referrals", _referralCount.toString()),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _statItem("Total Earned", "$_lovesEarned ❤️"),

          ElevatedButton(
            onPressed: () {
              if (_lovesEarned < 50000) {
                AppToast.showError("Minimum 50,000 Loves required to cash out.");
              } else {
                _services.requestReferralWithdrawal(50000);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 10)
            ),
            child: "Cash Out".text.white.size(10).bold.make(),
          )

        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        value.text.bold.size(22).color(Pallet.colorPrimary).make(),
        label.text.color(Colors.grey).make(),
      ],
    );
  }

  Widget _buildReferralCodeCard(String uid) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Pallet.fieldColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.transparent
        ),
      ),
      child: Column(
        children: [
          "Your Unique Referral ID"
              .text
              .size(12)
              .color(Theme.of(context).hintColor)
              .make(),
          5.heightBox,
          uid.text.bold.size(16).color(Theme.of(context).textTheme.bodyLarge?.color).make(),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: uid));
              showToast(message: "ID Copied!");
            },
            icon: Icon(Icons.copy, size: 18, color: Pallet.colorPrimary),
            label: "Copy ID".text.color(Pallet.colorPrimary).bold.make(),
          )
        ],
      ),
    );
  }


  Widget _buildProgramCard({required String title, required String subtitle, required IconData icon, required Color color, bool isHot = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isHot ? color.withValues(alpha: 0.5) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
          color: isHot ? color.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
            15.widthBox,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      title.text.bold.make(),
                      if (isHot) ...[
                        5.widthBox,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                          child: "HOT".text.white.size(8).bold.make(),
                        )
                      ]
                    ],
                  ),
                  subtitle.text.size(12).color(Theme.of(context).hintColor).make(),                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        "How it works".text.bold.color(Theme.of(context).textTheme.titleMedium?.color).make(),
        20.heightBox,
        _stepItem("1", "Share your link or ID with friends."),
        _stepItem("2", "They enter your ID when signing up."),
        _stepItem("3", "Both of you get 1,000 Loves instantly!"),
        _stepItem("4", "You remain completely anonymous with User Id"),
      ],
    );
  }

  Widget _stepItem(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          CircleAvatar(
              radius: 12,
              backgroundColor: Pallet.colorSecondary,
              child: step.text.white.size(10).bold.make()
          ),
          15.widthBox,
          Expanded(
            child: text.text
                .size(14)
                .color(Theme.of(context).textTheme.bodyMedium?.color)
                .make(),
          ),
        ],
      ),
    );
  }


  void _shareApp(String uid) {
    final String message = "${AppString.sendClaireToSomeoneHeader}\n\nMy Referral ID: $uid\n\n${AppString.sendClaireLink}?referrer=$uid";
    Share.share(message);
  }

  void _showInfluencerDetails() {
    final uid = _services.currentUser?.uid ?? "";
    final TextEditingController _motivationController = TextEditingController();
    final TextEditingController _tiktokController = TextEditingController();
    final TextEditingController _instaController = TextEditingController();
    final TextEditingController _xController = TextEditingController();
    final TextEditingController _waController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: _services.streamInfluencerApplication(uid),
        builder: (context, snapshot) {
          // If no application exists yet, default to 'none'
          String status = 'none';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            status = data['status'] ?? 'none';
          }

          return Container(

          padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20
            ),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))
                  ),
                  20.heightBox,

                  // REAL-TIME STATUS HEADER
                  if (status == 'approved')
                    FadeIn(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 20),
                            10.widthBox,
                            "Influencer Status: APPROVED".text.bold.green600.make(),
                          ],
                        ),
                      ),
                    )
                  else if (status == 'pending')
                    "Application Status: PENDING REVIEW".text.italic.orange600.make(),

                  30.heightBox,
                  "Micro-Influencer Program".text.bold.size(24).color(Pallet.colorPrimary).make(),
                  15.heightBox,
                  "Help Dear Claire grow on social media and get paid for it!".text.center.make(),
                  25.heightBox,
                  _influencerTask("Post a TikTok/Reels video", "5,000 Loves"),
                  _influencerTask("Share on WhatsApp Status", "500 Loves"),
                  _influencerTask("Mention Claire on Twitter/X", "1,000 Loves"),

                  if (status != 'approved') ...[
                    30.heightBox,
                    "Apply for Micro-Influencer".text.bold.size(20).make(),
                    15.heightBox,
                    _buildFormEmailField("TikTok Username", _tiktokController, "@username"),
                    10.heightBox,
                    _buildFormEmailField("Instagram Username", _instaController, "@username"),
                    10.heightBox,
                    _buildFormEmailField("X (Twitter) Username", _xController, "@username"),
                    10.heightBox,
                    _buildFormEmailField("WhatsApp Phone", _waController, "+123..."),
                    15.heightBox,
                    TextField(
                      controller: _motivationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Motivation / Plan to share...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    25.heightBox,
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Pallet.colorPrimary,
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: () async {
                        if (_motivationController.text.isEmpty || _tiktokController.text.isEmpty) {
                          AppToast.showError("TikTok and Motivation are required.");
                          return;
                        }
                        await _services.submitInfluencerApplication(
                          motivation: _motivationController.text,
                          tiktok: _tiktokController.text,
                          instagram: _instaController.text,
                          twitter: _xController.text,
                          whatsapp: _waController.text,
                        );
                        // No need to Navigator.pop here if you want them to see the "Pending" status immediately
                      },
                      child: "Submit & Send Email".text.white.bold.make(),
                    ),
                  ] else ...[
                    30.heightBox,
                    "You are an active partner. Keep sharing!".text.bold.color(Pallet.colorPrimary).make(),
                    "Welcome to the inner circle.".text.size(12).color(Theme.of(context).hintColor).make(),
                    50.heightBox,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildFormEmailField(String label, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }




  Widget _influencerTask(String title, String reward) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title.text.make(),
          reward.text.bold.color(Colors.green).make(),
        ],
      ),
    );
  }
}
