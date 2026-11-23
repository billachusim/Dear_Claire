import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/enums.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Converts timeStamp from firebase
String timeConverter(Timestamp timestamp,
    {TimeConverterEnum time = TimeConverterEnum.Featured}) {
  String _date = '';

  if (time == TimeConverterEnum.Featured)
    // Changed 'kk:mm' to 'hh:mm a' for 12-hour format with AM/PM
    _date = DateFormat('EEE. MMM dd, yyyy. hh:mm a').format(timestamp.toDate());

  if (time == TimeConverterEnum.Comment)
    _date = DateFormat('MMM dd, yyyy').format(timestamp.toDate());

  return _date;
}


String formatFirestoreTimestamp(Timestamp timestamp) {
  // Converts Firestore Timestamp to a DateTime object
  DateTime dateTime = timestamp.toDate();
  final String formattedDate = DateFormat('h:mm a, E, MMM d, y').format(dateTime);

  return formattedDate;
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

// Private stateful widget to manage the dialog's loading state
class _StatefulCustomDialog extends StatefulWidget {
  final String message;final Function()? onPressed;

  const _StatefulCustomDialog({
    required this.message,
    required this.onPressed,
  });

  @override
  _StatefulCustomDialogState createState() => _StatefulCustomDialogState();
}

class _StatefulCustomDialogState extends State<_StatefulCustomDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("NO"),
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(), // Disable while loading
    );

    Widget continueButton = TextButton(
      child: _isLoading
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Text("YES"),
      onPressed: widget.onPressed == null || _isLoading
          ? null // Disable button if no action or already loading
          : () async {
        setState(() {
          _isLoading = true; // Show progress indicator
        });

        // Await the passed function
        if (widget.onPressed != null) {
          await widget.onPressed!();
        }

        // Only pop if the dialog is still mounted (the async operation might have closed it)
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    // set up the AlertDialog
    return AlertDialog(
      title: Text("Claire🌺"),
      content: Text(widget.message),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
  }
}


/// custom dialog box
void showCustomDialog(BuildContext context,
    {required Function()? onPressed, required String message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return _StatefulCustomDialog(
        message: message,
        onPressed: onPressed,
      );
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
