import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/vault_repository.dart';
import '../services/sync_service.dart';

// ---------------------------------------------------------------------------
// Providers (referenced by main.dart overrides)
// ---------------------------------------------------------------------------

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError(
    'Override syncServiceProvider at app startup with a configured SyncService',
  );
});

final syncStateProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  throw UnimplementedError(
    'Override syncStateProvider at app startup',
  );
});

// ---------------------------------------------------------------------------
// SyncStatus — lifecycle phases exposed to the UI
// ---------------------------------------------------------------------------

enum SyncStatus {
  idle,
  handshake,
  comparing,
  downloading,
  uploading,
  success,
  error,
}

// ---------------------------------------------------------------------------
// SyncLogEntry — a single line in the sync activity log
// ---------------------------------------------------------------------------

class SyncLogEntry {
  final DateTime timestamp;
  final SyncStatus status;
  final String message;

  const SyncLogEntry({
    required this.timestamp,
    required this.status,
    required this.message,
  });

  String get timeString =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// SyncState — full observable state for the UI
// ---------------------------------------------------------------------------

class SyncState {
  final SyncStatus status;
  final List<SyncLogEntry> logs;
  final int downloadedCount;
  final int uploadedCount;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.logs = const [],
    this.downloadedCount = 0,
    this.uploadedCount = 0,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    List<SyncLogEntry>? logs,
    int? downloadedCount,
    int? uploadedCount,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      errorMessage: errorMessage,
    );
  }

  bool get isSyncing =>
      status == SyncStatus.handshake ||
      status == SyncStatus.comparing ||
      status == SyncStatus.downloading ||
      status == SyncStatus.uploading;

  bool get hasError => status == SyncStatus.error;
}

// ---------------------------------------------------------------------------
// SyncNotifier — drives the full sync lifecycle
// ---------------------------------------------------------------------------

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final VaultRepository _repository;
  final Uint8List _derivedKey;

  static const int _maxLogs = 50;

  SyncNotifier({
    required SyncService syncService,
    required VaultRepository repository,
    required Uint8List derivedKey,
  })  : _syncService = syncService,
        _repository = repository,
        _derivedKey = derivedKey,
        super(const SyncState());

  // ── Public API ──────────────────────────────────────────────────────

  /// Starts a full bidirectional sync cycle.
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = const SyncState(status: SyncStatus.handshake);
    _addLog(SyncStatus.handshake, 'WebDAV handshake initiated');

    try {
      // 1. Load local vault
      final localItems = await _repository.getAllItems(derivedKey: _derivedKey);

      // 2. Run sync with progress callbacks
      int downloads = 0;

      await _syncService.syncVault(
        localItems: localItems,
        onProgress: _onSyncProgress,
        onDownloadItem: (item) async {
          downloads++;
          await _repository.saveItem(item: item, derivedKey: _derivedKey);
        },
      );

      state = state.copyWith(
        status: SyncStatus.success,
        downloadedCount: downloads,
      );
      _addLog(
        SyncStatus.success,
        'Sync complete — $downloads downloaded',
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      _addLog(SyncStatus.error, 'Sync failed: ${_friendlyError(e)}');
    }
  }

  /// Clears log history and resets to idle.
  void reset() {
    state = const SyncState();
  }

  // ── Internal helpers ────────────────────────────────────────────────

  void _onSyncProgress(SyncProgressEvent event) {
    switch (event.phase) {
      case SyncPhase.handshake:
        state = state.copyWith(status: SyncStatus.handshake);
        _addLog(SyncStatus.handshake, event.message);
        break;
      case SyncPhase.comparing:
        state = state.copyWith(status: SyncStatus.comparing);
        _addLog(SyncStatus.comparing, event.message);
        break;
      case SyncPhase.downloading:
        state = state.copyWith(status: SyncStatus.downloading);
        _addLog(SyncStatus.downloading, event.message);
        break;
      case SyncPhase.uploading:
        state = state.copyWith(status: SyncStatus.uploading);
        _addLog(SyncStatus.uploading, event.message);
        break;
      case SyncPhase.success:
        _addLog(SyncStatus.success, event.message);
        break;
      case SyncPhase.error:
        _addLog(SyncStatus.error, event.message);
        break;
    }
  }

  void _addLog(SyncStatus status, String message) {
    final entry = SyncLogEntry(
      timestamp: DateTime.now(),
      status: status,
      message: message,
    );
    final newLogs = [entry, ...state.logs];
    if (newLogs.length > _maxLogs) {
      state = state.copyWith(logs: newLogs.sublist(0, _maxLogs));
    } else {
      state = state.copyWith(logs: newLogs);
    }
  }

  String _friendlyError(Object error) {
    final s = error.toString();
    if (s.contains('SocketException')) return 'Network unreachable';
    if (s.contains('HandshakeException')) return 'TLS handshake failed';
    if (s.contains('401')) return 'Authentication failed (check credentials)';
    if (s.contains('404')) return 'Remote vault not found';
    if (s.contains('507')) return 'Remote storage full';
    return s.length > 120 ? '${s.substring(0, 117)}...' : s;
  }
}
