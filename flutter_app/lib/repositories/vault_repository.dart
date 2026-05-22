import 'dart:convert';
import 'dart:typed_data';
import 'package:isar/isar.dart';
import '../models/nex_item.dart';
import '../services/crypto_utils.dart';

/// Repository executing high-performance queries with batched
/// encryption/decryption. All crypto work is offloaded to background
/// Isolates via CryptoService to guarantee zero UI jank.
class VaultRepository {
  final Isar _isar;
  final CryptoService _cryptoService;

  VaultRepository({
    required Isar isar,
    required CryptoService cryptoService,
  })  : _isar = isar,
        _cryptoService = cryptoService;

  // ── Save (encrypt-then-write) ──────────────────────────────────────

  Future<void> saveItem({
    required NexItem item,
    required Uint8List derivedKey,
  }) async {
    for (var field in item.fields) {
      if (field.value.isNotEmpty && field.isSensitive) {
        final encryptedBytes = await _cryptoService.encrypt(
          plaintext: field.value,
          secretKey: derivedKey,
        );
        field.value = base64Encode(encryptedBytes);
      }
    }

    item.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.nexItems.put(item);
    });
  }

  // ── Read (read-then-decrypt) ───────────────────────────────────────

  Future<List<NexItem>> searchItems({
    required String query,
    required Uint8List derivedKey,
  }) async {
    final lowercaseQuery = query.toLowerCase();

    final rawResults = await _isar.nexItems
        .filter()
        .nameContains(lowercaseQuery, caseSensitive: false)
        .sortByUpdatedAtDesc()
        .findAll();

    for (var item in rawResults) {
      await _decryptFields(item, derivedKey);
    }
    return rawResults;
  }

  Future<List<NexItem>> getAllItems({required Uint8List derivedKey}) async {
    final allItems = await _isar.nexItems.where().findAll();
    for (var item in allItems) {
      await _decryptFields(item, derivedKey);
    }
    return allItems;
  }

  Future<List<NexItem>> getWeakPasswordItems({
    required Uint8List derivedKey,
    int minimumSecureLength = 10,
  }) async {
    final allItems = await _isar.nexItems.where().findAll();
    for (var item in allItems) {
      await _decryptFields(item, derivedKey);
    }

    final weakItems = <NexItem>[];
    for (var item in allItems) {
      final passwordField = item.fields.firstWhere(
        (f) => f.name == 'password' || f.fieldType == 2,
        orElse: () => NexField()..decryptedValue = '',
      );
      final val = passwordField.decryptedValue ?? '';
      if (val.isNotEmpty && val.length < minimumSecureLength) {
        weakItems.add(item);
      }
    }
    return weakItems;
  }

  Future<void> deleteItem({required NexItem item}) async {
    await _isar.writeTxn(() async {
      await _isar.nexItems.delete(item.id);
    });
  }

  Future<void> toggleFavorite({required NexItem item}) async {
    item.isFavorite = !item.isFavorite;
    await _isar.writeTxn(() async => _isar.nexItems.put(item));
  }

  Future<void> markUsed({required NexItem item}) async {
    item.lastUsedAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.nexItems.put(item));
  }

  /// Re-encrypt all vault items from [oldKey] to [newKey].
  /// Returns the number of items re-encrypted.
  Future<int> reEncryptAllItems({
    required Uint8List oldKey,
    required Uint8List newKey,
  }) async {
    final allItems = await _isar.nexItems.where().findAll();
    int count = 0;

    for (final item in allItems) {
      // Decrypt sensitive fields with old key
      for (final field in item.fields) {
        if (field.isSensitive && field.value.isNotEmpty) {
          try {
            final encryptedBytes = base64Decode(field.value);
            final decrypted = await _cryptoService.decrypt(
              encryptedData: encryptedBytes,
              secretKey: oldKey,
            );
            // Re-encrypt with new key
            final reEncrypted = await _cryptoService.encrypt(
              plaintext: decrypted,
              secretKey: newKey,
            );
            field.value = base64Encode(reEncrypted);
          } catch (_) {
            // Field already corrupted or uses different key — skip
          }
        }
      }
      item.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.nexItems.put(item);
      });
      count++;
    }
    return count;
  }

  // ── Decrypt fields (each call runs in its own Isolate via CryptoService) ──

  Future<void> _decryptFields(NexItem item, Uint8List derivedKey) async {
    for (var field in item.fields) {
      if (field.isSensitive && field.value.isNotEmpty) {
        try {
          final encryptedBytes = base64Decode(field.value);
          final decrypted = await _cryptoService.decrypt(
            encryptedData: encryptedBytes,
            secretKey: derivedKey,
          );
          field.decryptedValue = decrypted;
        } catch (_) {
          field.decryptedValue = '[DECRYPTION_FAILED]';
        }
      } else {
        field.decryptedValue = field.value;
      }
    }
  }
}
