import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'color.dart';

/// Converts timeStamp from firebase
String timeConverter(Timestamp timestamp,
    {TimeConverterEnum time = TimeConverterEnum.Featured}) {
  String _date = '';

  if (time == TimeConverterEnum.Featured)
    _date = DateFormat('EEE. MMM dd, yyyy. kk:mm a').format(timestamp.toDate());

  if (time == TimeConverterEnum.Comment)
    _date = DateFormat('MMM dd, yyyy').format(timestamp.toDate());

  return _date;
}

/// Handles hexadecimal colors
extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

/// get device height
double getDeviceHeight(BuildContext context) =>
    MediaQuery.of(context).size.height;

/// get device width
double getDeviceWidth(BuildContext context) =>
    MediaQuery.of(context).size.width;

/// custom dialog box
void showCustomDialog(BuildContext context,
    {required Function()? onPressed, required String message}) {
  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("NO"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );
  Widget continueButton = TextButton(
    child: Text("YES"),
    onPressed: onPressed,
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Claire🌺"),
    content: Text(message),
    actions: [
      cancelButton,
      continueButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

/// validate users email
bool isValidEmail(String email) {
  String pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))';
  RegExp regex = new RegExp(pattern);
  return regex.hasMatch(email);
}

/// share session
void shareMessage(String message) {
  Share.share(
      '${AppString.shareHeader}\n\n$message\n${AppString.shareLink}');
}

/// share Claire to someone
void sendClaireToSomeone() {
  Share.share(
      '${AppString.sendClaireToSomeoneHeader}\n\n${AppString.sendClaireLink}');
}
