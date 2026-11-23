import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast({
  required String message,
  Color backgroundColor = Colors.black,
  Color textColor = Colors.white,
  Toast toastLength = Toast.LENGTH_SHORT,
}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: toastLength,
    backgroundColor: backgroundColor,
    textColor: textColor,
  );
}
