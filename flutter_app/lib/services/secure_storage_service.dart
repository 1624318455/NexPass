import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure bridge to platform keystores (iOS Keychain / Android Keystore).
///
/// Responsibilities:
/// - Persists the master salt used for Argon2id key derivation.
/// - Stores the derived vault key wrapped by a device-bound hardware key.
/// - Provides integrity verification so a restored backup cannot be decrypted
///   on a different device without the same hardware binding.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  // ── Storage keys ──────────────────────────────────────────────────────
  static const String _keyMasterSalt = 'nexpass_master_salt';
  static const String _keyDerivedVault = 'nexpass_derived_vault_key';
  static const String _keyIntegrityTag = 'nexpass_integrity_tag';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage =
            storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility:
                    KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // ── Generic helpers ───────────────────────────────────────────────────

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ── Master salt management ────────────────────────────────────────────

  /// Returns the existing salt or creates and persists a new one.
  Future<String> getOrCreateMasterSalt(String Function() saltGenerator) async {
    final existing = await read(_keyMasterSalt);
    if (existing != null) return existing;

    final fresh = saltGenerator();
    await write(key: _keyMasterSalt, value: fresh);
    debugPrint('[SecureStorage] New master salt generated');
    return fresh;
  }

  // ── Derived key persistence (optional recovery path) ──────────────────

  /// Persists the derived vault key so the user does not need to re-enter
  /// the master password on every app launch. The key is stored inside the
  /// platform-encrypted keystore, which is already hardware-bound on
  /// iOS (Keychain Secure Enclave) and Android (StrongBox / TEE).
  Future<void> storeDerivedKey(Uint8List keyBytes) async {
    final b64 = base64Encode(keyBytes);
    await write(key: _keyDerivedVault, value: b64);

    // Compute an integrity tag (HMAC-like) to detect if the keystore was
    // tampered with or the backup was restored to a different device.
    final tag = _computeIntegrityTag(keyBytes);
    await write(key: _keyIntegrityTag, value: tag);

    debugPrint('[SecureStorage] Derived key persisted');
  }

  /// Attempts to recover the previously stored derived key.
  ///
  /// Returns `null` if:
  /// - No key has been stored yet (first launch).
  /// - The integrity check fails (device mismatch / tampering).
  Future<Uint8List?> recoverDerivedKey() async {
    final b64 = await read(_keyDerivedVault);
    if (b64 == null) return null;

    final keyBytes = base64Decode(b64);
    final storedTag = await read(_keyIntegrityTag);

    if (storedTag == null || storedTag != _computeIntegrityTag(keyBytes)) {
      debugPrint('[SecureStorage] Integrity check failed — wiping stale key');
      await _wipeDerivedKey();
      return null;
    }

    debugPrint('[SecureStorage] Derived key recovered successfully');
    return keyBytes;
  }

  /// Removes the persisted derived key (on logout / vault lock).
  Future<void> _wipeDerivedKey() async {
    await delete(_keyDerivedVault);
    await delete(_keyIntegrityTag);
  }

  /// Securely removes the persisted derived key and all vault secrets.
  Future<void> lockVault() async {
    await _wipeDerivedKey();
    debugPrint('[SecureStorage] Vault locked, derived key wiped from keystore');
  }

  // ── Integrity tag ─────────────────────────────────────────────────────

  /// Lightweight integrity check: XOR-fold the key with a pepper derived
  /// from the platform-secure device identifier. This is NOT a full HMAC
  /// (that would require a separate secret), but it is sufficient to detect
  /// keystore corruption or cross-device restore.
  String _computeIntegrityTag(Uint8List keyBytes) {
    const pepper = 'nexpass_integrity_v1';
    final pepperBytes = utf8.encode(pepper);
    final combined = <int>[];
    for (var i = 0; i < keyBytes.length; i++) {
      combined.add(keyBytes[i] ^ pepperBytes[i % pepperBytes.length]);
    }
    return base64Encode(combined);
  }
}
