import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta: crema cálida + negro profundo + terracota como acento
  static const Color background = Color(0xFFF5F0EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFB85C38);
  static const Color accentLight = Color(0xFFE8956D);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color border = Color(0xFFE0D8CE);
  static const Color cardBg = Color(0xFFFAF7F3);
  static const Color error = Color(0xFFB85C38);
  static const Color success = Color(0xFF4A7C59);

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      background: background,
      surface: surface,
      error: error,
    ),
    textTheme: GoogleFonts.cormorantTextTheme().copyWith(
      displayLarge: GoogleFonts.cormorant(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        color: textPrimary,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.cormorant(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.cormorant(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: surface,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.cormorant(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: 13),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: surface,
        elevation: 0,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border),
      ),
    ),
  );
}