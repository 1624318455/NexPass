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

  /// Fetches one item by uuid with fields decrypted (null when absent).
  /// Used by history change-detection before overwrite.
  Future<NexItem?> getItemByUuid({
    required String uuid,
    required Uint8List derivedKey,
  }) async {
    final item =
        await _isar.nexItems.filter().uuidEqualTo(uuid).findFirst();
    if (item == null) return null;
    await _decryptFields(item, derivedKey);
    return item;
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

  // ── P1-10 batch (metadata-only, no re-encryption) ────────────────────
  // All three ops touch only isFavorite/type/updatedAt and reuse a single
  // write txn each, so sensitive fields are never passed through
  // encrypt-then-write (avoids double-encryption of at-rest ciphertext).

  /// Deletes all [items] by id in one transaction. Empty list is a no-op.
  Future<void> deleteItems({required List<NexItem> items}) async {
    if (items.isEmpty) return;
    final ids = items.map((e) => e.id).toList();
    await _isar.writeTxn(() async {
      for (final id in ids) {
        await _isar.nexItems.delete(id);
      }
    });
  }

  /// Sets [favorite] on all [items] in one transaction. Empty list no-op.
  Future<void> setFavoriteAll({
    required List<NexItem> items,
    required bool favorite,
  }) async {
    if (items.isEmpty) return;
    final now = DateTime.now();
    await _isar.writeTxn(() async {
      for (final item in items) {
        item.isFavorite = favorite;
        item.updatedAt = now;
        await _isar.nexItems.put(item);
      }
    });
  }

  /// Moves all [items] to [type] (1..5) in one transaction. Empty list no-op.
  Future<void> moveItemsToType({
    required List<NexItem> items,
    required int type,
  }) async {
    if (items.isEmpty) return;
    final now = DateTime.now();
    await _isar.writeTxn(() async {
      for (final item in items) {
        item.type = type;
        item.updatedAt = now;
        await _isar.nexItems.put(item);
      }
    });
  }

  /// Moves all [items] to folder [folderId] (null/empty = no folder).
  /// Metadata-only, single transaction. Empty list no-op.
  Future<void> moveItemsToFolder({
    required List<NexItem> items,
    required String? folderId,
  }) async {
    if (items.isEmpty) return;
    final now = DateTime.now();
    final normalized =
        (folderId == null || folderId.trim().isEmpty) ? null : folderId.trim();
    await _isar.writeTxn(() async {
      for (final item in items) {
        item.folderId = normalized;
        item.updatedAt = now;
        await _isar.nexItems.put(item);
      }
    });
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
