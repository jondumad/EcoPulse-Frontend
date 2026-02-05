import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Eco-Pulse Color Palette
  static const Color clay = Color(0xFFF4F1EE); // Main background
  static const Color forest = Color(0xFF1B4332); // Primary actions, trust
  static const Color violet = Color(0xFF7F30FF); // Highlights, energy
  static const Color terracotta = Color(0xFFD66853); // Warnings, tags
  static const Color ink = Color(0xFF1A1C1E); // Text, dark cards

  static const Color glass = Color.fromRGBO(255, 255, 255, 0.6);
  static const Color paperShadow = Color.fromRGBO(0, 0, 0, 0.05);
  static const Color borderSubtle = Color.fromRGBO(0, 0, 0, 0.05);

  // Legacy Mappings (Temporary for Refactoring)
  static const Color primaryGreen = forest;
  static const Color primaryBlue = forest; // Mapping to primary forest for now
  static const Color accentOrange = terracotta;
  static const Color backgroundLight = clay;
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = ink;
  static const Color textGrey = Color(
    0xFF7F8C8D,
  ); // Keep original grey for now or map to ink.withAlpha
  static const Color textMedium = Color(0xFF95A5A6);

  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: clay,
      colorScheme: const ColorScheme.light(
        primary: forest,
        secondary: violet,
        tertiary: terracotta,
        onSurface: ink,
        surface: clay,
        error: terracotta,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: TextTheme(
        // Fraunces - Display & Headers
        displayLarge: GoogleFonts.fraunces(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: ink,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          color: ink,
        ),
        displaySmall: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: ink,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
          color: ink,
        ),

        // Inter - Body
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ink,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ink.withValues(alpha: 0.6),
        ),

        // JetBrains Mono - Data & Labels (Section Labels)
        labelLarge: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: ink.withValues(alpha: 0.6),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: clay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: ink,
        ),
        iconTheme: IconThemeData(color: ink),
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Keep status bar icons dark
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: forest, width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: ink.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
