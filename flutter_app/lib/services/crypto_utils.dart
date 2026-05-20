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

/// Manages the derived vault key in memory. The key is held only for the
/// duration of an active unlock session and is wiped automatically after
/// [sessionTimeout] of inactivity or on explicit [wipe].
class KeyManager {
  Uint8List? _key;
  Timer? _expiryTimer;

  /// Duration after the last [refresh] call before the key is wiped.
  final Duration sessionTimeout;

  /// Optional callback fired when the key is wiped (for UI lock).
  final void Function()? onLock;

  KeyManager({
    this.sessionTimeout = const Duration(minutes: 5),
    this.onLock,
  });

  bool get isUnlocked => _key != null;

  Uint8List? get currentKey => _key;

  /// Stores the derived key and starts the expiry timer.
  void activate(Uint8List derivedKey) {
    _key = Uint8List.fromList(derivedKey);
    _resetTimer();
    debugPrint('[KeyManager] Key activated, session timeout: ${sessionTimeout.inMinutes}m');
  }

  /// Resets the expiry countdown (called on each authenticated action).
  void refresh() {
    if (_key != null) _resetTimer();
  }

  /// Immediately wipes the key from memory.
  void wipe() {
    if (_key != null) {
      // Overwrite before releasing reference
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

/// Core cryptographic engine for NexPass.
///
/// Provides:
/// - Argon2id key derivation (primary)
/// - PBKDF2-HMAC-SHA512 key derivation (fallback)
/// - AES-256-GCM authenticated encryption/decryption
///
/// All CPU-intensive operations run in background [Isolate]s.
class CryptoService {
  // ── Argon2id parameters ───────────────────────────────────────────────
  static const int argon2Iterations = 3;
  static const int argon2MemoryKB = 65536; // 64 MB
  static const int argon2Parallelism = 4;

  // ── PBKDF2 parameters ────────────────────────────────────────────────
  static const int pbkdf2Iterations = 600000;
  static const int pbkdf2KeyLength = 32;

  // ── AES-256-GCM constants ────────────────────────────────────────────
  static const int keyLengthBytes = 32; // 256 bits
  static const int nonceLengthBytes = 12;
  static const int macLengthBytes = 16;

  static final crypto.AesGcm _aesGcm = crypto.AesGcm.with256bits();

  // ── Key derivation ───────────────────────────────────────────────────

  /// Derives a 256-bit key from [password] + [salt] using Argon2id.
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

  /// Derives a 256-bit key from [password] + [salt] using PBKDF2-HMAC-SHA512.
  /// Used as fallback on devices where Argon2id Isolate is unavailable.
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

  // ── AES-256-GCM encrypt / decrypt ────────────────────────────────────

  /// Encrypts [plaintext] with [secretKey].
  ///
  /// Returns a concatenated byte array:
  ///   `[12-byte nonce | ciphertext | 16-byte HMAC tag]`
  ///
  /// Runs in an [Isolate] to keep the UI thread responsive.
  Future<Uint8List> encrypt({
    required String plaintext,
    required Uint8List secretKey,
  }) async {
    final plainBytes = utf8.encode(plaintext);
    return Isolate.run(() async {
      final key = crypto.SecretKey(secretKey);
      final nonce = _aesGcm.newNonce();
      final box = await _aesGcm.encrypt(plainBytes, secretKey: key, nonce: nonce);
      return BytesBuilder()
        ..add(box.nonce)
        ..add(box.cipherText)
        ..add(box.mac.bytes)
        ..takeBytes();
    });
  }

  /// Decrypts a combined payload produced by [encrypt].
  ///
  /// The expected layout is `[12B nonce][ciphertext][16B HMAC]`.
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

  // ── Private: Argon2id ────────────────────────────────────────────────

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
      iterations: iterations,
      memory: memoryKB,
      lanes: parallelism,
      version: pc.Argon2Parameters.ARGON2_VERSION_13,
    );

    final generator = pc.Argon2BytesGenerator();
    generator.init(params);

    final out = Uint8List(keyLengthBytes);
    generator.generateBytes(passwordBytes, out, 0, keyLengthBytes);
    return out;
  }

  // ── Private: PBKDF2-HMAC-SHA512 ──────────────────────────────────────

  static Uint8List _derivePBKDF2({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));

    // Use PBKDF2KeyGenerator with HMAC-SHA512 (default digest for pointycastle)
    final generator = pc.PBKDF2KeyGenerator();
    final params = pc.Pbkdf2Parameters(salt, iterations, keyLength);

    // Deterministic — no random seed needed for KDF (salt provides entropy)
    generator.init(params);

    // generateKey returns a KeyParameter; extract the raw bytes
    final keyParam = generator.generateKey(passwordBytes, 0, passwordBytes.length);
    return keyParam;
  }
}

// ---------------------------------------------------------------------------
// Helper: Salt generation
// ---------------------------------------------------------------------------

/// Generates a cryptographically secure random salt.
Uint8List generateSalt({int length = 32}) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}
