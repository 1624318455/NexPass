import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/models/nex_item.dart';

void main() {
  group('NexItem', () {
    test('default type is Login (1)', () {
      final item = NexItem();
      expect(item.type, 1);
    });

    test('username getter returns username field value', () {
      final item = NexItem()
        ..fields = [
          NexField()..name = 'username'..value = 'alice@example.com',
          NexField()..name = 'password'..value = 'secret',
        ];
      expect(item.username, 'alice@example.com');
    });

    test('username getter returns empty when no username field', () {
      final item = NexItem()..fields = [];
      expect(item.username, '');
    });

    test('website getter matches "website" field (case-insensitive)', () {
      final item = NexItem()
        ..fields = [
          NexField()..name = 'Website'..value = 'https://example.com',
        ];
      expect(item.website, 'https://example.com');
    });

    test('website getter matches "url" field', () {
      final item = NexItem()
        ..fields = [
          NexField()..name = 'url'..value = 'https://test.com',
        ];
      expect(item.website, 'https://test.com');
    });

    test('website getter returns empty when no matching field', () {
      final item = NexItem()..fields = [];
      expect(item.website, '');
    });

    test('totpSecret returns value from totpSecret field', () {
      final item = NexItem()
        ..fields = [
          NexField()..name = 'totpSecret'..value = 'JBSWY3DPEHPK3PXP',
        ];
      expect(item.totpSecret, 'JBSWY3DPEHPK3PXP');
    });

    test('totpSecret returns value from fieldType 3 field', () {
      final item = NexItem()
        ..fields = [
          NexField()..name = 'otp'..fieldType = 3..value = 'SECRET123',
        ];
      expect(item.totpSecret, 'SECRET123');
    });

    test('hasTotp is true when totpSecret is non-empty', () {
      final item = NexItem()
        ..fields = [
          NexField()..name = 'totpSecret'..value = 'ABC123',
        ];
      expect(item.hasTotp, isTrue);
    });

    test('hasTotp is false when no totp field', () {
      final item = NexItem()..fields = [];
      expect(item.hasTotp, isFalse);
    });
  });

  group('NexField', () {
    test('default fieldType is 1 (Text)', () {
      final field = NexField();
      expect(field.fieldType, 1);
    });

    test('isSensitive defaults to false', () {
      final field = NexField();
      expect(field.isSensitive, isFalse);
    });

    test('decryptedValue is null by default', () {
      final field = NexField();
      expect(field.decryptedValue, isNull);
    });
  });
}
