import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/services/password_generator_service.dart';

void main() {
  late PasswordGeneratorService generator;

  setUp(() {
    generator = PasswordGeneratorService();
  });

  // ── generate() ───────────────────────────────────────────────────────

  group('generate', () {
    test('produces password of requested length', () {
      final pw = generator.generate(length: 24);
      expect(pw.length, 24);
    });

    test('defaults to 16 characters', () {
      final pw = generator.generate();
      expect(pw.length, 16);
    });

    test('respects minimum length of 1', () {
      final pw = generator.generate(length: 1);
      expect(pw.length, 1);
    });

    test('all character sets included by default', () {
      final pw = generator.generate(length: 200);
      final hasUpper = pw.contains(RegExp('[A-Z]'));
      final hasLower = pw.contains(RegExp('[a-z]'));
      final hasDigits = pw.contains(RegExp('[0-9]'));
      final hasSymbols = pw.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));
      expect(hasUpper, isTrue);
      expect(hasLower, isTrue);
      expect(hasDigits, isTrue);
      expect(hasSymbols, isTrue);
    });

    test('only lowercase when all others disabled', () {
      final pw = generator.generate(
        length: 100,
        includeUppercase: false,
        includeDigits: false,
        includeSymbols: false,
      );
      expect(RegExp(r'^[a-z]+$').hasMatch(pw), isTrue);
    });

    test('only digits when selected', () {
      final pw = generator.generate(
        length: 50,
        includeUppercase: false,
        includeLowercase: false,
        includeSymbols: false,
      );
      expect(RegExp(r'^[0-9]+$').hasMatch(pw), isTrue);
    });

    test('falls back to lowercase when all sets disabled', () {
      final pw = generator.generate(
        length: 50,
        includeUppercase: false,
        includeLowercase: false,
        includeDigits: false,
        includeSymbols: false,
      );
      expect(RegExp(r'^[a-z]+$').hasMatch(pw), isTrue);
    });

    test('produces different passwords on repeated calls', () {
      final passwords = List.generate(10, (_) => generator.generate());
      final unique = passwords.toSet();
      // 16 chars from 80+ char alphabet — collisions astronomically unlikely
      expect(unique.length, 10);
    });
  });

  // ── evaluateStrength() ───────────────────────────────────────────────

  group('evaluateStrength', () {
    test('empty password returns 0.0', () {
      expect(generator.evaluateStrength(''), 0.0);
    });

    test('short password (<8 chars) scores low', () {
      final score = generator.evaluateStrength('abc');
      // no length bonus, only lowercase → 0.25 * (1/4) = 0.0625
      expect(score, lessThan(0.15));
    });

    test('8-char lowercase-only gets partial score', () {
      final score = generator.evaluateStrength('abcdefgh');
      // length ≥ 8 → 0.25, categories = 1 (lowercase) → (1/4)*0.50 = 0.125 → 0.375
      expect(score, 0.375);
    });

    test('strong password scores high', () {
      final score = generator.evaluateStrength('MyStr0ng!Pass#2024');
      // length ≥ 14 → 0.50, 4 categories → (4/4)*0.50 = 0.50 → 1.0
      expect(score, 1.0);
    });

    test('long single-category password caps at partial score', () {
      final score = generator.evaluateStrength('A' * 100);
      // length ≥ 14 → 0.50, 1 category → 0.125 → 0.625
      expect(score, 0.625);
    });

    test('score never exceeds 1.0', () {
      final pw = List.generate(16, (i) => 'Ab0!'[i % 4]).join();
      final score = generator.evaluateStrength(pw);
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('score never below 0.0', () {
      final score = generator.evaluateStrength('');
      expect(score, 0.0);
    });
  });
}
