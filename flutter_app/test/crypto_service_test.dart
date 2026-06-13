import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/services/crypto_utils.dart';

void main() {
  late CryptoService crypto;

  setUp(() {
    crypto = CryptoService();
  });

  Uint8List _randomKey() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }

  // ── AES-256-GCM round-trip ──────────────────────────────────────────

  group('AES-256-GCM encrypt/decrypt round-trip', () {
    test('simple ASCII plaintext survives round-trip', () async {
      final key = _randomKey();
      final plaintext = 'Hello, NexPass!';

      final encrypted = await crypto.encrypt(plaintext: plaintext, secretKey: key);
      final decrypted = await crypto.decrypt(encryptedData: encrypted, secretKey: key);

      expect(decrypted, plaintext);
    });

    test('empty string survives round-trip', () async {
      final key = _randomKey();
      final plaintext = '';

      final encrypted = await crypto.encrypt(plaintext: plaintext, secretKey: key);
      final decrypted = await crypto.decrypt(encryptedData: encrypted, secretKey: key);

      expect(decrypted, plaintext);
    });

    test('Unicode plaintext survives round-trip', () async {
      final key = _randomKey();
      final plaintext = '密码管理器 🔐 日本語テスト';

      final encrypted = await crypto.encrypt(plaintext: plaintext, secretKey: key);
      final decrypted = await crypto.decrypt(encryptedData: encrypted, secretKey: key);

      expect(decrypted, plaintext);
    });

    test('long plaintext survives round-trip', () async {
      final key = _randomKey();
      final plaintext = 'A' * 10000;

      final encrypted = await crypto.encrypt(plaintext: plaintext, secretKey: key);
      final decrypted = await crypto.decrypt(encryptedData: encrypted, secretKey: key);

      expect(decrypted, plaintext);
    });

    test('encrypted output is longer than plaintext (nonce + mac overhead)', () async {
      final key = _randomKey();
      final plaintext = 'test';

      final encrypted = await crypto.encrypt(plaintext: plaintext, secretKey: key);

      // nonce (12) + mac (16) + ciphertext (4) = 32 bytes, vs 4 bytes plaintext
      expect(encrypted.length, greaterThan(plaintext.length));
      expect(encrypted.length, 32); // 12 + 4 + 16
    });

    test('different encryptions produce different ciphertext (random nonce)', () async {
      final key = _randomKey();
      final plaintext = 'same input';

      final enc1 = await crypto.encrypt(plaintext: plaintext, secretKey: key);
      final enc2 = await crypto.encrypt(plaintext: plaintext, secretKey: key);

      // Nonces are random, so ciphertext should differ
      expect(
        List.generate(enc1.length, (i) => enc1[i] == enc2[i]),
        contains(false),
      );
    });
  });

  // ── Error handling ───────────────────────────────────────────────────

  group('error handling', () {
    test('wrong key throws on decrypt', () async {
      final key1 = _randomKey();
      final key2 = _randomKey();
      final plaintext = 'secret data';

      final encrypted = await crypto.encrypt(plaintext: plaintext, secretKey: key1);

      expect(
        () => crypto.decrypt(encryptedData: encrypted, secretKey: key2),
        throwsA(anything), // MAC verification failure
      );
    });

    test('truncated ciphertext throws ArgumentError', () async {
      final key = _randomKey();
      // Too short: only 10 bytes (minimum is nonce + mac = 28)
      final shortData = Uint8List(10);

      expect(
        () => crypto.decrypt(encryptedData: shortData, secretKey: key),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('empty ciphertext throws ArgumentError', () async {
      final key = _randomKey();

      expect(
        () => crypto.decrypt(
          encryptedData: Uint8List(0),
          secretKey: key,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── KeyManager integration ───────────────────────────────────────────

  group('KeyManager', () {
    test('activate + currentKey works with derived-length key', () {
      final km = KeyManager(sessionTimeout: const Duration(minutes: 1));
      final key = _randomKey();

      km.activate(key);
      expect(km.isUnlocked, isTrue);
      expect(km.currentKey!.length, 32);

      km.dispose();
    });
  });
}
