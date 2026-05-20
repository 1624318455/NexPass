import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:isar/isar.dart';
import '../models/nex_item.dart';
import '../services/crypto_utils.dart';

/// Repository executing high-performance queries with batched
/// encryption/decryption. All crypto work is offloaded to a background
/// [Isolate] to guarantee zero UI jank on low-end devices.
class VaultRepository {
  final Isar _isar;
  final CryptoService _cryptoService;

  VaultRepository({
    required Isar isar,
    required CryptoService cryptoService,
  })  : _isar = isar,
        _cryptoService = cryptoService;

  // ── Save (encrypt-then-write) ──────────────────────────────────────

  /// Encrypts all sensitive fields in [item], then persists to Isar.
  /// The encrypt batch runs in a single background Isolate.
  Future<void> saveItem({
    required NexItem item,
    required Uint8List derivedKey,
  }) async {
    // Collect fields that need encryption
    final plainTexts = <String>[];
    final indices = <int>[];

    for (var i = 0; i < item.fields.length; i++) {
      final field = item.fields[i];
      if (field.value.isNotEmpty && field.isSensitive) {
        plainTexts.add(field.value);
        indices.add(i);
      }
    }

    // Batch-encrypt all sensitive fields in one Isolate
    if (plainTexts.isNotEmpty) {
      final encryptedBatch = await Isolate.run(() async {
        final crypto = CryptoService();
        final results = <int, String>{};
        for (var j = 0; j < plainTexts.length; j++) {
          final encrypted = await crypto.encrypt(
            plaintext: plainTexts[j],
            secretKey: derivedKey,
          );
          results[indices[j]] = base64Encode(encrypted);
        }
        return results;
      });

      for (final entry in encryptedBatch.entries) {
        item.fields[entry.key].value = entry.value;
      }
    }

    item.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.nexItems.put(item);
    });
  }

  // ── Read (read-then-decrypt) ───────────────────────────────────────

  /// Searches items by name and batch-decrypts sensitive fields.
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

    await _batchDecrypt(rawResults, derivedKey);
    return rawResults;
  }

  /// Returns all items with sensitive fields decrypted.
  Future<List<NexItem>> getAllItems({required Uint8List derivedKey}) async {
    final allItems = await _isar.nexItems.where().findAll();
    await _batchDecrypt(allItems, derivedKey);
    return allItems;
  }

  /// Returns items where the decrypted password is shorter than
  /// [minimumSecureLength].
  Future<List<NexItem>> getWeakPasswordItems({
    required Uint8List derivedKey,
    int minimumSecureLength = 10,
  }) async {
    final allItems = await _isar.nexItems.where().findAll();
    await _batchDecrypt(allItems, derivedKey);

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

  // ── Batch decrypt (single Isolate) ─────────────────────────────────

  /// Decrypts all sensitive fields across [items] in one background Isolate,
  /// avoiding per-field Isolate spawn overhead.
  Future<void> _batchDecrypt(List<NexItem> items, Uint8List derivedKey) async {
    // Collect all encrypted fields across all items
    final encryptedBlobs = <_FieldRef>[];
    for (var itemIdx = 0; itemIdx < items.length; itemIdx++) {
      for (var fieldIdx = 0; fieldIdx < items[itemIdx].fields.length; fieldIdx++) {
        final field = items[itemIdx].fields[fieldIdx];
        if (field.isSensitive && field.value.isNotEmpty) {
          encryptedBlobs.add(_FieldRef(itemIdx, fieldIdx, field.value));
        }
      }
    }

    if (encryptedBlobs.isEmpty) return;

    // Decrypt all in one Isolate
    final decrypted = await Isolate.run(() async {
      final crypto = CryptoService();
      final results = <int, String>{};
      for (var i = 0; i < encryptedBlobs.length; i++) {
        try {
          final encryptedBytes = base64Decode(encryptedBlobs[i].value);
          final plain = await crypto.decrypt(
            encryptedData: encryptedBytes,
            secretKey: derivedKey,
          );
          results[i] = plain;
        } catch (_) {
          results[i] = '[DECRYPTION_FAILED]';
        }
      }
      return results;
    });

    // Apply decrypted values back
    for (var i = 0; i < encryptedBlobs.length; i++) {
      final ref = encryptedBlobs[i];
      items[ref.itemIdx].fields[ref.fieldIdx].decryptedValue = decrypted[i];
    }
  }
}

/// Internal reference to a specific field inside a specific item.
class _FieldRef {
  final int itemIdx;
  final int fieldIdx;
  final String value;
  const _FieldRef(this.itemIdx, this.fieldIdx, this.value);
}
