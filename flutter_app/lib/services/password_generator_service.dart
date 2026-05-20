import 'dart:math';

/// Secure generator engine producing cryptographically unpredictable passwords.
class PasswordGeneratorService {
  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String digitChars = '0123456789';
  static const String symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generates a password string according to custom parameters.
  String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeDigits = true,
    bool includeSymbols = true,
  }) {
    final rand = Random.secure();
    final buffer = StringBuffer();
    final allowedChars = StringBuffer();

    if (includeLowercase) allowedChars.write(lowercaseChars);
    if (includeUppercase) allowedChars.write(uppercaseChars);
    if (includeDigits) allowedChars.write(digitChars);
    if (includeSymbols) allowedChars.write(symbolChars);

    if (allowedChars.isEmpty) {
      allowedChars.write(lowercaseChars);
    }

    final chars = allowedChars.toString();
    for (int i = 0; i < length; i++) {
      final index = rand.nextInt(chars.length);
      buffer.write(chars[index]);
    }

    return buffer.toString();
  }

  /// Calculates visual progress metrics. Returns a value from 0.0 to 1.0.
  double evaluateStrength(String password) {
    if (password.isEmpty) return 0.0;

    double score = 0.0;
    if (password.length >= 8) score += 0.25;
    if (password.length >= 14) score += 0.25;

    final hasUpper = password.contains(RegExp('[A-Z]'));
    final hasLower = password.contains(RegExp('[a-z]'));
    final hasDigits = password.contains(RegExp('[0-9]'));
    final hasSymbols = password.contains(RegExp('[!@#\$%^&*()_+\\-=\\[\\]{}|;:,.<>?]'));

    int categories = 0;
    if (hasUpper) categories++;
    if (hasLower) categories++;
    if (hasDigits) categories++;
    if (hasSymbols) categories++;

    score += (categories / 4) * 0.50;
    return score.clamp(0.0, 1.0);
  }
}
