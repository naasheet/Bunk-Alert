// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_entry_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimetableEntryModelCollection on Isar {
  IsarCollection<TimetableEntryModel> get timetableEntryModels =>
      this.collection();
}

const TimetableEntryModelSchema = CollectionSchema(
  name: r'TimetableEntryModel',
  id: 1058384723686368217,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dayOfWeek': PropertySchema(
      id: 1,
      name: r'dayOfWeek',
      type: IsarType.long,
    ),
    r'endMinutes': PropertySchema(
      id: 2,
      name: r'endMinutes',
      type: IsarType.long,
    ),
    r'isActive': PropertySchema(
      id: 3,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'startMinutes': PropertySchema(
      id: 4,
      name: r'startMinutes',
      type: IsarType.long,
    ),
    r'subjectUuid': PropertySchema(
      id: 5,
      name: r'subjectUuid',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 6,
      name: r'syncStatus',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 7,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _timetableEntryModelEstimateSize,
  serialize: _timetableEntryModelSerialize,
  deserialize: _timetableEntryModelDeserialize,
  deserializeProp: _timetableEntryModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'subjectUuid': IndexSchema(
      id: -630854241714589217,
      name: r'subjectUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'subjectUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'dayOfWeek': IndexSchema(
      id: -5516657708462385134,
      name: r'dayOfWeek',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dayOfWeek',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _timetableEntryModelGetId,
  getLinks: _timetableEntryModelGetLinks,
  attach: _timetableEntryModelAttach,
  version: '3.1.0+1',
);

int _timetableEntryModelEstimateSize(
  TimetableEntryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.subjectUuid.length * 3;
  bytesCount += 3 + object.syncStatus.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _timetableEntryModelSerialize(
  TimetableEntryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.dayOfWeek);
  writer.writeLong(offsets[2], object.endMinutes);
  writer.writeBool(offsets[3], object.isActive);
  writer.writeLong(offsets[4], object.startMinutes);
  writer.writeString(offsets[5], object.subjectUuid);
  writer.writeString(offsets[6], object.syncStatus);
  writer.writeString(offsets[7], object.uuid);
}

TimetableEntryModel _timetableEntryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimetableEntryModel(
    createdAt: reader.readDateTime(offsets[0]),
    dayOfWeek: reader.readLong(offsets[1]),
    endMinutes: reader.readLong(offsets[2]),
    isActive: reader.readBoolOrNull(offsets[3]) ?? true,
    startMinutes: reader.readLong(offsets[4]),
    subjectUuid: reader.readString(offsets[5]),
    syncStatus: reader.readStringOrNull(offsets[6]) ?? 'pending',
    uuid: reader.readString(offsets[7]),
  );
  object.id = id;
  return object;
}

P _timetableEntryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset) ?? 'pending') as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _timetableEntryModelGetId(TimetableEntryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timetableEntryModelGetLinks(
    TimetableEntryModel object) {
  return [];
}

void _timetableEntryModelAttach(
    IsarCollection<dynamic> col, Id id, TimetableEntryModel object) {
  object.id = id;
}

extension TimetableEntryModelByIndex on IsarCollection<TimetableEntryModel> {
  Future<TimetableEntryModel?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  TimetableEntryModel? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<TimetableEntryModel?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<TimetableEntryModel?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(TimetableEntryModel object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(TimetableEntryModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<TimetableEntryModel> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<TimetableEntryModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension TimetableEntryModelQueryWhereSort
    on QueryBuilder<TimetableEntryModel, TimetableEntryModel, QWhere> {
  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhere>
      anyDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dayOfWeek'),
      );
    });
  }
}

extension TimetableEntryModelQueryWhere
    on QueryBuilder<TimetableEntryModel, TimetableEntryModel, QWhereClause> {
  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      subjectUuidEqualTo(String subjectUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'subjectUuid',
        value: [subjectUuid],
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      subjectUuidNotEqualTo(String subjectUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectUuid',
              lower: [],
              upper: [subjectUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectUuid',
              lower: [subjectUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectUuid',
              lower: [subjectUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectUuid',
              lower: [],
              upper: [subjectUuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      dayOfWeekEqualTo(int dayOfWeek) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dayOfWeek',
        value: [dayOfWeek],
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      dayOfWeekNotEqualTo(int dayOfWeek) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayOfWeek',
              lower: [],
              upper: [dayOfWeek],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayOfWeek',
              lower: [dayOfWeek],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayOfWeek',
              lower: [dayOfWeek],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayOfWeek',
              lower: [],
              upper: [dayOfWeek],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      dayOfWeekGreaterThan(
    int dayOfWeek, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dayOfWeek',
        lower: [dayOfWeek],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      dayOfWeekLessThan(
    int dayOfWeek, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dayOfWeek',
        lower: [],
        upper: [dayOfWeek],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterWhereClause>
      dayOfWeekBetween(
    int lowerDayOfWeek,
    int upperDayOfWeek, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dayOfWeek',
        lower: [lowerDayOfWeek],
        includeLower: includeLower,
        upper: [upperDayOfWeek],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimetableEntryModelQueryFilter on QueryBuilder<TimetableEntryModel,
    TimetableEntryModel, QFilterCondition> {
  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      dayOfWeekEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      dayOfWeekGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      dayOfWeekLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      dayOfWeekBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayOfWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      endMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      endMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      endMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      endMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      startMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      startMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      startMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      startMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subjectUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subjectUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subjectUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subjectUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subjectUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subjectUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subjectUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subjectUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subjectUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      subjectUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subjectUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      syncStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension TimetableEntryModelQueryObject on QueryBuilder<TimetableEntryModel,
    TimetableEntryModel, QFilterCondition> {}

extension TimetableEntryModelQueryLinks on QueryBuilder<TimetableEntryModel,
    TimetableEntryModel, QFilterCondition> {}

extension TimetableEntryModelQuerySortBy
    on QueryBuilder<TimetableEntryModel, TimetableEntryModel, QSortBy> {
  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortBySubjectUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectUuid', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortBySubjectUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectUuid', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension TimetableEntryModelQuerySortThenBy
    on QueryBuilder<TimetableEntryModel, TimetableEntryModel, QSortThenBy> {
  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenBySubjectUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectUuid', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenBySubjectUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectUuid', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension TimetableEntryModelQueryWhereDistinct
    on QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct> {
  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfWeek');
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endMinutes');
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMinutes');
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctBySubjectUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subjectUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctBySyncStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimetableEntryModel, TimetableEntryModel, QDistinct>
      distinctByUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension TimetableEntryModelQueryProperty
    on QueryBuilder<TimetableEntryModel, TimetableEntryModel, QQueryProperty> {
  QueryBuilder<TimetableEntryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimetableEntryModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TimetableEntryModel, int, QQueryOperations> dayOfWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfWeek');
    });
  }

  QueryBuilder<TimetableEntryModel, int, QQueryOperations>
      endMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endMinutes');
    });
  }

  QueryBuilder<TimetableEntryModel, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<TimetableEntryModel, int, QQueryOperations>
      startMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMinutes');
    });
  }

  QueryBuilder<TimetableEntryModel, String, QQueryOperations>
      subjectUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subjectUuid');
    });
  }

  QueryBuilder<TimetableEntryModel, String, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<TimetableEntryModel, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
