import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color primaryColor = Color(0xFFe91e63);
const Color secondaryColor = Color(0xFFfce4ec);

final ThemeData lightTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    systemOverlayStyle: SystemUiOverlayStyle.light, // White icons for pink bar
  ),
);

final ThemeData darkTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: Color(0xFF121212),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    systemOverlayStyle: SystemUiOverlayStyle.light, // White icons for pink bar
  ),
);
