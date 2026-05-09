import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Customer Ledger Pro — Design System
/// Primary: Deep Indigo, Secondary: Emerald, built on Material 3
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3730A3);        // Deep Indigo
  static const Color primaryLight = Color(0xFF6366F1);   // Indigo 500
  static const Color primaryDark = Color(0xFF1E1B4B);    // Indigo 950

  static const Color secondary = Color(0xFF059669);      // Emerald 600
  static const Color secondaryLight = Color(0xFF34D399); // Emerald 400

  static const Color accent = Color(0xFFF59E0B);         // Amber 500
  static const Color error = Color(0xFFE11D48);          // Rose 600
  static const Color warning = Color(0xFFF97316);        // Orange 500
  static const Color success = Color(0xFF10B981);        // Emerald 500

  // ── Light Theme ───────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextHint = Color(0xFF94A3B8);

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF242438);
  static const Color darkBorder = Color(0xFF2D2D4A);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color creditGreen = Color(0xFF10B981);
  static const Color debitRed = Color(0xFFEF4444);
  static const Color pendingAmber = Color(0xFFF59E0B);
  static const Color paidGreen = Color(0xFF059669);
  static const Color overdueRed = Color(0xFFDC2626);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightText,
        ),
        textTheme: _buildTextTheme(AppColors.lightText),
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightSurface,
          foregroundColor: AppColors.lightText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.lightText,
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.lightBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.primary),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: GoogleFonts.poppins(color: AppColors.lightTextSecondary),
          hintStyle: GoogleFonts.poppins(color: AppColors.lightTextHint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.lightTextSecondary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          error: AppColors.error,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
        ),
        textTheme: _buildTextTheme(AppColors.darkText),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.darkBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          labelStyle: GoogleFonts.poppins(color: AppColors.darkTextSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.darkTextSecondary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
        ),
      );

  static TextTheme _buildTextTheme(Color baseColor) => TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: baseColor),
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: baseColor),
        headlineLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: baseColor),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: baseColor),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: baseColor),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
        titleSmall: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: baseColor),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: baseColor),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: baseColor),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: baseColor),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: baseColor),
        labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: baseColor),
      );
}
