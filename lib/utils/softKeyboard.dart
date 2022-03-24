
import 'package:flutter/material.dart';

var currentFocus;

/// unfocus the soft keyboard.
unfocus(BuildContext context) {
  currentFocus = FocusScope.of(context);

  if (!currentFocus.hasPrimaryFocus) {
    currentFocus.unfocus();
  }
}

/// Hide the soft keyboard.
// void hideKeyboard(BuildContext context) {
//   FocusScope.of(context).requestFocus(FocusNode());
// }

/// Hide the soft keyboard.
void hideKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}