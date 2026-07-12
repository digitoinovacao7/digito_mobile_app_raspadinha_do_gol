import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores Premium - Dark Mode Neon
  static const Color primaryGreen = Color(0xFF39FF14); // Neon Green
  static const Color accentGold = Color(0xFFFFD700); // Dourado Vibrante
  static const Color backgroundDark = Color(0xFF090D14); // Fundo quase preto
  static const Color surfaceDark = Color(0xFF151C2A); // Superfície dos cards
  static const Color textLight = Color(0xFFFFFFFF); // Branco puro
  static const Color textMuted = Color(0xFF94A3B8); // Cinza azulado
  static const Color errorRed = Color(0xFFFF4444);

  // Aliases de compatibilidade para outras telas
  static const Color textDark = textLight; 
  static const Color backgroundWhite = backgroundDark;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGold,
        surface: surfaceDark,
        error: errorRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textLight,
          fontWeight: FontWeight.w900,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textLight,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textLight,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: primaryGreen),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: backgroundDark,
          elevation: 8,
          shadowColor: primaryGreen.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
    );
  }
}
