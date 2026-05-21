import 'package:flutter/material.dart';

/// Unified design system for NexPass.
/// All colors, spacings, and visual constants live here.
class NexTheme {
  NexTheme._();

  // ── Background ──────────────────────────────────────────────────────

  static const background = Color(0xFF0A0E14);
  static const surface = Color(0xFF121820);
  static const surfaceElevated = Color(0xFF1A2332);
  static const border = Color(0xFF1E2A38);
  static const borderLight = Color(0xFF253040);

  // ── Text ─────────────────────────────────────────────────────────────

  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF7D8590);
  static const textMuted = Color(0xFF484F58);

  // ── Accent ───────────────────────────────────────────────────────────

  static const primary = Color(0xFF4C9AFF);
  static const primaryDim = Color(0xFF1A3A5C);
  static const primaryGlow = Color(0xFF264D73);

  // ── Semantic ─────────────────────────────────────────────────────────

  static const danger = Color(0xFFF85149);
  static const dangerDim = Color(0xFF3D1A1A);
  static const warning = Color(0xFFD29922);
  static const warningDim = Color(0xFF3D3018);
  static const success = Color(0xFF3FB950);
  static const successDim = Color(0xFF1A3D1A);

  // ── Spacing ──────────────────────────────────────────────────────────

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  // ── Radius ───────────────────────────────────────────────────────────

  static const double rSm = 6;
  static const double rMd = 10;
  static const double rLg = 14;
  static const double rXl = 20;

  // ── Theme data ───────────────────────────────────────────────────────

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: background,
      surface: surface,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      iconTheme: IconThemeData(color: textSecondary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    iconTheme: const IconThemeData(color: textSecondary),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: const TextStyle(color: textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rXl)),
      titleTextStyle: const TextStyle(
        color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primaryDim,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? primary : textSecondary,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
  );
}
