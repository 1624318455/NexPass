import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import '../models/nex_item.dart';

// ---------------------------------------------------------------------------
// Sync progress events
// ---------------------------------------------------------------------------

enum SyncPhase {
  handshake,
  comparing,
  downloading,
  uploading,
  success,
  error,
}

class SyncProgressEvent {
  final SyncPhase phase;
  final String message;

  const SyncProgressEvent(this.phase, this.message);
}

typedef SyncProgressCallback = void Function(SyncProgressEvent event);

// ---------------------------------------------------------------------------
// SyncService — WebDAV atomic sync engine
// ---------------------------------------------------------------------------

/// Manages bidirectional vault synchronization over WebDAV.
///
/// ## Atomic write protocol
/// ```
/// 1.  PROPFIND  /nexpass_vault.json          → check existence
/// 2a. (missing) → PUT full vault to .json     → first-time upload
/// 2b. (exists)  → GET remote → merge by uuid  → compare updatedAt
/// 3.  PUT       /nexpass_vault.tmp            → write staging file
/// 4.  MOVE      /nexpass_vault.tmp → .json    → atomic swap
/// ```
///
/// Every network call is guarded by status-code validation and an optional
/// retry loop, so a single transient failure does not corrupt the remote.
class SyncService {
  final String webDavUrl;
  final String username;
  final String password;
  final http.Client _client;

  /// Maximum number of retries per HTTP operation.
  final int maxRetries;

  /// Delay between retries.
  final Duration retryDelay;

  SyncService({
    required this.webDavUrl,
    required this.username,
    required this.password,
    http.Client? client,
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 2),
  }) : _client = client ?? http.Client();

  // ── Auth header ─────────────────────────────────────────────────────

  Map<String, String> get _authHeader {
    final credentials = '$username:$password';
    final encoded = base64Encode(utf8.encode(credentials));
    return {
      'Authorization': 'Basic $encoded',
    };
  }

  Map<String, String> get _jsonHeaders => {
        ..._authHeader,
        'Content-Type': 'application/json; charset=utf-8',
      };

  // ── Public: full sync ───────────────────────────────────────────────

  /// Performs a full bidirectional sync between [localItems] and WebDAV.
  ///
  /// - Items newer on remote are downloaded via [onDownloadItem].
  /// - Items newer locally (or only locally) are uploaded atomically.
  Future<void> syncVault({
    required List<NexItem> localItems,
    required Future<void> Function(NexItem item) onDownloadItem,
    SyncProgressCallback? onProgress,
  }) async {
    final emit = onProgress ?? (_) {};

    // ── Phase 1: Handshake (PROPFIND) ──────────────────────────────
    emit(const SyncProgressEvent(
      SyncPhase.handshake,
      'PROPFIND nexpass_vault.json — checking remote existence',
    ));

    final headResp = await _retry(
      () => _client.send(
        http.Request('HEAD', Uri.parse('$webDavUrl/nexpass_vault.json'))
          ..headers.addAll(_authHeader),
      ),
    );

    // ── Phase 2a: Remote not found → fresh upload ──────────────────
    if (headResp.statusCode == 404) {
      emit(const SyncProgressEvent(
        SyncPhase.uploading,
        'Remote vault not found — uploading full local vault',
      ));
      await _atomicUpload(localItems, emit);
      emit(const SyncProgressEvent(
        SyncPhase.success,
        'Initial upload complete (${localItems.length} items)',
      ));
      return;
    }

    if (headResp.statusCode != 200 && headResp.statusCode != 207) {
      throw SyncException(
        'Unexpected PROPFIND status ${headResp.statusCode}',
        statusCode: headResp.statusCode,
      );
    }

    // ── Phase 2b: Remote exists → download & merge ─────────────────
    emit(const SyncProgressEvent(
      SyncPhase.comparing,
      'Remote vault found — fetching manifest for comparison',
    ));

    final getResp = await _retry(
      () => _client.get(
        Uri.parse('$webDavUrl/nexpass_vault.json'),
        headers: _authHeader,
      ),
    );

    if (getResp.statusCode != 200) {
      throw SyncException(
        'Failed to download remote vault: HTTP ${getResp.statusCode}',
        statusCode: getResp.statusCode,
      );
    }

    final List<dynamic> remoteData;
    try {
      // Parse JSON in a background Isolate to avoid blocking the UI thread
      // on large vault payloads.
      remoteData = await Isolate.run(() {
        return jsonDecode(getResp.body) as List<dynamic>;
      });
    } catch (_) {
      throw const SyncException('Remote vault JSON is corrupted');
    }

    emit(SyncProgressEvent(
      SyncPhase.comparing,
      'Fetched ${remoteData.length} remote items — comparing timestamps',
    ));

    // ── Download: remote items newer than local ────────────────────
    int dlCount = 0;
    for (final remoteJson in remoteData) {
      final String remoteUuid = remoteJson['uuid'] as String;
      final DateTime remoteUpdated =
          DateTime.parse(remoteJson['updatedAt'] as String);

      final localMatch = localItems.cast<NexItem?>().firstWhere(
            (item) => item?.uuid == remoteUuid,
            orElse: () => null,
          );

      if (localMatch == null) {
        // Brand-new remote item
        emit(SyncProgressEvent(
          SyncPhase.downloading,
          'New remote item: $remoteUuid',
        ));
        await onDownloadItem(_fromJson(remoteJson as Map<String, dynamic>));
        dlCount++;
      } else if (remoteUpdated.isAfter(localMatch.updatedAt)) {
        // Remote is newer
        emit(SyncProgressEvent(
          SyncPhase.downloading,
          'Updated remote item: ${localMatch.name}',
        ));
        final updated =
            _fromJson(remoteJson as Map<String, dynamic>)..id = localMatch.id;
        await onDownloadItem(updated);
        dlCount++;
      }
    }

    // ── Upload: local items newer (or not present) on remote ───────
    final List<NexItem> itemsToUpload = [];
    for (final local in localItems) {
      final remoteJson = remoteData.cast<Map<String, dynamic>?>().firstWhere(
            (r) => r?['uuid'] == local.uuid,
            orElse: () => null,
          );

      if (remoteJson == null) {
        itemsToUpload.add(local);
      } else {
        final remoteUpdated =
            DateTime.parse(remoteJson['updatedAt'] as String);
        if (local.updatedAt.isAfter(remoteUpdated)) {
          itemsToUpload.add(local);
        }
      }
    }

    if (itemsToUpload.isNotEmpty) {
      emit(SyncProgressEvent(
        SyncPhase.uploading,
        'Uploading ${itemsToUpload.length} local changes',
      ));
      await _atomicUpload(localItems, emit);
    }

    emit(SyncProgressEvent(
      SyncPhase.success,
      'Sync complete — $dlCount downloaded, ${itemsToUpload.length} uploaded',
    ));
  }

  // ── Atomic upload: PUT .tmp → MOVE .json ──────────────────────────

  /// Writes the full vault through a staging file for crash safety.
  ///
  /// 1. `PUT /nexpass_vault.tmp` — write serialized vault
  /// 2. `MOVE /nexpass_vault.tmp → /nexpass_vault.json` — atomic swap
  ///
  /// If the MOVE fails, the .tmp is cleaned up so no stale staging
  /// file is left behind.
  Future<void> _atomicUpload(
    List<NexItem> items,
    SyncProgressCallback emit,
  ) async {
    // Serialize vault JSON in a background Isolate to keep UI responsive.
    final jsonMaps = items.map(_toJson).toList();
    final payload = await Isolate.run(() {
      return jsonEncode(jsonMaps);
    });

    // ── Step 1: PUT to .tmp staging file ───────────────────────────
    emit(const SyncProgressEvent(
      SyncPhase.uploading,
      'Writing to staging file (nexpass_vault.tmp)',
    ));

    final putResp = await _retry(
      () => _client.put(
        Uri.parse('$webDavUrl/nexpass_vault.tmp'),
        headers: _jsonHeaders,
        body: payload,
      ),
    );

    if (putResp.statusCode != 200 &&
        putResp.statusCode != 201 &&
        putResp.statusCode != 204) {
      throw SyncException(
        'PUT to staging file failed: HTTP ${putResp.statusCode}',
        statusCode: putResp.statusCode,
      );
    }

    // ── Step 2: MOVE .tmp → .json (atomic swap) ───────────────────
    emit(const SyncProgressEvent(
      SyncPhase.uploading,
      'Atomic MOVE → nexpass_vault.json',
    ));

    final moveReq = http.Request(
      'MOVE',
      Uri.parse('$webDavUrl/nexpass_vault.tmp'),
    )
      ..headers.addAll(_authHeader)
      ..headers['Destination'] = '$webDavUrl/nexpass_vault.json'
      ..headers['Overwrite'] = 'T';

    final moveResp = await _retry(() => _client.send(moveReq));

    if (moveResp.statusCode != 200 &&
        moveResp.statusCode != 201 &&
        moveResp.statusCode != 204) {
      // Attempt cleanup of staging file
      await _cleanupStaging();
      throw SyncException(
        'Atomic MOVE failed: HTTP ${moveResp.statusCode}',
        statusCode: moveResp.statusCode,
      );
    }

    emit(const SyncProgressEvent(
      SyncPhase.uploading,
      'Atomic swap successful — remote vault updated',
    ));
  }

  /// Deletes the .tmp staging file if it was left behind after a failed MOVE.
  Future<void> _cleanupStaging() async {
    try {
      await _client.delete(
        Uri.parse('$webDavUrl/nexpass_vault.tmp'),
        headers: _authHeader,
      );
    } catch (_) {
      // Best-effort; ignore cleanup failures
    }
  }

  // ── Retry helper ──────────────────────────────────────────────────

  /// Retries [action] up to [maxRetries] times on transient errors
  /// (network failures, 5xx server errors).
  Future<T> _retry<T>(Future<T> Function() action) async {
    int attempt = 0;
    while (true) {
      try {
        final result = await action();
        // Retry on 5xx server errors
        if (result is http.Response &&
            result.statusCode >= 500 &&
            result.statusCode < 600 &&
            attempt < maxRetries) {
          attempt++;
          await Future.delayed(retryDelay * attempt);
          continue;
        }
        return result;
      } on SocketException {
        if (attempt >= maxRetries) rethrow;
        attempt++;
        await Future.delayed(retryDelay * attempt);
      } on HttpException {
        if (attempt >= maxRetries) rethrow;
        attempt++;
        await Future.delayed(retryDelay * attempt);
      } on TimeoutException {
        if (attempt >= maxRetries) rethrow;
        attempt++;
        await Future.delayed(retryDelay * attempt);
      }
    }
  }

  // ── JSON serialization ────────────────────────────────────────────

  NexItem _fromJson(Map<String, dynamic> json) {
    return NexItem()
      ..uuid = json['uuid'] as String?
      ..vaultId = json['vaultId'] as String?
      ..type = (json['type'] as num?)?.toInt() ?? 1
      ..name = json['name'] as String? ?? ''
      ..iconKey = json['iconKey'] as String?
      ..isFavorite = json['isFavorite'] as bool? ?? false
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..fields = (json['fields'] as List<dynamic>?)
              ?.map((f) => NexField()
                ..name = f['name'] as String? ?? ''
                ..value = f['value'] as String? ?? ''
                ..fieldType = (f['fieldType'] as num?)?.toInt() ?? 1
                ..isSensitive = f['isSensitive'] as bool? ?? false)
              .toList() ??
          [];
  }

  Map<String, dynamic> _toJson(NexItem item) {
    return {
      'uuid': item.uuid,
      'vaultId': item.vaultId,
      'type': item.type,
      'name': item.name,
      'iconKey': item.iconKey,
      'isFavorite': item.isFavorite,
      'updatedAt': item.updatedAt.toIso8601String(),
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

// ---------------------------------------------------------------------------
// SyncException
// ---------------------------------------------------------------------------

class SyncException implements Exception {
  final String message;
  final int? statusCode;

  const SyncException(this.message, {this.statusCode});

  @override
  String toString() =>
      'SyncException($message${statusCode != null ? ', HTTP $statusCode' : ''})';
}
