import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nex_item.dart';

// ---------------------------------------------------------------------------
// DualClipboardState — observable state for the overlay UI
// ---------------------------------------------------------------------------

class DualClipboardState {
  /// Whether the overlay is currently visible.
  final bool isVisible;

  /// The item name shown in the overlay header.
  final String itemName;

  /// The 6-digit TOTP that was copied to the system clipboard.
  final String totpCode;

  /// Seconds remaining before the RAM-cached password is wiped.
  final int secondsRemaining;

  const DualClipboardState({
    this.isVisible = false,
    this.itemName = '',
    this.totpCode = '',
    this.secondsRemaining = 0,
  });

  DualClipboardState copyWith({
    bool? isVisible,
    String? itemName,
    String? totpCode,
    int? secondsRemaining,
  }) {
    return DualClipboardState(
      isVisible: isVisible ?? this.isVisible,
      itemName: itemName ?? this.itemName,
      totpCode: totpCode ?? this.totpCode,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}

// ---------------------------------------------------------------------------
// DualClipboardNotifier — core dual-clipboard engine
// ---------------------------------------------------------------------------

/// Implements the Monica-inspired dual clipboard flow:
///
/// 1. Copy the 6-digit TOTP → system clipboard (`Clipboard.setData`).
/// 2. Store the password in a secure in-memory RAM buffer — never written
///    to logs, SharedPreferences, or any persistent storage.
/// 3. Show an overlay guiding the user through the two-step paste flow.
/// 4. Auto-wipe the RAM buffer after 30 seconds.
class DualClipboardNotifier extends StateNotifier<DualClipboardState> {
  Timer? _countdownTimer;

  /// The password held in secure RAM. Intentionally not exposed via state
  /// to prevent accidental logging through reactive watchers.
  String? _cachedPassword;

  /// How long (seconds) the password stays in RAM before auto-wipe.
  static const int cacheDurationSeconds = 30;

  DualClipboardNotifier() : super(const DualClipboardState());

  /// Whether a password is currently cached in RAM.
  bool get hasCachedPassword => _cachedPassword != null;

  /// Retrieves the cached password and immediately clears the buffer.
  ///
  /// This is the only way external code can access the password — a
  /// single-use read that destroys the copy, preventing stale references.
  String? consumePassword() {
    final pwd = _cachedPassword;
    _secureWipe();
    return pwd;
  }

  /// Executes the dual clipboard copy for a vault [item].
  ///
  /// Returns `true` if the dual path was taken (TOTP + password),
  /// `false` if only a single-field copy was performed.
  Future<bool> copyItem(NexItem item) async {
    final passwordField = _findPasswordField(item);
    final totpField = _findTotpField(item);

    final hasPassword = passwordField?.decryptedValue?.isNotEmpty == true;
    final hasTotp = totpField?.decryptedValue?.isNotEmpty == true;

    if (hasPassword && hasTotp) {
      // ── Dual clipboard path ──────────────────────────────────────
      await _copyTotpToClipboard(totpField!.decryptedValue!);
      _cachePasswordSecurely(passwordField!.decryptedValue!);
      _showOverlay(item.name, totpField.decryptedValue!);
      return true;
    }

    // ── Single-field fallback (password only) ──────────────────────
    if (hasPassword) {
      await Clipboard.setData(ClipboardData(text: passwordField!.decryptedValue!));
      return false;
    }

    // ── Single-field fallback (other field) ────────────────────────
    final firstValue = item.fields
        .where((f) => f.decryptedValue != null && f.decryptedValue!.isNotEmpty)
        .map((f) => f.decryptedValue!)
        .firstOrNull;
    if (firstValue != null) {
      await Clipboard.setData(ClipboardData(text: firstValue));
    }
    return false;
  }

  /// Dismisses the overlay, wipes the RAM buffer, and clears the system clipboard.
  void dismiss() {
    _secureWipe();
    _clearSystemClipboard();
    state = const DualClipboardState();
  }

  @override
  void dispose() {
    _secureWipe();
    super.dispose();
  }

  // ── Private helpers ───────────────────────────────────────────────

  Future<void> _copyTotpToClipboard(String totp) async {
    await Clipboard.setData(ClipboardData(text: totp));
  }

  void _cachePasswordSecurely(String password) {
    _secureWipe();
    _cachedPassword = password;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    var remaining = cacheDurationSeconds;

    state = state.copyWith(secondsRemaining: remaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        _secureWipe();
        _clearSystemClipboard();
        state = const DualClipboardState();
      } else {
        state = state.copyWith(secondsRemaining: remaining);
      }
    });
  }

  void _secureWipe() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    // Overwrite before releasing reference
    if (_cachedPassword != null) {
      _cachedPassword = '';
    }
    _cachedPassword = null;
  }

  /// Clears the system clipboard to prevent credential leakage.
  Future<void> _clearSystemClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {
      // Non-critical: clipboard clear is best-effort
    }
  }

  void _showOverlay(String itemName, String totpCode) {
    state = DualClipboardState(
      isVisible: true,
      itemName: itemName,
      totpCode: totpCode,
      secondsRemaining: cacheDurationSeconds,
    );
  }

  NexField? _findPasswordField(NexItem item) {
    try {
      return item.fields.firstWhere(
        (f) => f.name == 'password' || f.fieldType == 2,
      );
    } catch (_) {
      return null;
    }
  }

  NexField? _findTotpField(NexItem item) {
    try {
      return item.fields.firstWhere(
        (f) => f.name == 'totpSecret' || f.fieldType == 3,
      );
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dualClipboardProvider =
    StateNotifierProvider<DualClipboardNotifier, DualClipboardState>((ref) {
  return DualClipboardNotifier();
});
