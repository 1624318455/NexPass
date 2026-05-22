import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../services/crypto_utils.dart';
import '../services/secure_storage_service.dart';

enum AppState { initializing, locked, ready }

final appStateProvider = StateProvider<AppState>((ref) => AppState.initializing);

class UnlockState {
  final Uint8List? derivedKey;
  final KeyManager? keyManager;
  final bool isUnlocked;

  const UnlockState({
    this.derivedKey,
    this.keyManager,
    this.isUnlocked = false,
  });

  UnlockState copyWith({
    Uint8List? derivedKey,
    KeyManager? keyManager,
    bool? isUnlocked,
  }) {
    return UnlockState(
      derivedKey: derivedKey ?? this.derivedKey,
      keyManager: keyManager ?? this.keyManager,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

class UnlockNotifier extends StateNotifier<UnlockState> {
  final SecureStorageService _secureStorage;
  final CryptoService _cryptoService;

  UnlockNotifier({
    required SecureStorageService secureStorage,
    required CryptoService cryptoService,
  })  : _secureStorage = secureStorage,
        _cryptoService = cryptoService,
        super(const UnlockState());

  /// Auto-unlock if biometric is not enabled or key is recoverable.
  Future<void> tryAutoUnlock() async {
    final storedKey = await _secureStorage.recoverDerivedKey();
    if (storedKey != null) {
      _activateKey(storedKey);
    }
  }

  /// Unlock with biometric prompt.
  Future<bool> unlockWithBiometric({
    required Future<bool> Function(String reason) authenticate,
  }) async {
    final success = await authenticate('Unlock NexPass to access your vault');
    if (!success) return false;

    final storedKey = await _secureStorage.recoverDerivedKey();
    if (storedKey == null) return false;

    _activateKey(storedKey);
    return true;
  }

  /// Unlock with master password.
  Future<bool> unlockWithPassword(String password) async {
    final salt = await _secureStorage.getOrCreateMasterSalt(
      () => base64Encode(generateSalt()),
    );
    final saltBytes = base64Decode(salt);

    final derivedKey = await _cryptoService.deriveKey(
      password: password,
      salt: saltBytes,
    );

    // Verify against stored key if available.
    final storedKey = await _secureStorage.recoverDerivedKey();
    if (storedKey != null) {
      if (!_bytesEqual(derivedKey, storedKey)) return false;
    }

    // Re-store the derived key (in case it was wiped by Lock Vault).
    await _secureStorage.storeDerivedKey(derivedKey);

    _activateKey(derivedKey);
    return true;
  }

  /// Lock the vault: wipe key from memory.
  void lock() {
    state.keyManager?.wipe();
    state = const UnlockState();
  }

  /// Activate KeyManager and transition to ready state.
  void _activateKey(Uint8List key) {
    final km = KeyManager(
      sessionTimeout: const Duration(minutes: 5),
      onLock: () {
        if (mounted) state = const UnlockState();
      },
    );
    km.activate(key);
    state = UnlockState(
      derivedKey: key,
      keyManager: km,
      isUnlocked: true,
    );
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final unlockStateProvider =
    StateNotifierProvider<UnlockNotifier, UnlockState>((ref) {
  throw UnimplementedError('Override at app startup');
});
