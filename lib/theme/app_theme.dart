import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_profile_service.dart';

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

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: tacticalRed,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    colorScheme: const ColorScheme.light(
      primary: tacticalRed,
      secondary: amberWarning,
      surface: starkWhite,
      onPrimary: starkWhite,
      onSurface: Color(0xFF1D1D1F),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1D1F),
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1D1F),
      ),
      bodyLarge: const TextStyle(
        fontSize: 18,
        color: Colors.black87,
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

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // default is dark theme

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeStr = await UserProfileService.getTheme();
    _themeMode = (themeStr == 'light') ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await UserProfileService.saveTheme(isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
