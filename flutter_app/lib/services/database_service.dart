import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;

import '../models/nex_item.dart';
import 'crypto_utils.dart';

// ---------------------------------------------------------------------------
// AesGcmFileCipher — Isar encryption cipher using AES-256-GCM
// ---------------------------------------------------------------------------

/// Encrypts every Isar file chunk with AES-256-GCM before writing to disk.
///
/// Each chunk receives a unique 12-byte random nonce prepended to the
/// ciphertext, and the 16-byte authentication tag is appended. This means
/// on-disk format per chunk is:
///
///   `[12-byte nonce][encrypted data][16-byte GCM tag]`
///
/// The cipher is stateless — the same key can safely be reused across
/// different chunks because every nonce is unique.
class AesGcmFileCipher implements IsarEncryptionCipher {
  final Uint8List _keyBytes;
  final pc.AEADBlockCipher _cipher;
  static const int _nonceLength = 12;

  AesGcmFileCipher(this._keyBytes)
      : _cipher = pc.GCMBlockCipher(pc.AESEngine());

  @override
  Uint8List encrypt(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;

    final keyParam = pc.KeyParameter(_keyBytes);
    final nonce = _randomNonce();

    _cipher.init(true, pc.AEADParameters(keyParam, 128, nonce, Uint8List(0)));

    final cipherBytes = Uint8List.fromList(
      [nonce, _cipher.process(bytes)].expand((b) => b).toList(),
    );
    return cipherBytes;
  }

  @override
  Uint8List decrypt(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;

    if (bytes.length < _nonceLength + 16) {
      throw StateError(
        'Encrypted chunk too short: ${bytes.length} bytes '
        '(need at least ${_nonceLength + 16} for nonce + auth tag)',
      );
    }

    final nonce = bytes.sublist(0, _nonceLength);
    final cipherText = bytes.sublist(_nonceLength);

    final keyParam = pc.KeyParameter(_keyBytes);
    _cipher.init(false, pc.AEADParameters(keyParam, 128, nonce, Uint8List(0)));

    return _cipher.process(cipherText);
  }

  static Uint8List _randomNonce() {
    final secure = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(Uint8List.fromList(
        List.generate(32, (_) => pc.SecureRandom('Fortuna').nextUint8()),
      )));
    return secure.nextBytes(_nonceLength);
  }
}

// ---------------------------------------------------------------------------
// DatabaseService — Isar lifecycle + encryption configuration
// ---------------------------------------------------------------------------

/// Manages the Isar database lifecycle.
///
/// On first launch the service:
/// 1. Derives or recovers the vault encryption key via [SecureStorageService].
/// 2. Configures Isar to encrypt every file chunk with AES-256-GCM.
/// 3. Stores the derived key in the platform keystore for subsequent launches.
///
/// All heavy work (key derivation, Isar open) is performed in [initialize].
class DatabaseService {
  static Isar? _instance;
  static AesGcmFileCipher? _cipher;

  /// Returns the active encryption cipher (available after [initialize]).
  static AesGcmFileCipher? get cipher => _cipher;

  /// Initializes the encrypted Isar database.
  ///
  /// [derivedKey] is the 256-bit key produced by Argon2id from the master
  /// password + salt. It is used both as the file-level encryption key and
  /// is persisted in the platform keystore for convenience unlocks.
  static Future<Isar> initialize({
    required Uint8List derivedKey,
    required SecureStorageService secureStorage,
  }) async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    // Build the file-level cipher
    _cipher = AesGcmFileCipher(derivedKey);

    // Persist the derived key so the next launch can skip re-derivation
    await secureStorage.storeDerivedKey(derivedKey);

    // Open Isar with encryption
    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [NexItemSchema],
      directory: dir.path,
      name: 'nexpass_vault',
      encryptionCipher: _cipher,
    );

    debugPrint('[DatabaseService] Isar opened with AES-256-GCM encryption '
        'at ${dir.path}');
    return _instance!;
  }

  /// Returns the active Isar instance.
  static Isar get instance {
    if (_instance == null || !_instance!.isOpen) {
      throw StateError(
        'DatabaseService has not been initialized. '
        'Call DatabaseService.initialize(derivedKey: …) first.',
      );
    }
    return _instance!;
  }

  /// Closes the database and clears the in-memory cipher reference.
  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
      _cipher = null;
      debugPrint('[DatabaseService] Isar closed');
    }
  }

  /// Destructive wipe of all collections (vault reset / factory reset).
  static Future<void> clearAll() async {
    final db = instance;
    await db.writeTxn(() async {
      await db.clear();
    });
    debugPrint('[DatabaseService] All collections cleared');
  }
}
