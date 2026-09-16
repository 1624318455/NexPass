// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPasswordHistoryEntryCollection on Isar {
  IsarCollection<PasswordHistoryEntry> get passwordHistoryEntrys =>
      this.collection();
}

const PasswordHistoryEntrySchema = CollectionSchema(
  name: r'PasswordHistoryEntry',
  id: -903903681665683917,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'encryptedValue': PropertySchema(
      id: 1,
      name: r'encryptedValue',
      type: IsarType.string,
    ),
    r'itemUuid': PropertySchema(
      id: 2,
      name: r'itemUuid',
      type: IsarType.string,
    ),
    r'label': PropertySchema(
      id: 3,
      name: r'label',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 4,
      name: r'source',
      type: IsarType.string,
    )
  },
  estimateSize: _passwordHistoryEntryEstimateSize,
  serialize: _passwordHistoryEntrySerialize,
  deserialize: _passwordHistoryEntryDeserialize,
  deserializeProp: _passwordHistoryEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'itemUuid': IndexSchema(
      id: -647427939757351820,
      name: r'itemUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _passwordHistoryEntryGetId,
  getLinks: _passwordHistoryEntryGetLinks,
  attach: _passwordHistoryEntryAttach,
  version: '3.1.0+1',
);

int _passwordHistoryEntryEstimateSize(
  PasswordHistoryEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.encryptedValue.length * 3;
  {
    final value = object.itemUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.label.length * 3;
  bytesCount += 3 + object.source.length * 3;
  return bytesCount;
}

void _passwordHistoryEntrySerialize(
  PasswordHistoryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.encryptedValue);
  writer.writeString(offsets[2], object.itemUuid);
  writer.writeString(offsets[3], object.label);
  writer.writeString(offsets[4], object.source);
}

PasswordHistoryEntry _passwordHistoryEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PasswordHistoryEntry();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.encryptedValue = reader.readString(offsets[1]);
  object.id = id;
  object.itemUuid = reader.readStringOrNull(offsets[2]);
  object.label = reader.readString(offsets[3]);
  object.source = reader.readString(offsets[4]);
  return object;
}

P _passwordHistoryEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _passwordHistoryEntryGetId(PasswordHistoryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _passwordHistoryEntryGetLinks(
    PasswordHistoryEntry object) {
  return [];
}

void _passwordHistoryEntryAttach(
    IsarCollection<dynamic> col, Id id, PasswordHistoryEntry object) {
  object.id = id;
}

extension PasswordHistoryEntryQueryWhereSort
    on QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QWhere> {
  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension PasswordHistoryEntryQueryWhere
    on QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QWhereClause> {
  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      itemUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'itemUuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      itemUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'itemUuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      itemUuidEqualTo(String? itemUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'itemUuid',
        value: [itemUuid],
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      itemUuidNotEqualTo(String? itemUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemUuid',
              lower: [],
              upper: [itemUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemUuid',
              lower: [itemUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemUuid',
              lower: [itemUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemUuid',
              lower: [],
              upper: [itemUuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PasswordHistoryEntryQueryFilter on QueryBuilder<PasswordHistoryEntry,
    PasswordHistoryEntry, QFilterCondition> {
  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'encryptedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'encryptedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'encryptedValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'encryptedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'encryptedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      encryptedValueContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'encryptedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      encryptedValueMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'encryptedValue',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedValue',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> encryptedValueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'encryptedValue',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'itemUuid',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'itemUuid',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      itemUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      itemUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> itemUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
          QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry,
      QAfterFilterCondition> sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }
}

extension PasswordHistoryEntryQueryObject on QueryBuilder<PasswordHistoryEntry,
    PasswordHistoryEntry, QFilterCondition> {}

extension PasswordHistoryEntryQueryLinks on QueryBuilder<PasswordHistoryEntry,
    PasswordHistoryEntry, QFilterCondition> {}

extension PasswordHistoryEntryQuerySortBy
    on QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QSortBy> {
  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByEncryptedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedValue', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByEncryptedValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedValue', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByItemUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemUuid', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByItemUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemUuid', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }
}

extension PasswordHistoryEntryQuerySortThenBy
    on QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QSortThenBy> {
  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByEncryptedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedValue', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByEncryptedValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedValue', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByItemUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemUuid', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByItemUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemUuid', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }
}

extension PasswordHistoryEntryQueryWhereDistinct
    on QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QDistinct> {
  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QDistinct>
      distinctByEncryptedValue({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedValue',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QDistinct>
      distinctByItemUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QDistinct>
      distinctByLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PasswordHistoryEntry, PasswordHistoryEntry, QDistinct>
      distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }
}

extension PasswordHistoryEntryQueryProperty on QueryBuilder<
    PasswordHistoryEntry, PasswordHistoryEntry, QQueryProperty> {
  QueryBuilder<PasswordHistoryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PasswordHistoryEntry, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PasswordHistoryEntry, String, QQueryOperations>
      encryptedValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedValue');
    });
  }

  QueryBuilder<PasswordHistoryEntry, String?, QQueryOperations>
      itemUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemUuid');
    });
  }

  QueryBuilder<PasswordHistoryEntry, String, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<PasswordHistoryEntry, String, QQueryOperations>
      sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }
}
