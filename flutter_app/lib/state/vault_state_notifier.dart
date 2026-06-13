import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nex_item.dart';
import '../repositories/vault_repository.dart';
import '../services/autofill_engine.dart';
import 'unlock_state.dart';

// ---------------------------------------------------------------------------
// VaultState — observable state for the vault UI
// ---------------------------------------------------------------------------

class VaultState {
  final List<NexItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final int selectedTypeTab; // 0 = All, 1 = Login, 2 = Card, 3 = Secure Note

  const VaultState({
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedTypeTab = 0,
  });

  VaultState copyWith({
    List<NexItem>? items,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? selectedTypeTab,
  }) {
    return VaultState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTypeTab: selectedTypeTab ?? this.selectedTypeTab,
    );
  }
}

// ---------------------------------------------------------------------------
// VaultNotifier — drives vault CRUD + search
// ---------------------------------------------------------------------------

class VaultNotifier extends StateNotifier<VaultState> {
  final VaultRepository _repository;
  final Uint8List _masterKey;
  late final AutofillEngine _autofillEngine;

  VaultNotifier({
    required VaultRepository repository,
    required Uint8List masterKey,
  })  : _repository = repository,
        _masterKey = masterKey,
        super(const VaultState(items: [])) {
    // Initialize autofill engine with credential provider
    _autofillEngine = AutofillEngine(
      credentialProvider: () => state.items,
    );
    loadVault();
  }

  Uint8List get derivedKey => _masterKey;

  /// Public accessor for current items (avoids accessing protected `state`).
  List<NexItem> get currentItems => state.items;

  /// Loads vault items, filtered by the current search query.
  Future<void> loadVault() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.searchItems(
        query: state.searchQuery,
        derivedKey: _masterKey,
      );
      state = state.copyWith(items: items, isLoading: false);

      // Sync credentials to platform autofill cache
      _syncAutofillCache();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Vault load failed: $e',
        isLoading: false,
      );
    }
  }

  /// Updates the search filter and reloads.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadVault();
  }

  /// Switches the active category tab.
  void setTab(int tabIndex) {
    state = state.copyWith(selectedTypeTab: tabIndex);
  }

  /// Creates and persists a new vault entry.
  Future<void> addNewCredential({
    required String title,
    required int itemType,
    required String username,
    required String password,
  }) async {
    final item = NexItem()
      ..name = title
      ..type = itemType
      ..fields = [
        NexField()
          ..name = 'username'
          ..value = username
          ..isSensitive = false,
        NexField()
          ..name = 'password'
          ..value = password
          ..fieldType = 2
          ..isSensitive = true,
      ];

    await _repository.saveItem(item: item, derivedKey: _masterKey);
    await loadVault(); // loadVault already syncs autofill cache
  }

  /// Deletes a vault entry.
  Future<void> deleteItem(NexItem item) async {
    await _repository.deleteItem(item: item);
    await loadVault();
  }

  Future<void> toggleFavorite(NexItem item) async {
    await _repository.toggleFavorite(item: item);
    await loadVault();
  }

  void markUsed(NexItem item) {
    _repository.markUsed(item: item);
    // No need to sync cache for usage tracking
  }

  /// Re-saves an existing item (used by security audit to update passwords).
  Future<void> updateItem(NexItem item) async {
    // Deep-copy: saveItem encrypts sensitive fields in-place, which would
    // corrupt the in-memory item used by the detail screen.
    final copy = NexItem()
      ..uuid = item.uuid
      ..vaultId = item.vaultId
      ..type = item.type
      ..name = item.name
      ..iconKey = item.iconKey
      ..tags = List<String>.from(item.tags)
      ..isFavorite = item.isFavorite
      ..updatedAt = item.updatedAt
      ..lastUsedAt = item.lastUsedAt
      ..fields = item.fields.map((f) => NexField()
        ..name = f.name
        ..value = f.value
        ..fieldType = f.fieldType
        ..isSensitive = f.isSensitive
      ).toList();
    await _repository.saveItem(item: copy, derivedKey: _masterKey);
    await loadVault();
  }

  /// Returns items with weak passwords (length < [minimumSecureLength]).
  Future<List<NexItem>> getWeakPasswords({int minimumSecureLength = 10}) {
    return _repository.getWeakPasswordItems(
      derivedKey: _masterKey,
      minimumSecureLength: minimumSecureLength,
    );
  }

  /// Returns all items (used by SyncService for comparison).
  Future<List<NexItem>> getAllItems() {
    return _repository.getAllItems(derivedKey: _masterKey);
  }

  /// Syncs credentials to platform autofill cache.
  void _syncAutofillCache() {
    try {
      _autofillEngine.cacheCredentials();
    } catch (e) {
      debugPrint('[VaultNotifier] Failed to sync autofill cache: $e');
    }
  }

  /// Clears autofill cache (called when vault is locked).
  Future<void> clearAutofillCache() async {
    try {
      await _autofillEngine.clearCredentialCache();
    } catch (e) {
      debugPrint('[VaultNotifier] Failed to clear autofill cache: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final masterKeyProvider = Provider<Uint8List>((ref) {
  final unlockState = ref.watch(unlockStateProvider);
  if (unlockState.derivedKey == null) {
    throw StateError('Vault is locked — derived key not available');
  }
  return unlockState.derivedKey!;
});

final repositoryProvider = Provider<VaultRepository>((ref) {
  throw UnimplementedError(
    'Override repositoryProvider at app startup with an initialized VaultRepository',
  );
});

final vaultStateProvider =
    StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  final repo = ref.watch(repositoryProvider);
  final key = ref.watch(masterKeyProvider);
  return VaultNotifier(repository: repo, masterKey: key);
});
