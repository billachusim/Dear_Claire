import 'package:clairediary/ui/login/login_screen.dart';
import 'package:clairediary/ui/sign_up/sign_up.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: getDeviceWidth(context),
        height: getDeviceHeight(context),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorPrimary, Pallet.colorSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2),
              RotateImage(120, 120),
              SizedBox(height: 20),
              Text(
                AppString.appName,
                style: GoogleFonts.lato(
                  fontSize: 42.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "secret diary chat",
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  color: Pallet.colorWhite.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
              Spacer(flex: 3),
              _buildAuthButton(
                context: context,
                label: AppString.im_new_here,
                title: AppString.create_ego,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
              ),
              SizedBox(height: 20),
              _buildAuthButton(
                context: context,
                label: AppString.i_already_have_ego,
                title: AppString.open_up,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
              Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String label,
    required String title,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: getDeviceWidth(context) * 0.8,
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Pallet.colorWhite.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Pallet.colorWhite.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Pallet.colorWhite.withOpacity(0.8),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Pallet.colorWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
