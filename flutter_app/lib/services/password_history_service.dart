import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/password_history.dart';
import 'crypto_utils.dart';

/// 14-day password history (Proton/Dashlane parity).
///
/// Every recorded value is AES-256-GCM encrypted with the vault derived key
/// before touching Isar — same envelope as [NexField] sensitive values:
/// `base64(nonce12 + ciphertext + mac16)`. Plaintext never touches disk.
///
/// Write paths (wired in [VaultNotifier] + audit fix):
/// - 'created' — new credential saved
/// - 'rotated' — existing password changed (manual edit or audit fix)
/// - 'generated' — generator output captured even if never saved
///
/// [record] dedups against the latest entry for the same item so a
/// generate-then-save sequence leaves a single entry.
class PasswordHistoryService {
  /// Entries older than this are pruned.
  static const Duration retention = Duration(days: 14);

  /// Hard cap bounding Isar + decrypt cost.
  static const int maxEntries = 200;

  final Isar _isar;
  final CryptoService _crypto;

  PasswordHistoryService({required Isar isar, required CryptoService crypto})
      : _isar = isar,
        _crypto = crypto;

  // ── Write ───────────────────────────────────────────────────────────

  Future<void> record({
    required String password,
    required Uint8List derivedKey,
    String? itemUuid,
    required String label,
    required String source,
  }) async {
    if (password.isEmpty) return;
    try {
      // Dedup: skip when identical to the latest entry for this item.
      final latest = await _latestFor(itemUuid);
      if (latest != null) {
        try {
          final prev = await _crypto.decrypt(
            encryptedData: base64Decode(latest.encryptedValue),
            secretKey: derivedKey,
          );
          if (prev == password) return;
        } catch (_) {
          // Unreadable latest — fall through and record fresh.
        }
      }

      final encrypted = await _crypto.encrypt(
        plaintext: password,
        secretKey: derivedKey,
      );
      final entry = PasswordHistoryEntry()
        ..itemUuid = itemUuid
        ..label = label
        ..source = source
        ..encryptedValue = base64Encode(encrypted)
        ..createdAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.passwordHistoryEntrys.put(entry);
      });

      await pruneExpired();
      await _enforceCap();
    } catch (e) {
      // History must never break vault writes.
      debugPrint('[PasswordHistory] record failed: $e');
    }
  }

  // ── Read ────────────────────────────────────────────────────────────

  /// Newest-first decrypted entries, optionally scoped to one vault item.
  /// Expired entries are pruned first so callers never see stale data.
  Future<List<PasswordHistoryEntry>> list({
    required Uint8List derivedKey,
    String? itemUuid,
  }) async {
    await pruneExpired();
    final query = itemUuid == null
        ? _isar.passwordHistoryEntrys.where().sortByCreatedAtDesc()
        : _isar.passwordHistoryEntrys
            .filter()
            .itemUuidEqualTo(itemUuid)
            .sortByCreatedAtDesc();
    final entries = await query.findAll();

    final visible = <PasswordHistoryEntry>[];
    for (final e in entries) {
      try {
        e.decryptedValue = await _crypto.decrypt(
          encryptedData: base64Decode(e.encryptedValue),
          secretKey: derivedKey,
        );
        visible.add(e);
      } catch (_) {
        // Wrong key post-rotation or corrupt envelope — hide, don't crash.
      }
    }
    return visible;
  }

  // ── Maintenance ─────────────────────────────────────────────────────

  /// Deletes entries older than [retention]. Returns the removed count.
  Future<int> pruneExpired() async {
    final cutoff = DateTime.now().subtract(retention);
    final stale =
        await _isar.passwordHistoryEntrys.filter().createdAtLessThan(cutoff).findAll();
    if (stale.isEmpty) return 0;
    await _isar.writeTxn(() async {
      for (final e in stale) {
        await _isar.passwordHistoryEntrys.delete(e.id);
      }
    });
    return stale.length;
  }

  Future<void> deleteEntry(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.passwordHistoryEntrys.delete(id);
    });
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.passwordHistoryEntrys.clear();
    });
  }

  // ── Private ─────────────────────────────────────────────────────────

  Future<PasswordHistoryEntry?> _latestFor(String? itemUuid) async {
    if (itemUuid == null) {
      return _isar.passwordHistoryEntrys.where().sortByCreatedAtDesc().findFirst();
    }
    return _isar.passwordHistoryEntrys
        .filter()
        .itemUuidEqualTo(itemUuid)
        .sortByCreatedAtDesc()
        .findFirst();
  }

  Future<void> _enforceCap() async {
    final count = await _isar.passwordHistoryEntrys.where().count();
    if (count <= maxEntries) return;
    final overflow = await _isar.passwordHistoryEntrys
        .where()
        .sortByCreatedAt()
        .limit(count - maxEntries)
        .findAll();
    await _isar.writeTxn(() async {
      for (final e in overflow) {
        await _isar.passwordHistoryEntrys.delete(e.id);
      }
    });
  }
}

final passwordHistoryProvider = Provider<PasswordHistoryService>((ref) {
  throw UnimplementedError('Override passwordHistoryProvider at app startup');
});
