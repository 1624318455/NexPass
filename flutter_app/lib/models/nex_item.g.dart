// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// IsarGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nex_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file

// GENERATED CODE - DO NOT MODIFY BY HAND
// **************************************************************************
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, unused_import

// **************************************************************************
// IsarContentGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_local_identifiers

// **************************************************************************
// IsarGenerator
// **************************************************************************

final NexItemSchema = CollectionSchema(
  name: 'NexItem',
  id: const IzarObjectId([-102, -33, 78, -93, -89, -43, -93, 96]),
  properties: [
    IsarPropertySchema(
      name: 'uuid',
      type: IsarType.string,
    ),
    IsarPropertySchema(
      name: 'vaultId',
      type: IsarType.string,
    ),
    IsarPropertySchema(
      name: 'type',
      type: IsarType.long,
    ),
    IsarPropertySchema(
      name: 'name',
      type: IsarType.string,
    ),
    IsarPropertySchema(
      name: 'iconKey',
      type: IsarType.string,
    ),
    IsarPropertySchema(
      name: 'tags',
      type: IsarType.stringList,
    ),
    IsarPropertySchema(
      name: 'isFavorite',
      type: IsarType.bool,
    ),
    IsarPropertySchema(
      name: 'updatedAt',
      type: IsarType.dateTime,
    ),
    IsarPropertySchema(
      name: 'fields',
      type: IsarType.objectList,
      target: 'NexField',
    ),
  ],
  estimateSize: _nexItemEstimateSize,
  serialize: _nexItemSerialize,
  deserialize: _nexItemDeserialize,
  deserializeProp: _nexItemDeserializeProp,
  idName: 'id',
  links: [],
  embeddedSchemas: [NexFieldSchema],
  getId: _nexItemGetId,
  setId: _nexItemSetId,
  attach: _nexItemAttach,
  version: 3,
);

IzarType _nexItemEstimateSize(
  NexItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.uuid!.length * 3;
  bytesCount += 3 + (object.vaultId?.length ?? 0) * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + (object.iconKey?.length ?? 0) * 3;
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      bytesCount += 3 + object.tags[i].length * 3;
    }
  }
  bytesCount += 3 + object.fields.length * 3;
  {
    final offsets = allOffsets[NexField]!;
    for (var i = 0; i < object.fields.length; i++) {
      bytesCount += NexFieldSchema.estimateSize(
          object.fields[i], offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _nexItemSerialize(
  NexItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.uuid);
  writer.writeString(offsets[1], object.vaultId);
  writer.writeLong(offsets[2], object.type);
  writer.writeString(offsets[3], object.name);
  writer.writeString(offsets[4], object.iconKey);
  writer.writeStringList(offsets[5], object.tags);
  writer.writeBool(offsets[6], object.isFavorite);
  writer.writeDateTime(offsets[7], object.updatedAt);
  writer.writeObjectList<NexField>(
    offsets[8],
    allOffsets,
    NexFieldSchema.serialize,
    object.fields,
  );
}

NexItem _nexItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NexItem();
  object.id = id;
  object.uuid = reader.readStringOrNull(offsets[0]);
  object.vaultId = reader.readStringOrNull(offsets[1]);
  object.type = reader.readLong(offsets[2]);
  object.name = reader.readString(offsets[3]);
  object.iconKey = reader.readStringOrNull(offsets[4]);
  object.tags = reader.readStringList(offsets[5]) ?? [];
  object.isFavorite = reader.readBool(offsets[6]);
  object.updatedAt = reader.readDateTime(offsets[7]);
  object.fields = reader.readObjectList<NexField>(
        offsets[8],
        NexFieldSchema.deserialize,
        allOffsets,
      ) ??
      [];
  return object;
}

P _nexItemDeserializeProp<P>(
  int id,
  IsarReader reader,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (offset) {
    case -1:
      return id as P;
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readObjectList<NexField>(
            offset,
            NexFieldSchema.deserialize,
            allOffsets,
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $id');
  }
}

Id _nexItemGetId(NexItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _nexItemLinks(NexItem object) {
  return [];
}

void _nexItemAttach(Id id, NexItem object) {
  object.id = id;
}

extension NexItemQuerySortBy on QueryBuilder<NexItem, NexItem, QSortBy> {
  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByUuid() {
    return queryBySort(0, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByUuidDesc() {
    return queryBySort(0, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByVaultId() {
    return queryBySort(1, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByVaultIdDesc() {
    return queryBySort(1, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByType() {
    return queryBySort(2, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByTypeDesc() {
    return queryBySort(2, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByName() {
    return queryBySort(3, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByNameDesc() {
    return queryBySort(3, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByIsFavorite() {
    return queryBySort(6, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByIsFavoriteDesc() {
    return queryBySort(6, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByUpdatedAt() {
    return queryBySort(7, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> sortByUpdatedAtDesc() {
    return queryBySort(7, Sort.desc);
  }
}

extension NexItemQuerySortThenBy
    on QueryBuilder<NexItem, NexItem, QSortThenBy> {
  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByUuid() {
    return queryByThenSort(0, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByUuidDesc() {
    return queryByThenSort(0, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByVaultId() {
    return queryByThenSort(1, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByVaultIdDesc() {
    return queryByThenSort(1, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByType() {
    return queryByThenSort(2, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByTypeDesc() {
    return queryByThenSort(2, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByName() {
    return queryByThenSort(3, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByNameDesc() {
    return queryByThenSort(3, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByIsFavorite() {
    return queryByThenSort(6, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByIsFavoriteDesc() {
    return queryByThenSort(6, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByUpdatedAt() {
    return queryByThenSort(7, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByUpdatedAtDesc() {
    return queryByThenSort(7, Sort.desc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenById() {
    return queryByThenSort(-1, Sort.asc);
  }

  QueryBuilder<NexItem, NexItem, QAfterSortBy> thenByIdDesc() {
    return queryByThenSort(-1, Sort.desc);
  }
}

extension NexItemQueryWhereDistinct
    on QueryBuilder<NexItem, NexItem, QDistinct> {
  QueryBuilder<NexItem, NexItem, QDistinct> distinctByUuid({bool caseSensitive = true}) {
    return queryByDistinct(0, caseSensitive: caseSensitive);
  }

  QueryBuilder<NexItem, NexItem, QDistinct> distinctByVaultId({bool caseSensitive = true}) {
    return queryByDistinct(1, caseSensitive: caseSensitive);
  }

  QueryBuilder<NexItem, NexItem, QDistinct> distinctByType() {
    return queryByDistinct(2);
  }

  QueryBuilder<NexItem, NexItem, QDistinct> distinctByName({bool caseSensitive = true}) {
    return queryByDistinct(3, caseSensitive: caseSensitive);
  }

  QueryBuilder<NexItem, NexItem, QDistinct> distinctByIsFavorite() {
    return queryByDistinct(6);
  }

  QueryBuilder<NexItem, NexItem, QDistinct> distinctByUpdatedAt() {
    return queryByDistinct(7);
  }
}

extension NexItemQueryProperty
    on QueryBuilder<NexItem, NexItem, QQueryProperty> {
  QueryBuilder<NexItem, String?, QQueryOperations> uuidProperty() {
    return queryByProperty(0);
  }

  QueryBuilder<NexItem, String?, QQueryOperations> vaultIdProperty() {
    return queryByProperty(1);
  }

  QueryBuilder<NexItem, int, QQueryOperations> typeProperty() {
    return queryByProperty(2);
  }

  QueryBuilder<NexItem, String, QQueryOperations> nameProperty() {
    return queryByProperty(3);
  }

  QueryBuilder<NexItem, String?, QQueryOperations> iconKeyProperty() {
    return queryByProperty(4);
  }

  QueryBuilder<NexItem, List<String>, QQueryOperations> tagsProperty() {
    return queryByProperty(5);
  }

  QueryBuilder<NexItem, bool, QQueryOperations> isFavoriteProperty() {
    return queryByProperty(6);
  }

  QueryBuilder<NexItem, DateTime, QQueryOperations> updatedAtProperty() {
    return queryByProperty(7);
  }

  QueryBuilder<NexItem, List<NexField>, QQueryOperations> fieldsProperty() {
    return queryByProperty(8);
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

final NexFieldSchema = EmbededSchema(
  name: 'NexField',
  properties: [
    IsarPropertySchema(
      name: 'name',
      type: IsarType.string,
    ),
    IsarPropertySchema(
      name: 'value',
      type: IsarType.string,
    ),
    IsarPropertySchema(
      name: 'fieldType',
      type: IsarType.long,
    ),
    IsarPropertySchema(
      name: 'isSensitive',
      type: IsarType.bool,
    ),
  ],
  serialize: _nexFieldSerialize,
  deserialize: _nexFieldDeserialize,
  deserializeProp: _nexFieldDeserializeProp,
);

void _nexFieldSerialize(
  NexField object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.name);
  writer.writeString(offsets[1], object.value);
  writer.writeLong(offsets[2], object.fieldType);
  writer.writeBool(offsets[3], object.isSensitive);
}

NexField _nexFieldDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NexField();
  object.name = reader.readString(offsets[0]);
  object.value = reader.readString(offsets[1]);
  object.fieldType = reader.readLong(offsets[2]);
  object.isSensitive = reader.readBool(offsets[3]);
  return object;
}

P _nexFieldDeserializeProp<P>(
  int id,
  IsarReader reader,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (offset) {
    case -1:
      return id as P;
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $id');
  }
}

extension NexFieldQueryFilter
    on QueryBuilder<NexField, NexField, QFilterCondition> {
  QueryBuilder<NexField, NexField, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return queryBuilder(qBuilder, (q) {
      return q.filter(
        FilterCondition.equalTo(
          property: 0,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }
}
