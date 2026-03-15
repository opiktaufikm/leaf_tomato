import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF2D6B24);
  static const Color lightGreen = Color(0xFF4A8C3F);
  static const Color accentGreen = Color(0xFFEBF5E8);
  static const Color tomatoRed = Color(0xFFC8442A);
  static const Color lightRed = Color(0xFFFEF3F1);
  static const Color tealAccent = Color(0xFF2A7068);
  static const Color lightTeal = Color(0xFFE8F4F2);

  // Neutral
  static const Color background = Color(0xFFFAFAF8);
  static const Color cardBackground = Colors.white;
  static const Color borderColor = Color(0xFFE8F0E6);
  static const Color mutedText = Color(0xFF9AAF98);
  static const Color subtleText = Color(0xFF7A8F78);
  static const Color darkText = Color(0xFF1C2B1A);

  // Warning
  static const Color warningAmber = Color(0xFFB57210);
  static const Color lightAmber = Color(0xFFFEF8EE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        background: background,
        surface: cardBackground,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
