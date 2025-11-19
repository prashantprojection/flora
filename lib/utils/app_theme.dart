import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Color Palette
  static const Color background = Color(0xFFF5F5DC);
  static const Color foreground = Color(0xFF33322E);
  static const Color card = Color(0xFFF9F9F4);
  static const Color cardForeground = Color(0xFF33322E);
  static const Color primary = Color(0xFF6B8E23);
  static const Color primaryForeground = Color(0xFFF4F8EC);
  static const Color accent = Color(0xFF9ACD32);
  static const Color accentForeground = Color(0xFF252A1A);
  static const Color destructive = Color(0xFFFA5252);
  static const Color border = Color(0xFFD4D9C5);
  static const Color input = Color(0xFFE1E5D5);
  static const Color ring = Color(0xFF6B8E23);
  static const Color muted = Color(0xFFE9EDE0);
  static const Color mutedForeground = Color(0xFF808673);

  // 2. Typography
  static final TextTheme textTheme = TextTheme(
    headlineLarge: GoogleFonts.ptSans(fontSize: 32, fontWeight: FontWeight.bold, color: foreground), // Larger headlines if needed
    titleLarge: GoogleFonts.ptSans(fontSize: 24, fontWeight: FontWeight.bold, color: foreground), // Page Title
    titleMedium: GoogleFonts.ptSans(fontSize: 20, fontWeight: FontWeight.w600, color: cardForeground), // Card Title
    bodyMedium: GoogleFonts.ptSans(fontSize: 14, fontWeight: FontWeight.normal, color: foreground), // Body (base)
    bodySmall: GoogleFonts.ptSans(fontSize: 14, fontWeight: FontWeight.normal, color: mutedForeground), // Description/Muted
    labelLarge: GoogleFonts.ptSans(fontSize: 14, fontWeight: FontWeight.w500, color: primaryForeground), // Button
    labelMedium: GoogleFonts.ptSans(fontSize: 14, fontWeight: FontWeight.w500, color: foreground), // Label
    bodyLarge: GoogleFonts.ptSans(fontSize: 16, fontWeight: FontWeight.normal, color: foreground),
    labelSmall: GoogleFonts.ptSans(fontSize: 12, fontWeight: FontWeight.normal, color: mutedForeground), // Small/Caption
  );

  // 3. Spacing & Sizing
  static const double spacing_1 = 4.0;
  static const double spacing_2 = 8.0;
  static const double spacing_3 = 12.0;
  static const double spacing_4 = 16.0;
  static const double spacing_6 = 24.0;
  static const double spacing_8 = 32.0;

  // 4. Border Radius
  static const double borderRadiusLg = 8.0;
  static const double borderRadiusMd = 6.0;
  static const double borderRadiusSm = 2.0;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: card,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: primaryForeground,
        secondary: accent,
        onSecondary: accentForeground,
        error: destructive,
        onError: Colors.white,
        surface: card,
        onSurface: cardForeground,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: card,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLg),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.all(spacing_2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size.fromHeight(40),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: ring, width: 2),
        ),
        labelStyle: textTheme.titleMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadiusLg)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: foreground),
        titleTextStyle: textTheme.titleLarge,
      ),
    );
  }
}