import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/nex_item.dart';

enum CsvFormat { bitwarden, keepass, generic }

class CsvImportResult {
  final CsvFormat format;
  final List<NexItem> items;

  const CsvImportResult({required this.format, required this.items});
}

class CsvImportService {
  static const _uuid = Uuid();

  /// Parse a CSV file and return NexItems.
  Future<CsvImportResult> importFromCsv(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();

    if (lines.length < 2) {
      return const CsvImportResult(format: CsvFormat.generic, items: []);
    }

    final header = _parseCsvLine(lines[0]);
    final format = _detectFormat(header);
    final items = <NexItem>[];

    for (int i = 1; i < lines.length; i++) {
      final fields = _parseCsvLine(lines[i]);
      if (fields.isEmpty) continue;

      final item = _rowToItem(fields, header, format);
      if (item != null) items.add(item);
    }

    return CsvImportResult(format: format, items: items);
  }

  CsvFormat _detectFormat(List<String> header) {
    final lower = header.map((h) => h.toLowerCase()).toList();
    if (lower.contains('login_username') || lower.contains('login_password')) {
      return CsvFormat.bitwarden;
    }
    if (lower.contains('group') && lower.contains('title')) {
      return CsvFormat.keepass;
    }
    return CsvFormat.generic;
  }

  NexItem? _rowToItem(List<String> fields, List<String> header, CsvFormat format) {
    switch (format) {
      case CsvFormat.bitwarden:
        return _bitwardenRow(fields, header);
      case CsvFormat.keepass:
        return _keepassRow(fields, header);
      case CsvFormat.generic:
        return _genericRow(fields, header);
    }
  }

  NexItem? _bitwardenRow(List<String> fields, List<String> header) {
    String name = '', username = '', password = '', uri = '';

    for (int i = 0; i < header.length && i < fields.length; i++) {
      final h = header[i].toLowerCase();
      final v = fields[i];
      if (h == 'name') name = v;
      else if (h == 'login_username') username = v;
      else if (h == 'login_password') password = v;
      else if (h == 'login_uri') uri = v;
    }

    if (name.isEmpty && password.isEmpty) return null;

    final itemFields = <NexField>[
      _makeField('username', username, 1, false),
      _makeField('password', password, 2, true),
    ];
    if (uri.isNotEmpty) {
      itemFields.add(_makeField('website', uri, 5, false));
    }

    return NexItem()
      ..uuid = _uuid.v4()
      ..name = name
      ..type = 1
      ..fields = itemFields
      ..updatedAt = DateTime.now();
  }

  NexItem? _keepassRow(List<String> fields, List<String> header) {
    String title = '', username = '', password = '', url = '', notes = '';

    for (int i = 0; i < header.length && i < fields.length; i++) {
      final h = header[i].toLowerCase();
      final v = fields[i];
      if (h == 'title') title = v;
      else if (h == 'username') username = v;
      else if (h == 'password') password = v;
      else if (h == 'url') url = v;
      else if (h == 'notes') notes = v;
    }

    if (title.isEmpty && password.isEmpty) return null;

    final itemFields = <NexField>[
      _makeField('username', username, 1, false),
      _makeField('password', password, 2, true),
    ];
    if (url.isNotEmpty) {
      itemFields.add(_makeField('website', url, 5, false));
    }
    if (notes.isNotEmpty) {
      itemFields.add(_makeField('notes', notes, 3, false));
    }

    return NexItem()
      ..uuid = _uuid.v4()
      ..name = title
      ..type = 1
      ..fields = itemFields
      ..updatedAt = DateTime.now();
  }

  NexItem? _genericRow(List<String> fields, List<String> header) {
    // Try to find name and password columns by common names
    String name = '', username = '', password = '';

    for (int i = 0; i < header.length && i < fields.length; i++) {
      final h = header[i].toLowerCase();
      final v = fields[i];
      if (h.contains('name') || h.contains('title')) name = v;
      else if (h.contains('user') || h.contains('email') || h.contains('login')) username = v;
      else if (h.contains('pass') || h.contains('secret')) password = v;
    }

    // Fallback: if no header match, use first 3 columns
    if (name.isEmpty && fields.isNotEmpty) name = fields[0];
    if (username.isEmpty && fields.length > 1) username = fields[1];
    if (password.isEmpty && fields.length > 2) password = fields[2];

    if (name.isEmpty && password.isEmpty) return null;

    final itemFields = <NexField>[
      _makeField('username', username, 1, false),
      _makeField('password', password, 2, true),
    ];

    return NexItem()
      ..uuid = _uuid.v4()
      ..name = name
      ..type = 1
      ..fields = itemFields
      ..updatedAt = DateTime.now();
  }

  NexField _makeField(String name, String value, int fieldType, bool sensitive) {
    return NexField()
      ..name = name
      ..value = value
      ..fieldType = fieldType
      ..isSensitive = sensitive;
  }

  /// Simple CSV line parser handling quoted fields.
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else if (c == '"') {
          inQuotes = false;
        } else {
          buffer.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          result.add(buffer.toString().trim());
          buffer.clear();
        } else {
          buffer.write(c);
        }
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }
}
