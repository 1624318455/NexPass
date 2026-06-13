import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/nex_item.dart';

// ---------------------------------------------------------------------------
// AutofillEngine — cross-platform autofill coordination layer
// ---------------------------------------------------------------------------

/// Unified abstraction over Android AutofillService and iOS
/// CredentialProvider. Handles bidirectional MethodChannel communication
/// and manages the shared credential cache for autofill services.
///
/// ## Platform Integration
/// - **Android**: Pushes credentials to `CredentialCache` (EncryptedSharedPreferences)
///   so `NexPassAutofillService` can read them in its isolated process.
/// - **iOS**: Pushes decrypted passwords to `PasswordCache` (App Group container)
///   so the CredentialProvider extension can read them.
class AutofillEngine {
  static const MethodChannel _channel =
      MethodChannel('io.nexpass.app/autofill');

  /// Callback that provides the current vault items on demand.
  final List<NexItem> Function() _credentialProvider;

  /// Callback invoked when a credential fill is requested.
  final Future<void> Function(NexItem item)? _onFillRequested;

  AutofillEngine({
    required List<NexItem> Function() credentialProvider,
    Future<void> Function(NexItem item)? onFillRequested,
  })  : _credentialProvider = credentialProvider,
        _onFillRequested = onFillRequested {
    _channel.setMethodCallHandler(_handleMethodCall);
    debugPrint('[AutofillEngine] Initialized on ${Platform.operatingSystem}');
  }

  // ── Incoming method calls from native ────────────────────────────────

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      // ── Android: query matching credentials for a package ────────
      case 'queryMatchingCredentials':
        final args = call.arguments as Map?;
        final domain = args?['domain'] as String? ?? '';
        return _handleQueryCredentials(domain);

      // ── Android: inject credential into target fields ───────────
      case 'fillCredential':
        final args = call.arguments as Map?;
        final id = args?['id'] as String? ?? '';
        return _handleFillCredential(id);

      // ── Android: detect autofill fields in a structure ──────────
      case 'detectAutofillFields':
        return _handleDetectFields();

      // ── iOS: extension requesting credential list ───────────────
      case 'getCredentialIndex':
        return _handleGetCredentialIndex();

      // ── iOS: extension requesting full credential data ──────────
      case 'getCredentialDetail':
        final args = call.arguments as Map?;
        final uuid = args?['uuid'] as String? ?? '';
        return _handleGetCredentialDetail(uuid);

      default:
        throw PlatformException(
          code: 'UNSUPPORTED_METHOD',
          message: 'Method ${call.method} not implemented in AutofillEngine',
        );
    }
  }

  // ── Handler implementations ──────────────────────────────────────────

  /// Searches the vault for items matching [domain].
  List<Map<String, dynamic>> _handleQueryCredentials(String domain) {
    final items = _credentialProvider();
    final lowerDomain = domain.toLowerCase();

    return items
        .where((item) =>
            item.name.toLowerCase().contains(lowerDomain) ||
            item.username.toLowerCase().contains(lowerDomain) ||
            item.fields.any(
                (f) => f.value.toLowerCase().contains(lowerDomain)))
        .map((item) => _itemToMap(item))
        .toList();
  }

  /// Returns decrypted credential data for a specific item UUID.
  Map<String, dynamic>? _handleFillCredential(String credentialId) {
    final items = _credentialProvider();
    final match = items.where((i) => i.uuid == credentialId);

    if (match.isEmpty) return null;

    final item = match.first;

    // Trigger the callback if provided
    _onFillRequested?.call(item);

    return {
      'uuid': item.uuid,
      'name': item.name,
      'fields': item.fields
          .map((f) => {
                'name': f.name,
                'value': f.decryptedValue ?? f.value,
                'fieldType': f.fieldType,
                'isSensitive': f.isSensitive,
              })
          .toList(),
    };
  }

  /// Detects whether the current structure has fillable fields.
  Map<String, bool> _handleDetectFields() {
    return {'hasFields': true};
  }

  /// Returns the lightweight credential index for iOS extension.
  List<Map<String, dynamic>> _handleGetCredentialIndex() {
    final items = _credentialProvider();
    return items
        .where((item) => item.type == 1) // Logins only for autofill
        .map((item) => {
              'uuid': item.uuid,
              'name': item.name,
              'username': item.username,
              'itemType': item.type,
              'updatedAt': item.updatedAt.toIso8601String(),
            })
        .toList();
  }

  /// Returns full credential data for a specific UUID (used by iOS extension).
  Map<String, dynamic>? _handleGetCredentialDetail(String uuid) {
    final items = _credentialProvider();
    final match = items.where((i) => i.uuid == uuid);
    if (match.isEmpty) return null;
    return _itemToMap(match.first);
  }

  // ── Public API: outgoing calls to native ─────────────────────────────

  /// Notifies the native layer that a credential was selected for injection.
  Future<void> notifyCredentialSelected(String uuid) async {
    await _channel.invokeMethod('onCredentialSelected', {'uuid': uuid});
  }

  /// Opens the system autofill service settings page.
  static Future<bool> openSystemSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openAutofillSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Writes the vault index to the shared App Group container for iOS.
  ///
  /// Must be called whenever the vault is updated so the credential
  /// provider extension has fresh data.
  Future<void> syncVaultIndex() async {
    if (!Platform.isIOS) return;

    final items = _credentialProvider();
    final index = items
        .where((item) => item.type == 1)
        .map((item) => {
              'id': item.uuid,
              'name': item.name,
              'username': item.username,
              'matchDomains': <String>[],
              'itemType': item.type,
              'updatedAt': item.updatedAt.toIso8601String(),
            })
        .toList();

    try {
      await _channel.invokeMethod('syncVaultIndex', {'index': index});
      debugPrint('[AutofillEngine] iOS vault index synced (${index.length} entries)');
    } catch (e) {
      debugPrint('[AutofillEngine] Failed to sync iOS vault index: $e');
    }
  }

  // ── Credential cache management ─────────────────────────────────────

  /// Pushes the current vault credentials to the platform's autofill cache.
  ///
  /// Must be called after vault unlock, credential create/update/delete,
  /// and after vault decryption completes.
  ///
  /// - **Android**: Writes to `CredentialCache` (EncryptedSharedPreferences)
  ///   via MethodChannel so `NexPassAutofillService` can access them.
  /// - **iOS**: Writes decrypted passwords to `PasswordCache` (App Group container)
  ///   via the native AppDelegate MethodChannel.
  Future<void> cacheCredentials() async {
    final items = _credentialProvider();

    // Filter to login items with at least username or password
    final loginItems = items.where((item) =>
        item.type == 1 &&
        (item.username.isNotEmpty ||
            item.fields.any((f) => f.name == 'password' && f.value.isNotEmpty)));

    // Build credential maps for native side
    final credentialMaps = loginItems.map((item) {
      final passwordField = item.fields.firstWhere(
        (f) => f.name == 'password' || f.fieldType == 2,
        orElse: () => NexField()..value = '',
      );
      final websiteField = item.fields.firstWhere(
        (f) => f.name.toLowerCase() == 'website' || f.name.toLowerCase() == 'url',
        orElse: () => NexField()..value = '',
      );

      return {
        'uuid': item.uuid ?? '',
        'name': item.name,
        'username': item.username,
        'password': passwordField.decryptedValue ?? passwordField.value,
        'website': websiteField.value,
        'packageName': _extractDomain(websiteField.value),
      };
    }).toList();

    try {
      await _channel.invokeMethod('cacheCredentials', credentialMaps);
      debugPrint('[AutofillEngine] Cached ${credentialMaps.length} credentials '
          '(${Platform.operatingSystem})');
    } catch (e) {
      debugPrint('[AutofillEngine] Failed to cache credentials: $e');
    }
  }

  /// Clears all cached credentials from the platform's autofill cache.
  ///
  /// MUST be called when the vault is locked to ensure passwords
  /// are not persisted after the user locks the vault.
  Future<void> clearCredentialCache() async {
    try {
      await _channel.invokeMethod('clearCache');
      debugPrint('[AutofillEngine] Credential cache cleared');
    } catch (e) {
      debugPrint('[AutofillEngine] Failed to clear credential cache: $e');
    }
  }

  /// Extracts a domain-like string from a website URL for package matching.
  String _extractDomain(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  Map<String, dynamic> _itemToMap(NexItem item) {
    return {
      'uuid': item.uuid,
      'name': item.name,
      'username': item.username,
      'fields': item.fields
          .map((f) => {
                'name': f.name,
                'value': f.value,
                'fieldType': f.fieldType,
                'isSensitive': f.isSensitive,
              })
          .toList(),
    };
  }
}
