import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:nexpass/models/password_history.dart';
import 'package:nexpass/services/crypto_utils.dart';
import 'package:nexpass/services/password_history_service.dart';

/// P1-6c: 14-day encrypted password history.
///
/// Uses a real Isar instance in a temp dir + real AES-256-GCM envelopes so
/// the retention/dedup/cap paths under test match production behavior.
void main() {
  late Directory tmp;
  late Isar isar;
  late PasswordHistoryService service;
  late Uint8List key;

  // Isar 3 ships its native core via isar_flutter_libs (app runtime only);
  // unit tests must download the host binary once before opening Isar.
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nexpass_history_test');
    isar = await Isar.open([PasswordHistoryEntrySchema], directory: tmp.path);
    service = PasswordHistoryService(isar: isar, crypto: CryptoService());
    key = Uint8List.fromList(List.generate(32, (i) => i));
  });

  tearDown(() async {
    await isar.close();
    await tmp.delete(recursive: true);
  });

  group('retention policy', () {
    test('retention is 14 days', () {
      expect(PasswordHistoryService.retention, const Duration(days: 14));
    });

    test('entries older than 14 days are pruned on list', () async {
      await service.record(
        password: 'OldP@ssw0rd!',
        derivedKey: key,
        itemUuid: 'item-1',
        label: 'Old',
        source: 'created',
      );
      // Backdate past the retention window.
      final stored = await isar.passwordHistoryEntrys.where().findFirst();
      await isar.writeTxn(() async {
        stored!.createdAt = DateTime.now().subtract(const Duration(days: 15));
        await isar.passwordHistoryEntrys.put(stored);
      });

      final entries = await service.list(derivedKey: key);
      expect(entries, isEmpty);
      expect(await isar.passwordHistoryEntrys.where().count(), 0);
    });

    test('recent entries survive pruning', () async {
      await service.record(
        password: 'FreshP@ssw0rd!',
        derivedKey: key,
        itemUuid: 'item-1',
        label: 'Fresh',
        source: 'rotated',
      );
      final entries = await service.list(derivedKey: key);
      expect(entries, hasLength(1));
      expect(entries.first.decryptedValue, 'FreshP@ssw0rd!');
    });
  });

  group('write behavior', () {
    test('identical value for same item is deduped', () async {
      await service.record(
        password: 'SameP@ss1!',
        derivedKey: key,
        itemUuid: 'item-2',
        label: 'Dup',
        source: 'created',
      );
      await service.record(
        password: 'SameP@ss1!',
        derivedKey: key,
        itemUuid: 'item-2',
        label: 'Dup',
        source: 'generated',
      );
      expect(await isar.passwordHistoryEntrys.where().count(), 1);
    });

    test('changed value for same item creates a new entry', () async {
      await service.record(
        password: 'FirstP@ss1!',
        derivedKey: key,
        itemUuid: 'item-3',
        label: 'Chg',
        source: 'created',
      );
      await service.record(
        password: 'SecondP@ss2!',
        derivedKey: key,
        itemUuid: 'item-3',
        label: 'Chg',
        source: 'rotated',
      );
      final entries = await service.list(derivedKey: key, itemUuid: 'item-3');
      expect(entries, hasLength(2));
      // Newest first.
      expect(entries.first.decryptedValue, 'SecondP@ss2!');
    });

    test('empty passwords are never recorded', () async {
      await service.record(
        password: '',
        derivedKey: key,
        itemUuid: 'item-4',
        label: 'Empty',
        source: 'created',
      );
      expect(await isar.passwordHistoryEntrys.where().count(), 0);
    });

    test('plaintext never touches disk (stored value is an envelope)', () async {
      const secret = 'SuperSecret123!@#';
      await service.record(
        password: secret,
        derivedKey: key,
        itemUuid: 'item-5',
        label: 'Env',
        source: 'created',
      );
      final raw = await isar.passwordHistoryEntrys.where().findFirst();
      expect(raw!.encryptedValue, isNotEmpty);
      expect(raw.encryptedValue.contains(secret), isFalse);
    });

    test('entry count is capped at maxEntries', () async {
      // Seed raw entries directly (fast), then one service write triggers cap.
      await isar.writeTxn(() async {
        for (var i = 0; i < PasswordHistoryService.maxEntries + 5; i++) {
          await isar.passwordHistoryEntrys.put(PasswordHistoryEntry()
            ..itemUuid = 'bulk-$i'
            ..label = 'bulk'
            ..source = 'generated'
            ..encryptedValue = 'x'
            ..createdAt = DateTime.now());
        }
      });
      await service.record(
        password: 'CapTrigger1!',
        derivedKey: key,
        itemUuid: 'cap',
        label: 'Cap',
        source: 'generated',
      );
      expect(await isar.passwordHistoryEntrys.where().count(),
          PasswordHistoryService.maxEntries);
    });
  });
}
