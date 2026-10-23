import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary brand palette - Medical Grade Teal & Slate
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryTealDark = Color(0xFF0F766E);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFFCCFBF1);

  // Status & Safety Colors
  static const Color statusScheduled = Color(0xFF3B82F6); // Blue
  static const Color statusCommandSent = Color(0xFF8B5CF6); // Purple
  static const Color statusDispensed = Color(0xFF10B981); // Emerald Green
  static const Color statusAcknowledged = Color(0xFF059669); // Forest Green
  static const Color statusFailed = Color(0xFFEF4444); // Crimson Red
  static const Color statusWarning = Color(0xFFF59E0B); // Amber
  static const Color statusUnknown = Color(0xFF6B7280); // Slate Gray

  // Surface Colors
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color bgDark = Color(0xFF0B1320);
  static const Color cardDark = Color(0xFF152238);
  static const Color surfaceDarkElevated = Color(0xFF1C2C48);

  static ThemeData get lightTheme {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
        primary: primaryTeal,
        secondary: tealAccent,
        surface: bgLight,
        error: statusFailed,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF334155)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
      ),
      cardTheme: CardTheme(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.dark,
        primary: tealAccent,
        secondary: primaryTeal,
        surface: bgDark,
        error: statusFailed,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFCBD5E1)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData get highContrastTheme {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.highContrastLight(
        primary: Color(0xFF004D40),
        secondary: Color(0xFF000000),
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black),
        titleMedium: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}
