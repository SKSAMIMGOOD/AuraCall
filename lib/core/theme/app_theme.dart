import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color green = Color(0xff34C759);
  static const Color red = Color(0xffFF3B30);
  static const Color blue = Color(0xff0A84FF);
  static const Color background = Color(0xff000000);
  
  // Glassmorphic surface colors
  static const Color glassSurface = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassBorder = Color(0x26FFFFFF);  // rgba(255,255,255,0.15)
  static const Color glassText = Colors.white;
  static const Color glassTextSecondary = Colors.white70;
  static const Color glassTextMuted = Colors.white38;

  // Dark gradients
  static const List<Color> darkBackgroundGradient = [
    Color(0xff000000),
    Color(0xff080B10),
    Color(0xff030508),
  ];
}

class AppTheme {
  static ThemeData get amoledDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue,
        secondary: AppColors.green,
        error: AppColors.red,
        background: AppColors.background,
        surface: AppColors.glassSurface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1),
          headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5),
          headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
          bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
          bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white70),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.glassSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.0),
        ),
        elevation: 0,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.black.withOpacity(0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.0),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.blue,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: AppColors.blue.withOpacity(0.2),
        trackHeight: 4,
      ),
    );
  }

  static ThemeData get lightGlassTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xffF4F5F9),
      colorScheme: const ColorScheme.light(
        primary: AppColors.blue,
        secondary: AppColors.green,
        error: AppColors.red,
        background: Color(0xffF4F5F9),
        surface: Color(0x0D000000),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: -1),
          headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.black, letterSpacing: -0.5),
          headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
          bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
          bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black80),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0x0D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
          side: const BorderSide(color: Color(0x1A000000), width: 1.0),
        ),
        elevation: 0,
      ),
    );
  }
}
