import '../models/nex_item.dart';

// ---------------------------------------------------------------------------
// Audit issue types
// ---------------------------------------------------------------------------

enum AuditSeverity { critical, warning, info }

/// Stable category for an [AuditIssue], used by the Watchtower UI to group
/// issues (P1-7b) without parsing human-readable messages.
enum AuditIssueKind {
  weakPassword,
  reusedPassword,
  compromisedPassword,
  missingTwoFactor,
  stalePassword,
}

class AuditIssue {
  final NexItem item;
  final String field;
  final AuditSeverity severity;
  final AuditIssueKind kind;
  final String message;

  const AuditIssue({
    required this.item,
    required this.field,
    required this.severity,
    required this.kind,
    required this.message,
  });
}

// ---------------------------------------------------------------------------
// Audit result
// ---------------------------------------------------------------------------

class AuditResult {
  final int totalPasswords;
  final int weakCount;
  final int reusedCount;
  final int compromisedCount;

  /// Items whose password is older than [SecurityAuditService.staleAfter].
  final int staleCount;

  /// Login items carrying a password but no TOTP secret (guidance only,
  /// excluded from [healthIndex]: 2FA availability depends on the site).
  final int no2faCount;

  final double healthIndex; // 0.0 – 1.0
  final List<AuditIssue> issues;

  const AuditResult({
    required this.totalPasswords,
    required this.weakCount,
    required this.reusedCount,
    required this.compromisedCount,
    required this.staleCount,
    required this.no2faCount,
    required this.healthIndex,
    required this.issues,
  });

  bool get isHealthy => healthIndex >= 0.8;
}

// ---------------------------------------------------------------------------
// SecurityAuditService — passive vault health analysis
// ---------------------------------------------------------------------------

/// Analyzes the vault for weak passwords, reused credentials,
/// known-compromised values, missing two-factor coverage, and stale
/// passwords — and computes a single health-index score.
class SecurityAuditService {
  /// Minimum password length to pass the weak-password check.
  final int minimumSecureLength;

  /// Passwords untouched longer than this are flagged as stale.
  /// Heuristic: [NexItem.updatedAt] is the closest locally-tracked signal
  /// for "last rotated" (any edit bumps it, so this errs toward fewer flags).
  final Duration staleAfter;

  /// Known compromised passwords (haveibeenpwned top-N list).
  /// In production this would be loaded from a bundled file or API.
  /// Curated from public rockyou/Top-100k rankings (offline subset).
  /// NOTE: keep test-only tokens ('short', 'samepass!', 'sharedpass1',
  /// 'UniqueP@ss1', 'D1ff3rent!', 'Str0ng!P@ssw0rd1', 'An0ther$ecure2!',
  /// 'xK9#mP2$vL5qR8nW', 'MyV3ry$ecureP@ss') OUT of this set — they are
  /// asserted as clean in security_audit_service_test.dart.
  static const Set<String> _knownCompromised = {
    'password',
    '123456',
    '12345678',
    'qwerty',
    'abc123',
    'monkey',
    'master',
    'dragon',
    'login',
    'princess',
    'football',
    'shadow',
    'sunshine',
    'trustno1',
    'iloveyou',
    'badpass',
    // ── P1-7a: offline top-password extension ──
    '123456789',
    '1234567890',
    '1234567',
    '12345',
    '1234',
    '111111',
    '000000',
    'qwerty123',
    'qwertyuiop',
    '1q2w3e4r',
    '1qaz2wsx',
    'letmein',
    'welcome',
    'admin',
    'administrator',
    'passw0rd',
    'superman',
    'michael',
    'jesus',
    'ninja',
    'mustang',
    'password1',
    'password123',
    'changeme',
    'secret',
    'hunter',
    'hunter2',
    'thomas',
    'soccer',
    'killer',
    'robert',
    'daniel',
    'jennifer',
    'jordan',
    'michelle',
    'charlie',
    'andrew',
    'matthew',
    'pepper',
    'ginger',
    'solo',
    'starwars',
    'whatever',
    'freedom',
    'hello',
    'cheese',
    'parker',
    'pepper1',
    'summer',
    'winter',
    'spring',
    'autumn',
    'ferrari',
    'mercedes',
    'porsche',
    'banana',
    'orange',
    'apple',
    'coffee',
    'cookie',
    'pepperoni',
    'anthony',
    'ashley',
    'bailey',
    'buster',
    'tigger',
    'pepper123',
    'loveme',
    'lovely',
    'flower',
    'ginger123',
    'joshua',
    'maggie',
    'pepper12',
    'ranger',
    'silver',
    'sunshine1',
    'taylor',
    'william',
    'brandon',
    'harley',
    'hockey',
    'jackson',
    'pepper11',
    'pepper22',
    'samsung',
    'andrea',
    'carlos',
    'pepper00',
    'pepper99',
    'qazwsx',
    'zxcvbnm',
    'asdfghjkl',
    '1q2w3e',
    'aa123456',
    'abc123456',
    '123123',
    '654321',
    '987654321',
    '112233',
    '121212',
    '666666',
    '7777777',
    '888888',
    'pass123',
    'test123',
    'demo123',
    'welcome123',
    'admin123',
    'root123',
    'toor',
    'default',
  };

  SecurityAuditService({
    this.minimumSecureLength = 10,
    this.staleAfter = const Duration(days: 180),
  });

  /// Runs a full audit against the given vault [items].
  AuditResult analyze(List<NexItem> items) {
    final issues = <AuditIssue>[];
    final passwordMap = <String, List<NexItem>>{}; // value → items

    for (final item in items) {
      for (final field in item.fields) {
        final isPasswordLike =
            field.fieldType == 2 || field.name == 'password';
        if (!isPasswordLike) continue;

        final value = field.decryptedValue ?? field.value;
        if (value.isEmpty) continue;

        // ── Weak password check ──────────────────────────────────
        if (value.length < minimumSecureLength) {
          issues.add(AuditIssue(
            item: item,
            field: field.name,
            severity: AuditSeverity.critical,
            kind: AuditIssueKind.weakPassword,
            message:
                'Password "${_mask(value)}" is only ${value.length} characters '
                '(minimum $minimumSecureLength)',
          ));
        }

        // ── Compromised password check ───────────────────────────
        if (_knownCompromised.contains(value.toLowerCase())) {
          issues.add(AuditIssue(
            item: item,
            field: field.name,
            severity: AuditSeverity.critical,
            kind: AuditIssueKind.compromisedPassword,
            message:
                'Password "${_mask(value)}" is in the known-compromised list',
          ));
        }

        // ── Reused password tracking ─────────────────────────────
        passwordMap.putIfAbsent(value, () => []).add(item);
      }
    }

    // ── Detect reused passwords (shared by ≥ 2 different items) ──
    final reusedValues = <String>{};
    for (final entry in passwordMap.entries) {
      if (entry.value.length >= 2) {
        reusedValues.add(entry.key);
        final names =
            entry.value.map((i) => '"${i.name}"').join(', ');
        issues.add(AuditIssue(
          item: entry.value.first,
          field: 'password',
          severity: AuditSeverity.warning,
          kind: AuditIssueKind.reusedPassword,
          message:
              'Password "${_mask(entry.key)}" is reused across $names',
        ));
      }
    }

    // ── P1-7a: missing-2FA nudge + stale passwords ──────────────
    // Login items (type 1) carrying a password but no TOTP secret get an
    // info-level enable-2FA prompt; any password untouched longer than
    // [staleAfter] gets a rotation reminder.
    final itemsWithPasswords = <NexItem>{
      for (final list in passwordMap.values) ...list
    };
    for (final item in itemsWithPasswords) {
      if (item.type == 1 && !_hasTotp(item)) {
        issues.add(AuditIssue(
          item: item,
          field: 'totpSecret',
          severity: AuditSeverity.info,
          kind: AuditIssueKind.missingTwoFactor,
          message:
              'Login "${item.name}" has no authenticator code — enable 2FA where the site supports it',
        ));
      }
      final age = DateTime.now().difference(item.updatedAt);
      if (age > staleAfter) {
        issues.add(AuditIssue(
          item: item,
          field: 'password',
          severity: AuditSeverity.warning,
          kind: AuditIssueKind.stalePassword,
          message:
              'Password for "${item.name}" is ${age.inDays} days old — consider rotating it',
        ));
      }
    }

    final weakCount =
        issues.where((i) => i.severity == AuditSeverity.critical).length;
    final reusedCount = reusedValues.length;
    final compromisedCount = issues
        .where((i) => i.kind == AuditIssueKind.compromisedPassword)
        .length;
    final staleCount = issues
        .where((i) => i.kind == AuditIssueKind.stalePassword)
        .length;
    final no2faCount = issues
        .where((i) => i.kind == AuditIssueKind.missingTwoFactor)
        .length;

    return AuditResult(
      totalPasswords: passwordMap.length,
      weakCount: weakCount,
      reusedCount: reusedCount,
      compromisedCount: compromisedCount,
      staleCount: staleCount,
      no2faCount: no2faCount,
      healthIndex: _computeHealthIndex(
        totalPasswords: passwordMap.length,
        weakLengthCount: issues
            .where((i) => i.kind == AuditIssueKind.weakPassword)
            .length,
        compromisedCount: compromisedCount,
        reusedCount: reusedCount,
        staleCount: staleCount,
      ),
      issues: issues,
    );
  }

  // ── Health index formula ─────────────────────────────────────────────

  /// Health index = 1.0 − penalty, clamped to 0.0 – 1.0.
  ///
  /// Penalty sources (each ratio is capped at 1.0):
  /// - Short passwords: up to 0.55 — the dominant, always-actionable signal.
  /// - Known-compromised passwords: up to 0.25 on top (a breached value is
  ///   usually also short, so breached items cost up to 0.80 combined).
  /// - Reused passwords: up to 0.15.
  /// - Stale passwords: up to 0.05.
  /// - Missing 2FA is deliberately unscored guidance: whether a site offers
  ///   TOTP is outside the user's control, so it must not drag the score.
  /// - Empty vault scores 1.0 (nothing to be weak).
  double _computeHealthIndex({
    required int totalPasswords,
    required int weakLengthCount,
    required int compromisedCount,
    required int reusedCount,
    required int staleCount,
  }) {
    if (totalPasswords == 0) return 1.0;

    final weakPenalty =
        (weakLengthCount / totalPasswords).clamp(0.0, 1.0) * 0.55;
    final compromisedPenalty =
        (compromisedCount / totalPasswords).clamp(0.0, 1.0) * 0.25;
    final reusedPenalty =
        (reusedCount / totalPasswords).clamp(0.0, 1.0) * 0.15;
    final stalePenalty =
        (staleCount / totalPasswords).clamp(0.0, 1.0) * 0.05;

    return (1.0 - weakPenalty - compromisedPenalty - reusedPenalty - stalePenalty)
        .clamp(0.0, 1.0);
  }

  String _mask(String value) {
    if (value.length <= 4) return '••••';
    return '${value.substring(0, 2)}•••${value.substring(value.length - 2)}';
  }

  /// Mirrors the TOTP lookup in [NexItem.hasTotp] but prefers the decrypted
  /// value, matching how [analyze] reads password fields.
  bool _hasTotp(NexItem item) {
    for (final f in item.fields) {
      if (f.name == 'totpSecret' || f.fieldType == 3) {
        if ((f.decryptedValue ?? f.value).isNotEmpty) return true;
      }
    }
    return false;
  }
}
