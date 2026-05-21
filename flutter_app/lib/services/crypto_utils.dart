import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;

// ---------------------------------------------------------------------------
// KeyManager — in-memory key cache with automatic expiry
// ---------------------------------------------------------------------------

class KeyManager {
  Uint8List? _key;
  Timer? _expiryTimer;

  final Duration sessionTimeout;
  final void Function()? onLock;

  KeyManager({
    this.sessionTimeout = const Duration(minutes: 5),
    this.onLock,
  });

  bool get isUnlocked => _key != null;
  Uint8List? get currentKey => _key;

  void activate(Uint8List derivedKey) {
    _key = Uint8List.fromList(derivedKey);
    _resetTimer();
    debugPrint('[KeyManager] Key activated, session timeout: ${sessionTimeout.inMinutes}m');
  }

  void refresh() {
    if (_key != null) _resetTimer();
  }

  void wipe() {
    if (_key != null) {
      for (var i = 0; i < _key!.length; i++) {
        _key![i] = 0;
      }
    }
    _key = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    debugPrint('[KeyManager] Key wiped from memory');
    onLock?.call();
  }

  void _resetTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer(sessionTimeout, wipe);
  }

  void dispose() {
    _expiryTimer?.cancel();
    wipe();
  }
}

// ---------------------------------------------------------------------------
// CryptoService — Argon2id / PBKDF2 KDF + AES-256-GCM engine
// ---------------------------------------------------------------------------

class CryptoService {
  // Argon2id — reduced for fast debug startup; use full params in production
  static const int argon2Iterations = 2;
  static const int argon2MemoryKB = 16384; // 16 MB (production: 65536)
  static const int argon2Parallelism = 1;
  static const int keyLengthBytes = 32; // 256 bits

  // PBKDF2
  static const int pbkdf2Iterations = 600000;
  static const int pbkdf2KeyLength = 32;

  // AES-256-GCM
  static const int nonceLengthBytes = 12;
  static const int macLengthBytes = 16;

  static final crypto.AesGcm _aesGcm = crypto.AesGcm.with256bits();

  // ── Key derivation ─────────────────────────────────────────────────

  Future<Uint8List> deriveKey({
    required String password,
    required Uint8List salt,
    int iterations = argon2Iterations,
    int memoryKB = argon2MemoryKB,
    int parallelism = argon2Parallelism,
  }) async {
    return Isolate.run(() {
      return _deriveArgon2id(
        password: password,
        salt: salt,
        iterations: iterations,
        memoryKB: memoryKB,
        parallelism: parallelism,
      );
    });
  }

  Future<Uint8List> deriveKeyPBKDF2({
    required String password,
    required Uint8List salt,
    int iterations = pbkdf2Iterations,
    int keyLength = pbkdf2KeyLength,
  }) async {
    return Isolate.run(() {
      return _derivePBKDF2(
        password: password,
        salt: salt,
        iterations: iterations,
        keyLength: keyLength,
      );
    });
  }

  // ── AES-256-GCM encrypt / decrypt ──────────────────────────────────

  Future<Uint8List> encrypt({
    required String plaintext,
    required Uint8List secretKey,
  }) async {
    final plainBytes = utf8.encode(plaintext);
    return Isolate.run(() async {
      final key = crypto.SecretKey(secretKey);
      final nonce = _aesGcm.newNonce();
      final box = await _aesGcm.encrypt(plainBytes, secretKey: key, nonce: nonce);
      final result = Uint8List(nonceLengthBytes + box.cipherText.length + macLengthBytes);
      result.setRange(0, nonceLengthBytes, box.nonce);
      result.setRange(nonceLengthBytes, nonceLengthBytes + box.cipherText.length, box.cipherText);
      result.setRange(nonceLengthBytes + box.cipherText.length, result.length, box.mac.bytes);
      return result;
    });
  }

  Future<String> decrypt({
    required Uint8List encryptedData,
    required Uint8List secretKey,
  }) async {
    return Isolate.run(() async {
      if (encryptedData.length < nonceLengthBytes + macLengthBytes) {
        throw ArgumentError(
          'Encrypted payload too short: expected ≥ ${nonceLengthBytes + macLengthBytes} bytes, '
          'got ${encryptedData.length}',
        );
      }

      final key = crypto.SecretKey(secretKey);
      final nonce = encryptedData.sublist(0, nonceLengthBytes);
      final macStart = encryptedData.length - macLengthBytes;
      final cipherText = encryptedData.sublist(nonceLengthBytes, macStart);
      final mac = crypto.Mac(encryptedData.sublist(macStart));

      final box = crypto.SecretBox(cipherText, nonce: nonce, mac: mac);
      final decrypted = await _aesGcm.decrypt(box, secretKey: key);
      return utf8.decode(decrypted);
    });
  }

  // ── Private: Argon2id ──────────────────────────────────────────────

  static Uint8List _deriveArgon2id({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int memoryKB,
    required int parallelism,
  }) {
    final passwordBytes = utf8.encode(password);

    final params = pc.Argon2Parameters(
      pc.Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: keyLengthBytes,
      iterations: iterations,
      memory: memoryKB,
      lanes: parallelism,
      version: pc.Argon2Parameters.ARGON2_VERSION_13,
    );

    final generator = pc.Argon2BytesGenerator();
    generator.init(params);

    final out = Uint8List(keyLengthBytes);
    generator.deriveKey(passwordBytes, 0, out, 0);
    return out;
  }

  // ── Private: PBKDF2-HMAC-SHA256 ────────────────────────────────────

  static Uint8List _derivePBKDF2({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final mac = pc.HMac(pc.SHA256Digest(), 64);
    final generator = pc.PBKDF2KeyDerivator(mac);
    generator.init(pc.Pbkdf2Parameters(salt, iterations, keyLength));

    final out = Uint8List(keyLength);
    generator.deriveKey(passwordBytes, 0, out, 0);
    return out;
  }
}

// ---------------------------------------------------------------------------
// Salt generation
// ---------------------------------------------------------------------------

Uint8List generateSalt({int length = 32}) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}
