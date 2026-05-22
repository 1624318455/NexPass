import 'package:flutter/material.dart';

/// Material Design 3 theme system for NexPass.
/// Uses ColorScheme.fromSeed() for MD3-compliant dynamic color.
class NexTheme {
  NexTheme._();

  /// MD3 seed color — deep purple/indigo (matching reference design).
  static const Color seedColor = Color(0xFF5B21B6);

  /// Theme presets matching the reference design color palettes.
  static const List<Color> themePresets = [
    Color(0xFF5B21B6), // Deep purple (default)
    Color(0xFF1D4ED8), // Blue
    Color(0xFF059669), // Green
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF7C3AED), // Violet
  ];

  // ── Semantic color aliases (for use outside ThemeData) ──────────────

  static const danger = Color(0xFFEF4444);
  static const dangerDim = Color(0xFFFEF2F2);
  static const warning = Color(0xFFF59E0B);
  static const warningDim = Color(0xFFFFFBEB);
  static const success = Color(0xFF22C55E);
  static const successDim = Color(0xFFF0FDF4);

  // ── Legacy color aliases (mapped to MD3) ────────────────────────────
  // These allow existing screen code to compile without changes.

  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const primary = Color(0xFF3B82F6);
  static const primaryDim = Color(0xFFEFF6FF);
  static const primaryGlow = Color(0xFFDBEAFE);

  // ── MD3 Spacing (8dp grid) ─────────────────────────────────────────

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  // ── MD3 Shape tokens ───────────────────────────────────────────────

  static const double rSm = 8;    // small — text fields, menus
  static const double rMd = 12;   // medium — cards
  static const double rLg = 16;   // large — FABs
  static const double rXl = 28;   // extra-large — dialogs

  // ── MD3 ThemeData (light) ──────────────────────────────────────────

  static ThemeData lightThemeWith(Color seed) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rSm),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 2,
      indicatorColor: seed.withOpacity(0.12),
    ),
  );

  static ThemeData get lightTheme => lightThemeWith(seedColor);

  // ── MD3 ThemeData (dark) ───────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rSm),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rMd),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 2,
    ),
  );
}
