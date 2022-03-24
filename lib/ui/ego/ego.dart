import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EgoPage extends StatelessWidget {
  const EgoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("Ego",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
                fontSize: 20.0,
                color: Pallet.colorBlack,
                //fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}