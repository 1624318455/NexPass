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
      expect(result.issues.length, 1);
      expect(result.issues.first.severity, AuditSeverity.critical);
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
}
