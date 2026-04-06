import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class STBColors {
  // Primary STB Brand Colors (Official Banking Colors)
  static const Color primaryBlue = Color(0xFF004990); // STB Deep Blue
  static const Color primaryGreen = Color(0xFF81B822); // STB Light Green
  static const Color white = Color(0xFFFFFFFF);

  // Dark theme accents
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2C2C2C);

  // Gradients (More subtle, professional)
  static const Color gradientStart = Color(0xFF005B9F);
  static const Color gradientEnd = Color(0xFF003875);
  static const Color greenGradientStart = Color(0xFF8DC63F);
  static const Color greenGradientEnd = Color(0xFF6A991A);

  // Status colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color danger = Color(0xFFD50000);
  static const Color info = Color(0xFF00B0FF);
  
  static const Color pending = Color(0xFFFFAB00);
  static const Color approved = Color(0xFF00C853);
  static const Color rejected = Color(0xFFD50000);

  // Text colors
  static const Color textPrimary = Color(0xFF212121); // Almost black for high readability
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Background
  static const Color bgLight = Color(0xFFF5F7FA); // App background
  static const Color bgCard = Color(0xFFFFFFFF);

  // Misc
  static const Color divider = Color(0xFFEEEEEE);
  static const Color shadow = Color(0x1F000000);
}

class STBTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: STBColors.primaryBlue,
      scaffoldBackgroundColor: STBColors.bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: STBColors.primaryBlue,
        brightness: Brightness.light,
        primary: STBColors.primaryBlue,
        secondary: STBColors.primaryGreen,
        surface: STBColors.bgCard,
        surfaceContainerHighest: const Color(0xFFF0F4F8),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: STBColors.textPrimary, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: STBColors.textPrimary, letterSpacing: -0.5),
        headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: STBColors.textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: STBColors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: STBColors.textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: STBColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: STBColors.white, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: STBColors.white),
      ),
      cardTheme: CardThemeData(
        color: STBColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: STBColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: STBColors.primaryBlue,
          foregroundColor: STBColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 4,
          shadowColor: STBColors.primaryBlue.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: STBColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: STBColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: STBColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: STBColors.primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: STBColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: STBColors.danger, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.inter(color: STBColors.textSecondary, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: STBColors.textSecondary.withValues(alpha: 0.6)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: STBColors.white,
        selectedItemColor: STBColors.primaryBlue,
        unselectedItemColor: STBColors.textSecondary.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: STBColors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // STB Gradient decoration
  static BoxDecoration get primaryGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [STBColors.gradientStart, STBColors.gradientEnd],
    ),
  );

  static BoxDecoration get headerGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0089D0), Color(0xFF005A8C), Color(0xFF003D5C)],
    ),
  );
}
