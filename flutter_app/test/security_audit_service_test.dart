import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/models/nex_item.dart';
import 'package:nexpass/services/security_audit_service.dart';

void main() {
  late SecurityAuditService audit;

  setUp(() {
    audit = SecurityAuditService(minimumSecureLength: 10);
  });

  NexItem _makeItem(String name, String password) {
    final item = NexItem()
      ..name = name
      ..type = 1
      ..fields = [
        NexField()
          ..name = 'password'
          ..value = password
          ..fieldType = 2
          ..isSensitive = true,
      ];
    return item;
  }

  NexItem _makeItemWithNoPassword(String name) {
    return NexItem()
      ..name = name
      ..type = 1
      ..fields = [
        NexField()
          ..name = 'username'
          ..value = 'user@test.com'
          ..fieldType = 1,
      ];
  }

  // ── Empty vault ──────────────────────────────────────────────────────

  group('empty vault', () {
    test('returns healthy with 0 passwords', () {
      final result = audit.analyze([]);
      expect(result.totalPasswords, 0);
      expect(result.healthIndex, 1.0);
      expect(result.isHealthy, isTrue);
      expect(result.issues, isEmpty);
    });
  });

  // ── Weak password detection ──────────────────────────────────────────

  group('weak password detection', () {
    test('flags password shorter than minimumSecureLength', () {
      final result = audit.analyze([_makeItem('Short', 'abc')]);
      expect(result.weakCount, 1);
      // P1-7a: a TOTP-less login also gets an info-level 2FA nudge.
      expect(result.issues.length, 2);
      expect(
        result.issues
            .where((i) => i.kind == AuditIssueKind.weakPassword)
            .single
            .severity,
        AuditSeverity.critical,
      );
      expect(
        result.issues
            .where((i) => i.kind == AuditIssueKind.missingTwoFactor)
            .single
            .severity,
        AuditSeverity.info,
      );
    });

    test('passes password at exactly minimumSecureLength', () {
      final result = audit.analyze([_makeItem('OK', '1234567890')]);
      // 10 chars = exactly minimumSecureLength, should NOT be flagged as weak
      final weakIssues = result.issues.where(
        (i) => i.message.contains('only'),
      );
      expect(weakIssues, isEmpty);
    });

    test('passes long password', () {
      final result = audit.analyze([
        _makeItem('Strong', r'MyV3ry$ecureP@ss'),
      ]);
      final weakIssues = result.issues.where(
        (i) => i.message.contains('only'),
      );
      expect(weakIssues, isEmpty);
    });
  });

  // ── Compromised password detection ───────────────────────────────────

  group('compromised password detection', () {
    test('flags known compromised passwords', () {
      final result = audit.analyze([_makeItem('Leaky', 'password')]);
      final compromised = result.issues.where(
        (i) => i.message.contains('compromised'),
      );
      expect(compromised, isNotEmpty);
      expect(result.compromisedCount, 1);
    });

    test('flags 123456 as compromised', () {
      final result = audit.analyze([_makeItem('Bad', '123456')]);
      expect(result.compromisedCount, 1);
    });

    test('does not flag unique strong password as compromised', () {
      final result = audit.analyze([
        _makeItem('Safe', r'xK9#mP2$vL5qR8nW'),
      ]);
      expect(result.compromisedCount, 0);
    });
  });

  // ── Reused password detection ────────────────────────────────────────

  group('reused password detection', () {
    test('detects two items sharing the same password', () {
      final items = [
        _makeItem('Account A', 'sharedpass1'),
        _makeItem('Account B', 'sharedpass1'),
      ];
      final result = audit.analyze(items);
      expect(result.reusedCount, 1);
      final reusedIssues = result.issues.where(
        (i) => i.severity == AuditSeverity.warning,
      );
      expect(reusedIssues, isNotEmpty);
    });

    test('no reuse warning when all passwords differ', () {
      final items = [
        _makeItem('A', 'UniqueP@ss1'),
        _makeItem('B', 'D1ff3rent!'),
      ];
      final result = audit.analyze(items);
      expect(result.reusedCount, 0);
    });
  });

  // ── Health index ─────────────────────────────────────────────────────

  group('health index', () {
    test('all strong unique passwords → 1.0', () {
      final items = [
        _makeItem('A', 'Str0ng!P@ssw0rd1'),
        _makeItem('B', r'An0ther$ecure2!'),
      ];
      final result = audit.analyze(items);
      expect(result.healthIndex, 1.0);
      expect(result.isHealthy, isTrue);
    });

    test('all weak passwords → low score', () {
      final items = [
        _makeItem('A', 'ab'),
        _makeItem('B', 'cd'),
        _makeItem('C', 'ef'),
      ];
      final result = audit.analyze(items);
      expect(result.healthIndex, lessThan(0.5));
      expect(result.isHealthy, isFalse);
    });

    test('single compromised password penalizes score', () {
      final result = audit.analyze([
        _makeItem('Leaky', '123456'),
      ]);
      expect(result.healthIndex, lessThan(1.0));
    });
  });

  // ── Non-password fields ignored ──────────────────────────────────────

  group('non-password fields', () {
    test('items without password fields are excluded', () {
      final result = audit.analyze([_makeItemWithNoPassword('NoPw')]);
      expect(result.totalPasswords, 0);
      expect(result.healthIndex, 1.0);
    });
  });

  // ── Mixed scenario ───────────────────────────────────────────────────

  group('mixed vault', () {
    test('correctly counts all issue types', () {
      final items = [
        _makeItem('Weak', 'short'),             // weak + compromised
        _makeItem('Duplicate1', 'samepass!'),    // reused
        _makeItem('Duplicate2', 'samepass!'),    // reused
        _makeItem('Strong', r'xK9#mP2$vL5qR8'),  // clean
      ];
      final result = audit.analyze(items);
      expect(result.totalPasswords, 3); // 3 unique password values
      expect(result.weakCount, greaterThanOrEqualTo(1));
      expect(result.reusedCount, 1);
      expect(result.healthIndex, lessThan(1.0));
    });
  });

  // ── P1-7a: 2FA coverage + stale passwords ────────────────────────────

  group('two-factor coverage', () {
    NexItem makeLoginWithTotp(String name, String password) {
      return NexItem()
        ..name = name
        ..type = 1
        ..fields = [
          NexField()
            ..name = 'password'
            ..value = password
            ..fieldType = 2
            ..isSensitive = true,
          NexField()
            ..name = 'totpSecret'
            ..value = 'JBSWY3DPEHPK3PXP'
            ..fieldType = 3
            ..isSensitive = true,
        ];
    }

    test('login without TOTP gets an info-level 2FA nudge', () {
      final result = audit.analyze([_makeItem('NoTotp', r'V3ry$ecureP@ss!')]);
      final nudge = result.issues.where(
        (i) => i.kind == AuditIssueKind.missingTwoFactor,
      );
      expect(nudge, hasLength(1));
      expect(nudge.single.severity, AuditSeverity.info);
      expect(nudge.single.field, 'totpSecret');
    });

    test('login with TOTP gets no 2FA nudge', () {
      final result = audit.analyze(
        [makeLoginWithTotp('WithTotp', r'V3ry$ecureP@ss!')],
      );
      expect(
        result.issues.where((i) => i.kind == AuditIssueKind.missingTwoFactor),
        isEmpty,
      );
    });

    test('non-login items are exempt from the 2FA nudge', () {
      final card = NexItem()
        ..name = 'Card'
        ..type = 2
        ..fields = [
          NexField()
            ..name = 'password'
            ..value = r'V3ry$ecureP@ss!'
            ..fieldType = 2
            ..isSensitive = true,
        ];
      final result = audit.analyze([card]);
      expect(
        result.issues.where((i) => i.kind == AuditIssueKind.missingTwoFactor),
        isEmpty,
      );
    });
  });

  group('stale passwords', () {    test('password older than staleAfter is flagged', () {
      final item = _makeItem('Old', r'V3ry$ecureP@ss!')
        ..updatedAt = DateTime.now().subtract(const Duration(days: 200));
      final result = audit.analyze([item]);
      final stale = result.issues.where(
        (i) => i.kind == AuditIssueKind.stalePassword,
      );
      expect(stale, hasLength(1));
      expect(stale.single.severity, AuditSeverity.warning);
    });

    test('recently updated password is not flagged', () {
      final result = audit.analyze([_makeItem('Fresh', r'V3ry$ecureP@ss!')]);
      expect(
        result.issues.where((i) => i.kind == AuditIssueKind.stalePassword),
        isEmpty,
      );
    });

    test('staleAfter threshold is configurable', () {
      final strict = SecurityAuditService(
        staleAfter: const Duration(days: 30),
      );
      final item = _makeItem('Aged', r'V3ry$ecureP@ss!')
        ..updatedAt = DateTime.now().subtract(const Duration(days: 60));
      expect(
        strict
            .analyze([item])
            .issues
            .where((i) => i.kind == AuditIssueKind.stalePassword),
        hasLength(1),
      );
      expect(
        audit
            .analyze([item])
            .issues
            .where((i) => i.kind == AuditIssueKind.stalePassword),
        isEmpty,
      );
    });
  });

  // ── P1-7a (B3): health-index weights ────────────────────────────────

  group('health index weights', () {
    test('missing 2FA is counted but unscored', () {
      final result = audit.analyze([
        _makeItem('A', 'Str0ng!P@ssw0rd1'),
        _makeItem('B', r'An0ther$ecure2!'),
      ]);
      expect(result.no2faCount, 2);
      expect(result.healthIndex, 1.0);
      expect(result.isHealthy, isTrue);
    });

    test('stale-only vault costs 0.05', () {
      final item = _makeItem('Old', 'Str0ng!P@ssw0rd1')
        ..updatedAt = DateTime.now().subtract(const Duration(days: 200));
      final result = audit.analyze([item]);
      expect(result.staleCount, 1);
      expect(result.healthIndex, closeTo(0.95, 0.001));
    });

    test('long compromised password costs 0.25', () {
      // 'welcome123' is 10 chars (not weak) but in the compromised list.
      final result = audit.analyze([_makeItem('Leaky', 'welcome123')]);
      expect(result.compromisedCount, 1);
      expect(result.healthIndex, closeTo(0.75, 0.001));
    });

    test('short breached password stacks weak + compromised', () {
      // '123456': weak-length (0.55) + compromised (0.25) = 0.80 penalty.
      final result = audit.analyze([_makeItem('Bad', '123456')]);
      expect(result.healthIndex, closeTo(0.20, 0.001));
      expect(result.isHealthy, isFalse);
    });

    test('fully weak vault stays below 0.5', () {
      final result = audit.analyze([
        _makeItem('A', 'ab'),
        _makeItem('B', 'cd'),
      ]);
      expect(result.healthIndex, closeTo(0.45, 0.001));
    });
  });
}
