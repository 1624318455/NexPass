import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexpass/services/csv_import_service.dart';

void main() {
  late CsvImportService service;
  late Directory tempDir;

  setUp(() {
    service = CsvImportService();
    tempDir = Directory.systemTemp.createTempSync('csv_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<String> _writeCsv(String filename, String content) async {
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  // ── Format detection ─────────────────────────────────────────────────

  group('format detection', () {
    test('detects Bitwarden format (login_username header)', () async {
      final path = await _writeCsv('bw.csv',
          'name,login_username,login_password,login_uri\n'
          'GitHub,alice,pass123,https://github.com\n');
      final result = await service.importFromCsv(path);
      expect(result.format, CsvFormat.bitwarden);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'GitHub');
    });

    test('detects KeePass format (group + title headers)', () async {
      final path = await _writeCsv('kp.csv',
          'group,title,username,password,url,notes\n'
          'Email,Gmail,user@gmail.com,secret123,https://gmail.com,my notes\n');
      final result = await service.importFromCsv(path);
      expect(result.format, CsvFormat.keepass);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Gmail');
    });

    test('falls back to generic format', () async {
      final path = await _writeCsv('gen.csv',
          'Website,Login,Secret\n'
          'example.com,admin,12345\n');
      final result = await service.importFromCsv(path);
      expect(result.format, CsvFormat.generic);
      expect(result.items.length, 1);
    });
  });

  // ── Bitwarden parsing ────────────────────────────────────────────────

  group('Bitwarden parsing', () {
    test('parses multiple rows', () async {
      final path = await _writeCsv('multi.csv',
          'name,login_username,login_password,login_uri\n'
          'GitHub,alice,pass1,https://github.com\n'
          'GitLab,bob,pass2,https://gitlab.com\n');
      final result = await service.importFromCsv(path);
      expect(result.items.length, 2);
      expect(result.items[0].name, 'GitHub');
      expect(result.items[1].name, 'GitLab');
    });

    test('creates correct field structure', () async {
      final path = await _writeCsv('fields.csv',
          'name,login_username,login_password,login_uri\n'
          'Test,user@test.com,mypass123,https://test.com\n');
      final result = await service.importFromCsv(path);
      final item = result.items.first;

      // Should have 3 fields: username, password, website
      expect(item.fields.length, 3);

      final usernameField = item.fields.firstWhere((f) => f.name == 'username');
      expect(usernameField.value, 'user@test.com');
      expect(usernameField.isSensitive, isFalse);

      final passwordField = item.fields.firstWhere((f) => f.name == 'password');
      expect(passwordField.value, 'mypass123');
      expect(passwordField.isSensitive, isTrue);
      expect(passwordField.fieldType, 2); // Password type
    });

    test('skips rows with empty name and password', () async {
      final path = await _writeCsv('skip.csv',
          'name,login_username,login_password\n'
          'Valid,user,pass\n'
          ',,\n');
      final result = await service.importFromCsv(path);
      expect(result.items.length, 1);
    });
  });

  // ── KeePass parsing ──────────────────────────────────────────────────

  group('KeePass parsing', () {
    test('parses all fields including notes', () async {
      final path = await _writeCsv('kp_full.csv',
          'group,title,username,password,url,notes\n'
          'Social,Twitter,alice,secret123,https://twitter.com,my twitter notes\n');
      final result = await service.importFromCsv(path);
      final item = result.items.first;

      expect(item.name, 'Twitter');
      // username, password, website, notes = 4 fields
      expect(item.fields.length, 4);

      final notesField = item.fields.firstWhere((f) => f.name == 'notes');
      expect(notesField.value, 'my twitter notes');
    });

    test('omits empty url and notes fields', () async {
      final path = await _writeCsv('kp_no_url.csv',
          'group,title,username,password,url,notes\n'
          'App,Simple,user,pass,,\n');
      final result = await service.importFromCsv(path);
      final item = result.items.first;
      // Only username + password (url and notes are empty → omitted)
      expect(item.fields.length, 2);
    });
  });

  // ── Generic parsing ──────────────────────────────────────────────────

  group('Generic parsing', () {
    test('matches common column names', () async {
      final path = await _writeCsv('gen_cols.csv',
          'Site Name,Email Address,Password\n'
          'Example,admin@example.com,secret\n');
      final result = await service.importFromCsv(path);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Example');
    });

    test('falls back to positional columns when headers do not match', () async {
      final path = await _writeCsv('gen_pos.csv',
          'Col1,Col2,Col3\n'
          'MySite,admin@example.com,pass123\n');
      final result = await service.importFromCsv(path);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'MySite');
    });
  });

  // ── CSV edge cases ───────────────────────────────────────────────────

  group('edge cases', () {
    test('empty file returns empty result', () async {
      final path = await _writeCsv('empty.csv', '');
      final result = await service.importFromCsv(path);
      expect(result.items, isEmpty);
    });

    test('header-only file returns empty result', () async {
      final path = await _writeCsv('header.csv', 'name,password\n');
      final result = await service.importFromCsv(path);
      expect(result.items, isEmpty);
    });

    test('handles quoted fields with commas', () async {
      final path = await _writeCsv('quoted.csv',
          'name,login_username,login_password\n'
          '"My, Site",user,"p@ss,word"\n');
      final result = await service.importFromCsv(path);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'My, Site');
      final pw = result.items.first.fields
          .firstWhere((f) => f.name == 'password');
      expect(pw.value, 'p@ss,word');
    });

    test('handles escaped quotes inside quoted fields', () async {
      final path = await _writeCsv('esc.csv',
          'name,login_username,login_password\n'
          '"He said ""hi""",user,pass123\n');
      final result = await service.importFromCsv(path);
      expect(result.items.first.name, 'He said "hi"');
    });

    test('handles Windows line endings (CRLF)', () async {
      final path = await _writeCsv('crlf.csv',
          'name,login_username,login_password\r\n'
          'Test,user,pass123\r\n');
      final result = await service.importFromCsv(path);
      expect(result.items.length, 1);
    });

    test('each item gets a unique UUID', () async {
      final path = await _writeCsv('uuids.csv',
          'name,login_username,login_password\n'
          'A,u1,p1\nB,u2,p2\nC,u3,p3\n');
      final result = await service.importFromCsv(path);
      final uuids = result.items.map((i) => i.uuid).toSet();
      expect(uuids.length, 3);
    });
  });
}
