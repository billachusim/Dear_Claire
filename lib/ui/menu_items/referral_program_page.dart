import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/color.dart';
import '../../../utils/strings.dart';
import '../../../services/firebase_services.dart';
import '../../../helpers/toast_helper.dart';

class ReferralProgramPage extends StatelessWidget {
  final FirebaseServices _services = FirebaseServices();

  @override
  Widget build(BuildContext context) {
    String uid = _services.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("Referral Program", style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: Pallet.colorPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Invite friends and you both earn 1,000 Loves!",
                textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 18)),
            SizedBox(height: 30),
            Text("Your Referral ID:", style: TextStyle(color: Colors.grey)),
            SelectableText(uid, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: Icon(Icons.copy),
              label: Text("Copy ID"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: uid));
                showToast(message: "ID copied to clipboard");
              },
            ),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Pallet.colorPrimary, minimumSize: Size(double.infinity, 50)),
              onPressed: () {
                final String message = "${AppString.sendClaireToSomeoneHeader}\n\nMy ID: $uid\n\n${AppString.sendClaireLink}?referrer=$uid";
                Share.share(message);
              },
              child: Text("Share App", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
