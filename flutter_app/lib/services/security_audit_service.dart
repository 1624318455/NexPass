import '../models/nex_item.dart';

// ---------------------------------------------------------------------------
// Audit issue types
// ---------------------------------------------------------------------------

enum AuditSeverity { critical, warning, info }

class AuditIssue {
  final NexItem item;
  final String field;
  final AuditSeverity severity;
  final String message;

  const AuditIssue({
    required this.item,
    required this.field,
    required this.severity,
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
  final double healthIndex; // 0.0 – 1.0
  final List<AuditIssue> issues;

  const AuditResult({
    required this.totalPasswords,
    required this.weakCount,
    required this.reusedCount,
    required this.compromisedCount,
    required this.healthIndex,
    required this.issues,
  });

  bool get isHealthy => healthIndex >= 0.8;
}

// ---------------------------------------------------------------------------
// SecurityAuditService — passive vault health analysis
// ---------------------------------------------------------------------------

/// Analyzes the vault for weak passwords, reused credentials,
/// and computes a single health-index score.
class SecurityAuditService {
  /// Minimum password length to pass the weak-password check.
  final int minimumSecureLength;

  /// Known compromised passwords (haveibeenpwned top-N list).
  /// In production this would be loaded from a bundled file or API.
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
  };

  SecurityAuditService({this.minimumSecureLength = 10});

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
          message:
              'Password "${_mask(entry.key)}" is reused across $names',
        ));
      }
    }

    final weakCount =
        issues.where((i) => i.severity == AuditSeverity.critical).length;
    final reusedCount = reusedValues.length;
    final compromisedCount = issues
        .where((i) => i.message.contains('compromised'))
        .length;

    return AuditResult(
      totalPasswords: passwordMap.length,
      weakCount: weakCount,
      reusedCount: reusedCount,
      compromisedCount: compromisedCount,
      healthIndex: _computeHealthIndex(
        totalPasswords: passwordMap.length,
        weakCount: weakCount,
        reusedCount: reusedCount,
      ),
      issues: issues,
    );
  }

  // ── Health index formula ─────────────────────────────────────────────

  /// Health index = 1.0 − penalty.
  ///
  /// Penalty sources:
  /// - Each weak password costs up to 0.30 (divided by total, capped).
  /// - Each reused password costs up to 0.20.
  /// - Empty vault scores 1.0 (nothing to be weak).
  double _computeHealthIndex({
    required int totalPasswords,
    required int weakCount,
    required int reusedCount,
  }) {
    if (totalPasswords == 0) return 1.0;

    final weakPenalty =
        (weakCount / totalPasswords).clamp(0.0, 1.0) * 0.60;
    final reusedPenalty =
        (reusedCount / totalPasswords).clamp(0.0, 1.0) * 0.40;

    return (1.0 - weakPenalty - reusedPenalty).clamp(0.0, 1.0);
  }

  String _mask(String value) {
    if (value.length <= 4) return '••••';
    return '${value.substring(0, 2)}•••${value.substring(value.length - 2)}';
  }
}
