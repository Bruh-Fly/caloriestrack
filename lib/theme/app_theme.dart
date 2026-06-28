import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // Colors
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface    = Color(0xFF16161E);
  static const Color surfaceAlt = Color(0xFF1E1E2A);
  static const Color accent     = Color(0xFF7C5CFC); // CalAI purple
  static const Color accentGlow = Color(0xFF9B7DFF);
  static const Color green      = Color(0xFF4ADE80);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color proteinColor  = Color(0xFF7C5CFC);
  static const Color carbsColor    = Color(0xFF4ADE80);
  static const Color fatColor      = Color(0xFFFBBF24);
  static const Color errorColor    = Color(0xFFFF6B6B);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: green,
        surface: surface,
        background: background,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
