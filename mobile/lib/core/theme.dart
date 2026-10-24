import 'package:flutter/material.dart';

class AppTheme {
  // Soft Rose / Blush Pink Romantic Dark Palette
  static const Color background = Color(0xFF121013);
  static const Color surface = Color(0xFF1D171E);
  static const Color surfaceLight = Color(0xFF28202A);
  
  static const Color primaryRose = Color(0xFFE2849C);
  static const Color primaryRoseLight = Color(0xFFF7A8BE);
  static const Color roseDark = Color(0xFF83324C);
  
  static const Color lavenderAccent = Color(0xFFC4B5FD);
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryRose,
      colorScheme: const ColorScheme.dark(
        primary: primaryRose,
        secondary: primaryRoseLight,
        surface: surface,
        error: danger,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
