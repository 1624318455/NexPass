import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import '../models/nex_item.dart';
import '../state/vault_state_notifier.dart';

// ---------------------------------------------------------------------------
// AutofillChannelService — Dart-side MethodChannel handler
// ---------------------------------------------------------------------------

/// Handles incoming MethodChannel calls from native autofill services
/// (Android AutofillService, iOS CredentialProviderExtension).
///
/// This service acts as the bridge between native platform code and the
/// Dart vault layer. It receives credential queries from the native side,
/// resolves them against the local Isar vault, and returns results.
class AutofillChannelService {
  static const MethodChannel _channel =
      MethodChannel('io.nexpass.app/autofill');

  static const String _iosAppGroupID = 'group.io.nexpass.app';
  static const String _iosIndexFileName = 'vault_index.json';

  final VaultNotifier _vaultNotifier;

  AutofillChannelService({required VaultNotifier vaultNotifier})
      : _vaultNotifier = vaultNotifier {
    _channel.setMethodCallHandler(_handleNativeQuery);
    debugPrint('[AutofillChannelService] Handler registered');
  }

  // ── Incoming method calls from native ────────────────────────────────

  Future<dynamic> _handleNativeQuery(MethodCall call) async {
    switch (call.method) {
      // ── Android / iOS: search credentials for a domain ──────────
      case 'queryMatchingCredentials':
        return _handleQuery(call);

      // ── Android: inject credential into target fields ───────────
      case 'fillCredential':
        return _handleFill(call);

      // ── iOS: write vault index to App Group container ──────────
      case 'syncVaultIndex':
        return _handleSyncIndex(call);

      default:
        throw PlatformException(
          code: 'UNSUPPORTED_METHOD',
          message:
              'Method ${call.method} not implemented in AutofillChannelService',
        );
    }
  }

  // ── Handler implementations ──────────────────────────────────────────

  /// Searches the local vault for items matching a domain string.
  Future<List<Map<String, dynamic>>> _handleQuery(MethodCall call) async {
    final args = call.arguments as Map?;
    final domain = args?['domain'] as String? ?? '';
    final lowerDomain = domain.toLowerCase();

    debugPrint('[AutofillChannelService] Query: "$domain"');

    final items = _vaultNotifier.state.items.where((item) {
      return item.name.toLowerCase().contains(lowerDomain) ||
          item.username.toLowerCase().contains(lowerDomain) ||
          item.fields
              .any((f) => f.value.toLowerCase().contains(lowerDomain));
    }).toList();

    return items
        .map((item) => {
              'uuid': item.uuid,
              'name': item.name,
              'username': item.username,
              'fields': item.fields
                  .map((f) => {
                        'name': f.name,
                        'value': f.decryptedValue ?? f.value,
                        'fieldType': f.fieldType,
                        'isSensitive': f.isSensitive,
                      })
                  .toList(),
            })
        .toList();
  }

  /// Returns decrypted field data for a specific credential UUID.
  Future<Map<String, dynamic>> _handleFill(MethodCall call) async {
    final args = call.arguments as Map?;
    final credentialId = args?['id'] as String? ?? '';

    debugPrint('[AutofillChannelService] Fill request: $credentialId');

    final items = _vaultNotifier.state.items;
    final match = items.where((i) => i.uuid == credentialId);

    if (match.isEmpty) {
      return {'success': false, 'error': 'Credential not found'};
    }

    final item = match.first;
    return {
      'success': true,
      'uuid': item.uuid,
      'name': item.name,
      'fields': item.fields
          .map((f) => {
                'name': f.name,
                'value': f.decryptedValue ?? f.value,
                'fieldType': f.fieldType,
              })
          .toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Writes the vault credential index to the iOS App Group shared container.
  ///
  /// The iOS CredentialProviderExtension reads this file to present
  /// matching credentials to Safari / system autofill.
  Future<void> _handleSyncIndex(MethodCall call) async {
    if (!Platform.isIOS) return;

    final args = call.arguments as Map?;
    final rawIndex = args?['index'] as List<dynamic>?;

    if (rawIndex == null || rawIndex.isEmpty) return;

    try {
      final containerURL = await _getAppGroupContainer();
      if (containerURL == null) {
        debugPrint('[AutofillChannelService] iOS App Group container unavailable');
        return;
      }

      final fileURL = containerURL.uri.resolve(_iosIndexFileName);
      final jsonStr = jsonEncode(rawIndex);
      await File(fileURL.toFilePath()).writeAsString(jsonStr);

      debugPrint('[AutofillChannelService] iOS vault index written '
          '(${rawIndex.length} entries)');
    } catch (e) {
      debugPrint('[AutofillChannelService] Failed to write iOS index: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Resolves the App Group container URL on iOS.
  Future<Directory?> _getAppGroupContainer() async {
    try {
      // On iOS, path_provider can resolve App Group containers
      // via a platform channel or the shared_preferences_app_group package.
      // For this stub, we use a direct file manager approach.
      final appDir = await getApplicationDocumentsDirectory();
      // Navigate to the App Group container path
      final groupPath = appDir.parent.path
          .replaceFirst(appDir.path.split('/').last, _iosAppGroupID);
      final groupDir = Directory(groupPath);
      if (await groupDir.exists()) {
        return groupDir;
      }
    } catch (_) {}
    return null;
  }
}
