import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color tacticalRed = Color(0xFFD32F2F);
  static const Color charcoalNight = Color(0xFF121212);
  static const Color amberWarning = Color(0xFFFFA000);
  static const Color starkWhite = Color(0xFFFFFFFF);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: tacticalRed,
    scaffoldBackgroundColor: charcoalNight,
    colorScheme: const ColorScheme.dark(
      primary: tacticalRed,
      secondary: amberWarning,
      surface: Color(0xFF1E1E1E),
      onPrimary: starkWhite,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: starkWhite,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: starkWhite,
      ),
      bodyLarge: const TextStyle(
        fontSize: 18,
        color: Colors.white70,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tacticalRed,
        foregroundColor: starkWhite,
        minimumSize: const Size(64, 64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
