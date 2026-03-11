import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary & Accent
  static const Color primary = Color(0xFF7C3AED); // Royal Purple
  static const Color secondary = Color(0xFF10B981); // Emerald
  
  // Dark Theme Colors (Deep Obsidian/Zinc)
  static const Color backgroundDark = Color(0xFF070708);
  static const Color surfaceDark = Color(0xFF121216);
  static const Color textPrimaryDark = Color(0xFFF1F1F3);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color dividerDark = Color(0xFF1E1E24);

  // Light Theme Colors (Soft Bone/Slate)
  static const Color backgroundLight = Color(0xFFF9F9FB);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color dividerLight = Color(0xFFE2E8F0);
  
  // Status Colors (Sophisticated)
  static const Color income = Color(0xFF38BDF8); // Sophisticated Sky
  static const Color expense = Color(0xFFFB7185); // Soft Rose
  
  // Category Colors (Refined Palette)
  static const List<Color> categoryColors = [
    Color(0xFF818CF8),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFB923C),
    Color(0xFFFB7185),
    Color(0xFFA78BFA),
  ];
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
    ),
    dividerColor: AppColors.dividerDark,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: GoogleFonts.outfit(
        color: AppColors.textPrimaryDark, 
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.outfit(
        color: AppColors.textPrimaryDark, 
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(color: AppColors.textPrimaryDark),
      bodyMedium: GoogleFonts.inter(color: AppColors.textSecondaryDark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.dividerDark, width: 1),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
    ),
    dividerColor: AppColors.dividerLight,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineMedium: GoogleFonts.outfit(
        color: AppColors.textPrimaryLight, 
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.outfit(
        color: AppColors.textPrimaryLight, 
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(color: AppColors.textPrimaryLight),
      bodyMedium: GoogleFonts.inter(color: AppColors.textSecondaryLight),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}
