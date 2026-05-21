import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nex_item.dart';
import '../repositories/vault_repository.dart';

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

  VaultNotifier({
    required VaultRepository repository,
    required Uint8List masterKey,
  })  : _repository = repository,
        _masterKey = masterKey,
        super(const VaultState(items: [])) {
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
    await loadVault();
  }

  /// Deletes a vault entry.
  Future<void> deleteItem(NexItem item) async {
    await _repository.deleteItem(item: item);
    await loadVault();
  }

  /// Re-saves an existing item (used by security audit to update passwords).
  Future<void> updateItem(NexItem item) async {
    await _repository.saveItem(item: item, derivedKey: _masterKey);
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
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final masterKeyProvider = Provider<Uint8List>((ref) {
  throw UnimplementedError(
    'Override masterKeyProvider at app startup with the Argon2id-derived key',
  );
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
