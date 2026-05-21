import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/nex_item.dart';

/// Manages the Isar database lifecycle.
///
/// NOTE: Isar 3.1.0 does not support file-level encryption via cipher.
/// All encryption is handled at the field level by VaultRepository (AES-256-GCM).
/// When Isar adds native encryption support, integrate it here.
class DatabaseService {
  static Isar? _instance;

  /// Initializes the Isar database with all collection schemas.
  static Future<Isar> initialize() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [NexItemSchema],
      directory: dir.path,
      name: 'nexpass_vault',
    );

    debugPrint('[DatabaseService] Isar initialized at ${dir.path}');
    return _instance!;
  }

  /// Returns the active Isar instance.
  static Isar get instance {
    if (_instance == null || !_instance!.isOpen) {
      throw StateError(
        'DatabaseService has not been initialized. '
        'Call DatabaseService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Closes the database.
  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
      debugPrint('[DatabaseService] Isar closed');
    }
  }

  /// Wipes all collections (factory reset).
  static Future<void> clearAll() async {
    final db = instance;
    await db.writeTxn(() async {
      await db.clear();
    });
    debugPrint('[DatabaseService] All collections cleared');
  }
}
