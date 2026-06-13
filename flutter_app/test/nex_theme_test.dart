import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/theme/nex_theme.dart';

void main() {
  group('NexTheme', () {
    test('lightThemeWith returns Material 3 ThemeData', () {
      final theme = NexTheme.lightThemeWith(NexTheme.seedColor);
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('lightThemeWith uses correct seed color in ColorScheme', () {
      final theme = NexTheme.lightThemeWith(NexTheme.seedColor);
      // ColorScheme.fromSeed with seedColor should produce matching primary
      final expected = ColorScheme.fromSeed(
        seedColor: NexTheme.seedColor,
        brightness: Brightness.light,
      );
      expect(theme.colorScheme.primary, expected.primary);
    });

    test('darkThemeWith returns dark ThemeData', () {
      final theme = NexTheme.darkThemeWith(NexTheme.seedColor);
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('spacing tokens are consistent (8dp grid)', () {
      expect(NexTheme.xs, 4);
      expect(NexTheme.sm, 8);
      expect(NexTheme.md, 12);
      expect(NexTheme.lg, 16);
      expect(NexTheme.xl, 20);
      expect(NexTheme.xxl, 24);
      expect(NexTheme.xxxl, 32);
    });

    test('shape tokens are monotonically increasing', () {
      expect(NexTheme.rSm, lessThan(NexTheme.rMd));
      expect(NexTheme.rMd, lessThan(NexTheme.rLg));
      expect(NexTheme.rLg, lessThan(NexTheme.rXl));
    });

    test('themePresets contains at least 3 colors', () {
      expect(NexTheme.themePresets.length, greaterThanOrEqualTo(3));
    });

    test('semantic colors are defined', () {
      // Verify key semantic colors exist and are not transparent
      expect(NexTheme.danger.alpha, greaterThan(0));
      expect(NexTheme.warning.alpha, greaterThan(0));
      expect(NexTheme.success.alpha, greaterThan(0));
    });
  });
}
