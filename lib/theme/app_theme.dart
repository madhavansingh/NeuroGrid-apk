import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // NeuroGrid Brand Colors — Soft Blue Civic Palette
  static const Color primary = Color(0xFF1A6BF5);
  static const Color primaryLight = Color(0xFFEBF1FF);
  static const Color primaryMuted = Color(0xFF6B9EFF);
  static const Color primaryDark = Color(0xFF1250C4);

  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4FF);
  static const Color background = Color(0xFFF5F7FF);
  static const Color outline = Color(0xFFE2E8F4);
  static const Color outlineVariant = Color(0xFFF1F4FB);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF9BA8C0);

  // Traffic semantic colors
  static const Color trafficHeavy = Color(0xFFEF4444);
  static const Color trafficHeavyLight = Color(0xFFFEE2E2);
  static const Color trafficModerate = Color(0xFFF59E0B);
  static const Color trafficModerateLight = Color(0xFFFEF3C7);
  static const Color trafficClear = Color(0xFF22C55E);
  static const Color trafficClearLight = Color(0xFFDCFCE7);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryLight,
        secondary: primaryMuted,
        secondaryContainer: Color(0xFFD6E4FF),
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        error: error,
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: textPrimary,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: Color(0xFF1E293B),
        onInverseSurface: Color(0xFFF8FAFC),
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        hintStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B9EFF),
        primaryContainer: Color(0xFF1A3A7A),
        secondary: Color(0xFF93B8FF),
        surface: Color(0xFF1A1F2E),
        surfaceContainerHighest: Color(0xFF232A3B),
        error: Color(0xFFF87171),
        onPrimary: Color(0xFF0F1420),
        onSurface: Color(0xFFF1F5FB),
        outline: Color(0xFF2D3748),
        outlineVariant: Color(0xFF1E2535),
        inverseSurface: Color(0xFFF1F5FB),
        onInverseSurface: Color(0xFF0F1420),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1420),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
    );
  }
}
