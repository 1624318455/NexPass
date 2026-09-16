import 'package:isar/isar.dart';

part 'password_history.g.dart';

/// A field-level-encrypted snapshot of a password value, kept for 14 days
/// so a generated or rotated password is recoverable even if it was never
/// saved to its vault item (Proton/Dashlane 2-week parity).
///
/// Encryption envelope mirrors [NexField] sensitive values handled by
/// VaultRepository: `base64(nonce12 + ciphertext + mac16)` via
/// CryptoService AES-256-GCM. Plaintext never touches disk.
@collection
class PasswordHistoryEntry {
  Id id = Isar.autoIncrement;

  /// Owning vault item, null for generated-but-never-saved passwords.
  @Index()
  String? itemUuid;

  /// Human label shown in the history list (item name or source).
  String label = '';

  /// Where the value came from: 'created' | 'rotated' | 'generated'.
  String source = '';

  /// AES-256-GCM envelope (base64). Decrypted on read via CryptoService.
  String encryptedValue = '';

  @Index()
  DateTime createdAt = DateTime.now();

  @ignore
  String? decryptedValue;
}
