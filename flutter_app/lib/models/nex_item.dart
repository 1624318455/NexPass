import 'package:isar/isar.dart';

part 'nex_item.g.dart';

@collection
class NexItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? uuid;

  String? vaultId;

  // 1 = Login, 2 = Card, 3 = Identity, 4 = Secure Note, 5 = TOTP
  @Index()
  int type = 1;

  @Index(type: IndexType.value, caseSensitive: false)
  String name = '';

  String? iconKey;

  // Embedded list representing dynamic schema values encrypted natively
  List<NexField> fields = [];

  List<String> tags = [];

  bool isFavorite = false;

  DateTime updatedAt = DateTime.now();

  DateTime? lastUsedAt;

  // Helper to quickly scan list of fields to fetch username
  String get username {
    final userField = fields.firstWhere(
      (f) => f.name == 'username',
      orElse: () => NexField()..value = '',
    );
    return userField.value;
  }

  String get website {
    final f = fields.firstWhere(
      (f) => f.name.toLowerCase() == 'website' || f.name.toLowerCase() == 'url',
      orElse: () => NexField()..value = '',
    );
    return f.value;
  }

  String get totpSecret {
    final f = fields.firstWhere(
      (f) => f.name == 'totpSecret' || f.fieldType == 3,
      orElse: () => NexField()..value = '',
    );
    return f.value;
  }

  bool get hasTotp => totpSecret.isNotEmpty;
}

@embedded
class NexField {
  String name = ''; // e.g. 'username', 'password', 'cardNumber', 'cvv', 'totpSecret'
  String value = '';

  // 1 = Text, 2 = Password, 3 = Hidden, 4 = TOTP, 5 = Date
  int fieldType = 1;

  bool isSensitive = false;

  @ignore
  String? decryptedValue;
}
