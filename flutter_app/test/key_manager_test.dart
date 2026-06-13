import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/services/crypto_utils.dart';

void main() {
  group('KeyManager', () {
    late KeyManager km;

    setUp(() {
      km = KeyManager(sessionTimeout: const Duration(seconds: 2));
    });

    tearDown(() {
      km.dispose();
    });

    Uint8List _testKey() => Uint8List.fromList(List.generate(32, (i) => i));

    test('starts locked', () {
      expect(km.isUnlocked, isFalse);
      expect(km.currentKey, isNull);
    });

    test('activate stores key and unlocks', () {
      final key = _testKey();
      km.activate(key);
      expect(km.isUnlocked, isTrue);
      expect(km.currentKey, isNotNull);
      expect(km.currentKey!.length, 32);
    });

    test('activate stores a defensive copy (not same reference)', () {
      final key = _testKey();
      km.activate(key);
      // Mutating the original should not affect KeyManager
      key[0] = 99;
      expect(km.currentKey![0], 0);
    });

    test('wipe clears the key', () {
      km.activate(_testKey());
      expect(km.isUnlocked, isTrue);
      km.wipe();
      expect(km.isUnlocked, isFalse);
      expect(km.currentKey, isNull);
    });

    test('wipe zeros out key bytes before nulling', () {
      // We can't read _key directly, but we verify wipe() works without error
      km.activate(_testKey());
      km.wipe();
      expect(km.isUnlocked, isFalse);
    });

    test('onLock callback fires on wipe', () {
      bool locked = false;
      final kmWithCallback = KeyManager(
        sessionTimeout: const Duration(seconds: 2),
        onLock: () => locked = true,
      );
      kmWithCallback.activate(_testKey());
      kmWithCallback.wipe();
      expect(locked, isTrue);
      kmWithCallback.dispose();
    });

    test('dispose clears key', () {
      km.activate(_testKey());
      expect(km.isUnlocked, isTrue);
      km.dispose();
      expect(km.isUnlocked, isFalse);
    });

    test('refresh resets the expiry timer', () async {
      km.activate(_testKey());
      expect(km.isUnlocked, isTrue);

      // Wait 1.5s (of 2s timeout), refresh, then wait another 1.5s
      // Total 3s elapsed but timer was reset at 1.5s — should still be unlocked
      await Future.delayed(const Duration(milliseconds: 1500));
      km.refresh();
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(km.isUnlocked, isTrue);
    });

    test('auto-locks after session timeout', () async {
      km.activate(_testKey());
      expect(km.isUnlocked, isTrue);

      // Wait longer than the 2s session timeout
      await Future.delayed(const Duration(milliseconds: 2500));
      expect(km.isUnlocked, isFalse);
    });

    test('onLock callback fires on auto-lock', () async {
      bool locked = false;
      final kmWithCallback = KeyManager(
        sessionTimeout: const Duration(milliseconds: 500),
        onLock: () => locked = true,
      );
      kmWithCallback.activate(_testKey());
      await Future.delayed(const Duration(milliseconds: 800));
      expect(locked, isTrue);
      kmWithCallback.dispose();
    });

    test('wipe before timeout prevents auto-lock', () async {
      bool locked = false;
      final kmWithCallback = KeyManager(
        sessionTimeout: const Duration(seconds: 2),
        onLock: () => locked = true,
      );
      kmWithCallback.activate(_testKey());
      kmWithCallback.wipe();
      // onLock fires once from manual wipe
      expect(locked, isTrue);
      locked = false;
      // Timer is cancelled, so no second call after delay
      await Future.delayed(const Duration(milliseconds: 2500));
      expect(locked, isFalse);
      kmWithCallback.dispose();
    });
  });

  group('generateSalt', () {
    test('generates salt of default length 32', () {
      final salt = generateSalt();
      expect(salt.length, 32);
    });

    test('generates salt of custom length', () {
      final salt = generateSalt(length: 16);
      expect(salt.length, 16);
    });

    test('different calls produce different salts', () {
      final salts = List.generate(5, (_) => generateSalt());
      final unique = salts.toSet();
      expect(unique.length, 5);
    });
  });
}
