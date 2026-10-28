import 'package:flutter/material.dart';

class AegisColors {
  // Clean Blue & White Palette
  static const Color background = Color(0xFFF8FAFC);        // Soft clean off-white
  static const Color cardSurface = Color(0xFFFFFFFF);       // Crisp pure white
  static const Color cardBorder = Color(0xFFE2E8F0);        // Subtle clean border
  static const Color cardBorderActive = Color(0xFF2563EB);   // Vibrant royal blue

  static const Color primaryBlue = Color(0xFF1D4ED8);       // Primary Navy/Royal Blue
  static const Color contactBlue = Color(0xFF2563EB);       // Accent Blue
  static const Color primaryBlueLight = Color(0xFFEFF6FF);  // Soft sky blue tint
  static const Color primaryBlueDark = Color(0xFF1E40AF);   // Deep cobalt

  // Status Accents
  static const Color policeRed = Color(0xFFDC2626);
  static const Color policeRedLight = Color(0xFFFEF2F2);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color medicalGreen = Color(0xFF059669);
  static const Color medicalGreenLight = Color(0xFFECFDF5);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFFFBEB);

  // High-contrast clean typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
}

class AegisTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AegisColors.background,
      primaryColor: AegisColors.primaryBlue,
      cardColor: AegisColors.cardSurface,
      dividerColor: AegisColors.cardBorder,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Color(0x1A000000),
        centerTitle: false,
        iconTheme: IconThemeData(color: AegisColors.primaryBlue),
        titleTextStyle: TextStyle(
          color: AegisColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AegisColors.primaryBlue,
        unselectedItemColor: AegisColors.textMuted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AegisColors.cardBorder),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AegisColors.primaryBlue,
        secondary: AegisColors.medicalGreen,
        error: AegisColors.policeRed,
        surface: AegisColors.cardSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AegisColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AegisColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AegisColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AegisColors.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
