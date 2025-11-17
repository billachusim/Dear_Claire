import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFe91e63);
const Color secondaryColor = Color(0xFFfce4ec);

final ThemeData lightTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.light(primary: primaryColor, secondary: secondaryColor),
  appBarTheme: AppBarTheme(
    color: primaryColor,
  ),
);

final ThemeData darkTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.dark(primary: primaryColor, secondary: secondaryColor),
  appBarTheme: AppBarTheme(
    color: primaryColor,
  ),
);
