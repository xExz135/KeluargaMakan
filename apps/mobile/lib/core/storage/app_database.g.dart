// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedHouseholdsTable extends CachedHouseholds
    with TableInfo<$CachedHouseholdsTable, CachedHousehold> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedHouseholdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _managerAccountIdMeta = const VerificationMeta(
    'managerAccountId',
  );
  @override
  late final GeneratedColumn<String> managerAccountId = GeneratedColumn<String>(
    'manager_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _managerProfileIdMeta = const VerificationMeta(
    'managerProfileId',
  );
  @override
  late final GeneratedColumn<String> managerProfileId = GeneratedColumn<String>(
    'manager_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    city,
    timeZone,
    language,
    managerAccountId,
    managerProfileId,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_households';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedHousehold> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timeZoneMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('manager_account_id')) {
      context.handle(
        _managerAccountIdMeta,
        managerAccountId.isAcceptableOrUnknown(
          data['manager_account_id']!,
          _managerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_managerAccountIdMeta);
    }
    if (data.containsKey('manager_profile_id')) {
      context.handle(
        _managerProfileIdMeta,
        managerProfileId.isAcceptableOrUnknown(
          data['manager_profile_id']!,
          _managerProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_managerProfileIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedHousehold map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedHousehold(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      managerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manager_account_id'],
      )!,
      managerProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manager_profile_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedHouseholdsTable createAlias(String alias) {
    return $CachedHouseholdsTable(attachedDatabase, alias);
  }
}

class CachedHousehold extends DataClass implements Insertable<CachedHousehold> {
  final String id;
  final String? name;
  final String? city;

  /// IANA name as the API sent it.
  final String timeZone;

  /// Contract `Language` wire value.
  final String language;
  final String managerAccountId;
  final String managerProfileId;
  final DateTime updatedAt;
  final DateTime cachedAt;
  const CachedHousehold({
    required this.id,
    this.name,
    this.city,
    required this.timeZone,
    required this.language,
    required this.managerAccountId,
    required this.managerProfileId,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    map['time_zone'] = Variable<String>(timeZone);
    map['language'] = Variable<String>(language);
    map['manager_account_id'] = Variable<String>(managerAccountId);
    map['manager_profile_id'] = Variable<String>(managerProfileId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedHouseholdsCompanion toCompanion(bool nullToAbsent) {
    return CachedHouseholdsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      timeZone: Value(timeZone),
      language: Value(language),
      managerAccountId: Value(managerAccountId),
      managerProfileId: Value(managerProfileId),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedHousehold.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedHousehold(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      city: serializer.fromJson<String?>(json['city']),
      timeZone: serializer.fromJson<String>(json['timeZone']),
      language: serializer.fromJson<String>(json['language']),
      managerAccountId: serializer.fromJson<String>(json['managerAccountId']),
      managerProfileId: serializer.fromJson<String>(json['managerProfileId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'city': serializer.toJson<String?>(city),
      'timeZone': serializer.toJson<String>(timeZone),
      'language': serializer.toJson<String>(language),
      'managerAccountId': serializer.toJson<String>(managerAccountId),
      'managerProfileId': serializer.toJson<String>(managerProfileId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedHousehold copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> city = const Value.absent(),
    String? timeZone,
    String? language,
    String? managerAccountId,
    String? managerProfileId,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => CachedHousehold(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    city: city.present ? city.value : this.city,
    timeZone: timeZone ?? this.timeZone,
    language: language ?? this.language,
    managerAccountId: managerAccountId ?? this.managerAccountId,
    managerProfileId: managerProfileId ?? this.managerProfileId,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedHousehold copyWithCompanion(CachedHouseholdsCompanion data) {
    return CachedHousehold(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      city: data.city.present ? data.city.value : this.city,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      language: data.language.present ? data.language.value : this.language,
      managerAccountId: data.managerAccountId.present
          ? data.managerAccountId.value
          : this.managerAccountId,
      managerProfileId: data.managerProfileId.present
          ? data.managerProfileId.value
          : this.managerProfileId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedHousehold(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('city: $city, ')
          ..write('timeZone: $timeZone, ')
          ..write('language: $language, ')
          ..write('managerAccountId: $managerAccountId, ')
          ..write('managerProfileId: $managerProfileId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    city,
    timeZone,
    language,
    managerAccountId,
    managerProfileId,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedHousehold &&
          other.id == this.id &&
          other.name == this.name &&
          other.city == this.city &&
          other.timeZone == this.timeZone &&
          other.language == this.language &&
          other.managerAccountId == this.managerAccountId &&
          other.managerProfileId == this.managerProfileId &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedHouseholdsCompanion extends UpdateCompanion<CachedHousehold> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> city;
  final Value<String> timeZone;
  final Value<String> language;
  final Value<String> managerAccountId;
  final Value<String> managerProfileId;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedHouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.city = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.language = const Value.absent(),
    this.managerAccountId = const Value.absent(),
    this.managerProfileId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedHouseholdsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.city = const Value.absent(),
    required String timeZone,
    required String language,
    required String managerAccountId,
    required String managerProfileId,
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timeZone = Value(timeZone),
       language = Value(language),
       managerAccountId = Value(managerAccountId),
       managerProfileId = Value(managerProfileId),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<CachedHousehold> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? city,
    Expression<String>? timeZone,
    Expression<String>? language,
    Expression<String>? managerAccountId,
    Expression<String>? managerProfileId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (city != null) 'city': city,
      if (timeZone != null) 'time_zone': timeZone,
      if (language != null) 'language': language,
      if (managerAccountId != null) 'manager_account_id': managerAccountId,
      if (managerProfileId != null) 'manager_profile_id': managerProfileId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedHouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? city,
    Value<String>? timeZone,
    Value<String>? language,
    Value<String>? managerAccountId,
    Value<String>? managerProfileId,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedHouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      timeZone: timeZone ?? this.timeZone,
      language: language ?? this.language,
      managerAccountId: managerAccountId ?? this.managerAccountId,
      managerProfileId: managerProfileId ?? this.managerProfileId,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (managerAccountId.present) {
      map['manager_account_id'] = Variable<String>(managerAccountId.value);
    }
    if (managerProfileId.present) {
      map['manager_profile_id'] = Variable<String>(managerProfileId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedHouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('city: $city, ')
          ..write('timeZone: $timeZone, ')
          ..write('language: $language, ')
          ..write('managerAccountId: $managerAccountId, ')
          ..write('managerProfileId: $managerProfileId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageGroupMeta = const VerificationMeta(
    'ageGroup',
  );
  @override
  late final GeneratedColumn<String> ageGroup = GeneratedColumn<String>(
    'age_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isChildMeta = const VerificationMeta(
    'isChild',
  );
  @override
  late final GeneratedColumn<bool> isChild = GeneratedColumn<bool>(
    'is_child',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_child" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isManagerMeta = const VerificationMeta(
    'isManager',
  );
  @override
  late final GeneratedColumn<bool> isManager = GeneratedColumn<bool>(
    'is_manager',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manager" IN (0, 1))',
    ),
  );
  static const VerificationMeta _avatarStyleMeta = const VerificationMeta(
    'avatarStyle',
  );
  @override
  late final GeneratedColumn<String> avatarStyle = GeneratedColumn<String>(
    'avatar_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarColorTokenMeta = const VerificationMeta(
    'avatarColorToken',
  );
  @override
  late final GeneratedColumn<String> avatarColorToken = GeneratedColumn<String>(
    'avatar_color_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarIllustrationIdMeta =
      const VerificationMeta('avatarIllustrationId');
  @override
  late final GeneratedColumn<String> avatarIllustrationId =
      GeneratedColumn<String>(
        'avatar_illustration_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    position,
    name,
    ageGroup,
    isChild,
    isManager,
    avatarStyle,
    avatarColorToken,
    avatarIllustrationId,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('age_group')) {
      context.handle(
        _ageGroupMeta,
        ageGroup.isAcceptableOrUnknown(data['age_group']!, _ageGroupMeta),
      );
    } else if (isInserting) {
      context.missing(_ageGroupMeta);
    }
    if (data.containsKey('is_child')) {
      context.handle(
        _isChildMeta,
        isChild.isAcceptableOrUnknown(data['is_child']!, _isChildMeta),
      );
    } else if (isInserting) {
      context.missing(_isChildMeta);
    }
    if (data.containsKey('is_manager')) {
      context.handle(
        _isManagerMeta,
        isManager.isAcceptableOrUnknown(data['is_manager']!, _isManagerMeta),
      );
    } else if (isInserting) {
      context.missing(_isManagerMeta);
    }
    if (data.containsKey('avatar_style')) {
      context.handle(
        _avatarStyleMeta,
        avatarStyle.isAcceptableOrUnknown(
          data['avatar_style']!,
          _avatarStyleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avatarStyleMeta);
    }
    if (data.containsKey('avatar_color_token')) {
      context.handle(
        _avatarColorTokenMeta,
        avatarColorToken.isAcceptableOrUnknown(
          data['avatar_color_token']!,
          _avatarColorTokenMeta,
        ),
      );
    }
    if (data.containsKey('avatar_illustration_id')) {
      context.handle(
        _avatarIllustrationIdMeta,
        avatarIllustrationId.isAcceptableOrUnknown(
          data['avatar_illustration_id']!,
          _avatarIllustrationIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ageGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_group'],
      )!,
      isChild: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_child'],
      )!,
      isManager: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manager'],
      )!,
      avatarStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_style'],
      )!,
      avatarColorToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_color_token'],
      ),
      avatarIllustrationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_illustration_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String id;

  /// Order from the API (manager first).
  final int position;
  final String name;

  /// Contract `AgeGroup` wire value.
  final String ageGroup;
  final bool isChild;
  final bool isManager;

  /// Contract `AvatarStyle` wire value.
  final String avatarStyle;
  final String? avatarColorToken;
  final String? avatarIllustrationId;
  final DateTime updatedAt;
  final DateTime cachedAt;
  const CachedProfile({
    required this.id,
    required this.position,
    required this.name,
    required this.ageGroup,
    required this.isChild,
    required this.isManager,
    required this.avatarStyle,
    this.avatarColorToken,
    this.avatarIllustrationId,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['age_group'] = Variable<String>(ageGroup);
    map['is_child'] = Variable<bool>(isChild);
    map['is_manager'] = Variable<bool>(isManager);
    map['avatar_style'] = Variable<String>(avatarStyle);
    if (!nullToAbsent || avatarColorToken != null) {
      map['avatar_color_token'] = Variable<String>(avatarColorToken);
    }
    if (!nullToAbsent || avatarIllustrationId != null) {
      map['avatar_illustration_id'] = Variable<String>(avatarIllustrationId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      id: Value(id),
      position: Value(position),
      name: Value(name),
      ageGroup: Value(ageGroup),
      isChild: Value(isChild),
      isManager: Value(isManager),
      avatarStyle: Value(avatarStyle),
      avatarColorToken: avatarColorToken == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarColorToken),
      avatarIllustrationId: avatarIllustrationId == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarIllustrationId),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      id: serializer.fromJson<String>(json['id']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      ageGroup: serializer.fromJson<String>(json['ageGroup']),
      isChild: serializer.fromJson<bool>(json['isChild']),
      isManager: serializer.fromJson<bool>(json['isManager']),
      avatarStyle: serializer.fromJson<String>(json['avatarStyle']),
      avatarColorToken: serializer.fromJson<String?>(json['avatarColorToken']),
      avatarIllustrationId: serializer.fromJson<String?>(
        json['avatarIllustrationId'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'ageGroup': serializer.toJson<String>(ageGroup),
      'isChild': serializer.toJson<bool>(isChild),
      'isManager': serializer.toJson<bool>(isManager),
      'avatarStyle': serializer.toJson<String>(avatarStyle),
      'avatarColorToken': serializer.toJson<String?>(avatarColorToken),
      'avatarIllustrationId': serializer.toJson<String?>(avatarIllustrationId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProfile copyWith({
    String? id,
    int? position,
    String? name,
    String? ageGroup,
    bool? isChild,
    bool? isManager,
    String? avatarStyle,
    Value<String?> avatarColorToken = const Value.absent(),
    Value<String?> avatarIllustrationId = const Value.absent(),
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => CachedProfile(
    id: id ?? this.id,
    position: position ?? this.position,
    name: name ?? this.name,
    ageGroup: ageGroup ?? this.ageGroup,
    isChild: isChild ?? this.isChild,
    isManager: isManager ?? this.isManager,
    avatarStyle: avatarStyle ?? this.avatarStyle,
    avatarColorToken: avatarColorToken.present
        ? avatarColorToken.value
        : this.avatarColorToken,
    avatarIllustrationId: avatarIllustrationId.present
        ? avatarIllustrationId.value
        : this.avatarIllustrationId,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      id: data.id.present ? data.id.value : this.id,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      ageGroup: data.ageGroup.present ? data.ageGroup.value : this.ageGroup,
      isChild: data.isChild.present ? data.isChild.value : this.isChild,
      isManager: data.isManager.present ? data.isManager.value : this.isManager,
      avatarStyle: data.avatarStyle.present
          ? data.avatarStyle.value
          : this.avatarStyle,
      avatarColorToken: data.avatarColorToken.present
          ? data.avatarColorToken.value
          : this.avatarColorToken,
      avatarIllustrationId: data.avatarIllustrationId.present
          ? data.avatarIllustrationId.value
          : this.avatarIllustrationId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('ageGroup: $ageGroup, ')
          ..write('isChild: $isChild, ')
          ..write('isManager: $isManager, ')
          ..write('avatarStyle: $avatarStyle, ')
          ..write('avatarColorToken: $avatarColorToken, ')
          ..write('avatarIllustrationId: $avatarIllustrationId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    position,
    name,
    ageGroup,
    isChild,
    isManager,
    avatarStyle,
    avatarColorToken,
    avatarIllustrationId,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.id == this.id &&
          other.position == this.position &&
          other.name == this.name &&
          other.ageGroup == this.ageGroup &&
          other.isChild == this.isChild &&
          other.isManager == this.isManager &&
          other.avatarStyle == this.avatarStyle &&
          other.avatarColorToken == this.avatarColorToken &&
          other.avatarIllustrationId == this.avatarIllustrationId &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> id;
  final Value<int> position;
  final Value<String> name;
  final Value<String> ageGroup;
  final Value<bool> isChild;
  final Value<bool> isManager;
  final Value<String> avatarStyle;
  final Value<String?> avatarColorToken;
  final Value<String?> avatarIllustrationId;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.id = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.ageGroup = const Value.absent(),
    this.isChild = const Value.absent(),
    this.isManager = const Value.absent(),
    this.avatarStyle = const Value.absent(),
    this.avatarColorToken = const Value.absent(),
    this.avatarIllustrationId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String id,
    required int position,
    required String name,
    required String ageGroup,
    required bool isChild,
    required bool isManager,
    required String avatarStyle,
    this.avatarColorToken = const Value.absent(),
    this.avatarIllustrationId = const Value.absent(),
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       position = Value(position),
       name = Value(name),
       ageGroup = Value(ageGroup),
       isChild = Value(isChild),
       isManager = Value(isManager),
       avatarStyle = Value(avatarStyle),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<CachedProfile> custom({
    Expression<String>? id,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? ageGroup,
    Expression<bool>? isChild,
    Expression<bool>? isManager,
    Expression<String>? avatarStyle,
    Expression<String>? avatarColorToken,
    Expression<String>? avatarIllustrationId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (ageGroup != null) 'age_group': ageGroup,
      if (isChild != null) 'is_child': isChild,
      if (isManager != null) 'is_manager': isManager,
      if (avatarStyle != null) 'avatar_style': avatarStyle,
      if (avatarColorToken != null) 'avatar_color_token': avatarColorToken,
      if (avatarIllustrationId != null)
        'avatar_illustration_id': avatarIllustrationId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? id,
    Value<int>? position,
    Value<String>? name,
    Value<String>? ageGroup,
    Value<bool>? isChild,
    Value<bool>? isManager,
    Value<String>? avatarStyle,
    Value<String?>? avatarColorToken,
    Value<String?>? avatarIllustrationId,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      id: id ?? this.id,
      position: position ?? this.position,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      isChild: isChild ?? this.isChild,
      isManager: isManager ?? this.isManager,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      avatarColorToken: avatarColorToken ?? this.avatarColorToken,
      avatarIllustrationId: avatarIllustrationId ?? this.avatarIllustrationId,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ageGroup.present) {
      map['age_group'] = Variable<String>(ageGroup.value);
    }
    if (isChild.present) {
      map['is_child'] = Variable<bool>(isChild.value);
    }
    if (isManager.present) {
      map['is_manager'] = Variable<bool>(isManager.value);
    }
    if (avatarStyle.present) {
      map['avatar_style'] = Variable<String>(avatarStyle.value);
    }
    if (avatarColorToken.present) {
      map['avatar_color_token'] = Variable<String>(avatarColorToken.value);
    }
    if (avatarIllustrationId.present) {
      map['avatar_illustration_id'] = Variable<String>(
        avatarIllustrationId.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('ageGroup: $ageGroup, ')
          ..write('isChild: $isChild, ')
          ..write('isManager: $isManager, ')
          ..write('avatarStyle: $avatarStyle, ')
          ..write('avatarColorToken: $avatarColorToken, ')
          ..write('avatarIllustrationId: $avatarIllustrationId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAllergensTable extends CachedAllergens
    with TableInfo<$CachedAllergensTable, CachedAllergen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAllergensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleSetVersionMeta = const VerificationMeta(
    'ruleSetVersion',
  );
  @override
  late final GeneratedColumn<String> ruleSetVersion = GeneratedColumn<String>(
    'rule_set_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    position,
    ruleSetVersion,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_allergens';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAllergen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('rule_set_version')) {
      context.handle(
        _ruleSetVersionMeta,
        ruleSetVersion.isAcceptableOrUnknown(
          data['rule_set_version']!,
          _ruleSetVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleSetVersionMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  CachedAllergen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAllergen(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      ruleSetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_set_version'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedAllergensTable createAlias(String alias) {
    return $CachedAllergensTable(attachedDatabase, alias);
  }
}

class CachedAllergen extends DataClass implements Insertable<CachedAllergen> {
  /// Contract `StandardAllergen` wire value.
  final String code;
  final int position;
  final String ruleSetVersion;
  final DateTime cachedAt;
  const CachedAllergen({
    required this.code,
    required this.position,
    required this.ruleSetVersion,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['position'] = Variable<int>(position);
    map['rule_set_version'] = Variable<String>(ruleSetVersion);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedAllergensCompanion toCompanion(bool nullToAbsent) {
    return CachedAllergensCompanion(
      code: Value(code),
      position: Value(position),
      ruleSetVersion: Value(ruleSetVersion),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedAllergen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAllergen(
      code: serializer.fromJson<String>(json['code']),
      position: serializer.fromJson<int>(json['position']),
      ruleSetVersion: serializer.fromJson<String>(json['ruleSetVersion']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'position': serializer.toJson<int>(position),
      'ruleSetVersion': serializer.toJson<String>(ruleSetVersion),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedAllergen copyWith({
    String? code,
    int? position,
    String? ruleSetVersion,
    DateTime? cachedAt,
  }) => CachedAllergen(
    code: code ?? this.code,
    position: position ?? this.position,
    ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedAllergen copyWithCompanion(CachedAllergensCompanion data) {
    return CachedAllergen(
      code: data.code.present ? data.code.value : this.code,
      position: data.position.present ? data.position.value : this.position,
      ruleSetVersion: data.ruleSetVersion.present
          ? data.ruleSetVersion.value
          : this.ruleSetVersion,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAllergen(')
          ..write('code: $code, ')
          ..write('position: $position, ')
          ..write('ruleSetVersion: $ruleSetVersion, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, position, ruleSetVersion, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAllergen &&
          other.code == this.code &&
          other.position == this.position &&
          other.ruleSetVersion == this.ruleSetVersion &&
          other.cachedAt == this.cachedAt);
}

class CachedAllergensCompanion extends UpdateCompanion<CachedAllergen> {
  final Value<String> code;
  final Value<int> position;
  final Value<String> ruleSetVersion;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedAllergensCompanion({
    this.code = const Value.absent(),
    this.position = const Value.absent(),
    this.ruleSetVersion = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAllergensCompanion.insert({
    required String code,
    required int position,
    required String ruleSetVersion,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       position = Value(position),
       ruleSetVersion = Value(ruleSetVersion),
       cachedAt = Value(cachedAt);
  static Insertable<CachedAllergen> custom({
    Expression<String>? code,
    Expression<int>? position,
    Expression<String>? ruleSetVersion,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (position != null) 'position': position,
      if (ruleSetVersion != null) 'rule_set_version': ruleSetVersion,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAllergensCompanion copyWith({
    Value<String>? code,
    Value<int>? position,
    Value<String>? ruleSetVersion,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedAllergensCompanion(
      code: code ?? this.code,
      position: position ?? this.position,
      ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (ruleSetVersion.present) {
      map['rule_set_version'] = Variable<String>(ruleSetVersion.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAllergensCompanion(')
          ..write('code: $code, ')
          ..write('position: $position, ')
          ..write('ruleSetVersion: $ruleSetVersion, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedKitchensTable extends CachedKitchens
    with TableInfo<$CachedKitchensTable, CachedKitchen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedKitchensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxItemsMeta = const VerificationMeta(
    'maxItems',
  );
  @override
  late final GeneratedColumn<int> maxItems = GeneratedColumn<int>(
    'max_items',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceVersionMeta = const VerificationMeta(
    'referenceVersion',
  );
  @override
  late final GeneratedColumn<String> referenceVersion = GeneratedColumn<String>(
    'reference_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    maxItems,
    referenceVersion,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_kitchens';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedKitchen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('max_items')) {
      context.handle(
        _maxItemsMeta,
        maxItems.isAcceptableOrUnknown(data['max_items']!, _maxItemsMeta),
      );
    } else if (isInserting) {
      context.missing(_maxItemsMeta);
    }
    if (data.containsKey('reference_version')) {
      context.handle(
        _referenceVersionMeta,
        referenceVersion.isAcceptableOrUnknown(
          data['reference_version']!,
          _referenceVersionMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedKitchen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedKitchen(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      maxItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_items'],
      )!,
      referenceVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_version'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedKitchensTable createAlias(String alias) {
    return $CachedKitchensTable(attachedDatabase, alias);
  }
}

class CachedKitchen extends DataClass implements Insertable<CachedKitchen> {
  final int id;
  final int maxItems;
  final String? referenceVersion;
  final DateTime cachedAt;
  const CachedKitchen({
    required this.id,
    required this.maxItems,
    this.referenceVersion,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['max_items'] = Variable<int>(maxItems);
    if (!nullToAbsent || referenceVersion != null) {
      map['reference_version'] = Variable<String>(referenceVersion);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedKitchensCompanion toCompanion(bool nullToAbsent) {
    return CachedKitchensCompanion(
      id: Value(id),
      maxItems: Value(maxItems),
      referenceVersion: referenceVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceVersion),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedKitchen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedKitchen(
      id: serializer.fromJson<int>(json['id']),
      maxItems: serializer.fromJson<int>(json['maxItems']),
      referenceVersion: serializer.fromJson<String?>(json['referenceVersion']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'maxItems': serializer.toJson<int>(maxItems),
      'referenceVersion': serializer.toJson<String?>(referenceVersion),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedKitchen copyWith({
    int? id,
    int? maxItems,
    Value<String?> referenceVersion = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedKitchen(
    id: id ?? this.id,
    maxItems: maxItems ?? this.maxItems,
    referenceVersion: referenceVersion.present
        ? referenceVersion.value
        : this.referenceVersion,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedKitchen copyWithCompanion(CachedKitchensCompanion data) {
    return CachedKitchen(
      id: data.id.present ? data.id.value : this.id,
      maxItems: data.maxItems.present ? data.maxItems.value : this.maxItems,
      referenceVersion: data.referenceVersion.present
          ? data.referenceVersion.value
          : this.referenceVersion,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedKitchen(')
          ..write('id: $id, ')
          ..write('maxItems: $maxItems, ')
          ..write('referenceVersion: $referenceVersion, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, maxItems, referenceVersion, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedKitchen &&
          other.id == this.id &&
          other.maxItems == this.maxItems &&
          other.referenceVersion == this.referenceVersion &&
          other.cachedAt == this.cachedAt);
}

class CachedKitchensCompanion extends UpdateCompanion<CachedKitchen> {
  final Value<int> id;
  final Value<int> maxItems;
  final Value<String?> referenceVersion;
  final Value<DateTime> cachedAt;
  const CachedKitchensCompanion({
    this.id = const Value.absent(),
    this.maxItems = const Value.absent(),
    this.referenceVersion = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedKitchensCompanion.insert({
    this.id = const Value.absent(),
    required int maxItems,
    this.referenceVersion = const Value.absent(),
    required DateTime cachedAt,
  }) : maxItems = Value(maxItems),
       cachedAt = Value(cachedAt);
  static Insertable<CachedKitchen> custom({
    Expression<int>? id,
    Expression<int>? maxItems,
    Expression<String>? referenceVersion,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (maxItems != null) 'max_items': maxItems,
      if (referenceVersion != null) 'reference_version': referenceVersion,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedKitchensCompanion copyWith({
    Value<int>? id,
    Value<int>? maxItems,
    Value<String?>? referenceVersion,
    Value<DateTime>? cachedAt,
  }) {
    return CachedKitchensCompanion(
      id: id ?? this.id,
      maxItems: maxItems ?? this.maxItems,
      referenceVersion: referenceVersion ?? this.referenceVersion,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (maxItems.present) {
      map['max_items'] = Variable<int>(maxItems.value);
    }
    if (referenceVersion.present) {
      map['reference_version'] = Variable<String>(referenceVersion.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedKitchensCompanion(')
          ..write('id: $id, ')
          ..write('maxItems: $maxItems, ')
          ..write('referenceVersion: $referenceVersion, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedKitchenItemsTable extends CachedKitchenItems
    with TableInfo<$CachedKitchenItemsTable, CachedKitchenItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedKitchenItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayNameIdMeta = const VerificationMeta(
    'displayNameId',
  );
  @override
  late final GeneratedColumn<String> displayNameId = GeneratedColumn<String>(
    'display_name_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameEnMeta = const VerificationMeta(
    'displayNameEn',
  );
  @override
  late final GeneratedColumn<String> displayNameEn = GeneratedColumn<String>(
    'display_name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultStapleMeta = const VerificationMeta(
    'isDefaultStaple',
  );
  @override
  late final GeneratedColumn<bool> isDefaultStaple = GeneratedColumn<bool>(
    'is_default_staple',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default_staple" IN (0, 1))',
    ),
  );
  static const VerificationMeta _usageRankMeta = const VerificationMeta(
    'usageRank',
  );
  @override
  late final GeneratedColumn<int> usageRank = GeneratedColumn<int>(
    'usage_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    position,
    ingredientId,
    isCustom,
    displayNameId,
    displayNameEn,
    customName,
    category,
    state,
    isDefaultStaple,
    usageRank,
    changedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_kitchen_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedKitchenItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    } else if (isInserting) {
      context.missing(_isCustomMeta);
    }
    if (data.containsKey('display_name_id')) {
      context.handle(
        _displayNameIdMeta,
        displayNameId.isAcceptableOrUnknown(
          data['display_name_id']!,
          _displayNameIdMeta,
        ),
      );
    }
    if (data.containsKey('display_name_en')) {
      context.handle(
        _displayNameEnMeta,
        displayNameEn.isAcceptableOrUnknown(
          data['display_name_en']!,
          _displayNameEnMeta,
        ),
      );
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('is_default_staple')) {
      context.handle(
        _isDefaultStapleMeta,
        isDefaultStaple.isAcceptableOrUnknown(
          data['is_default_staple']!,
          _isDefaultStapleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDefaultStapleMeta);
    }
    if (data.containsKey('usage_rank')) {
      context.handle(
        _usageRankMeta,
        usageRank.isAcceptableOrUnknown(data['usage_rank']!, _usageRankMeta),
      );
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedKitchenItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedKitchenItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      displayNameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_id'],
      ),
      displayNameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_en'],
      ),
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      isDefaultStaple: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_staple'],
      )!,
      usageRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_rank'],
      ),
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedKitchenItemsTable createAlias(String alias) {
    return $CachedKitchenItemsTable(attachedDatabase, alias);
  }
}

class CachedKitchenItem extends DataClass
    implements Insertable<CachedKitchenItem> {
  final String id;

  /// Order from the API (KIT-03 category order).
  final int position;
  final String? ingredientId;
  final bool isCustom;
  final String? displayNameId;
  final String? displayNameEn;
  final String? customName;

  /// Contract `KitchenCategory` wire value.
  final String category;

  /// Contract `KitchenItemState` wire value.
  final String state;
  final bool isDefaultStaple;
  final int? usageRank;
  final DateTime changedAt;
  final DateTime createdAt;
  const CachedKitchenItem({
    required this.id,
    required this.position,
    this.ingredientId,
    required this.isCustom,
    this.displayNameId,
    this.displayNameEn,
    this.customName,
    required this.category,
    required this.state,
    required this.isDefaultStaple,
    this.usageRank,
    required this.changedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || ingredientId != null) {
      map['ingredient_id'] = Variable<String>(ingredientId);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || displayNameId != null) {
      map['display_name_id'] = Variable<String>(displayNameId);
    }
    if (!nullToAbsent || displayNameEn != null) {
      map['display_name_en'] = Variable<String>(displayNameEn);
    }
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    map['category'] = Variable<String>(category);
    map['state'] = Variable<String>(state);
    map['is_default_staple'] = Variable<bool>(isDefaultStaple);
    if (!nullToAbsent || usageRank != null) {
      map['usage_rank'] = Variable<int>(usageRank);
    }
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CachedKitchenItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedKitchenItemsCompanion(
      id: Value(id),
      position: Value(position),
      ingredientId: ingredientId == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredientId),
      isCustom: Value(isCustom),
      displayNameId: displayNameId == null && nullToAbsent
          ? const Value.absent()
          : Value(displayNameId),
      displayNameEn: displayNameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(displayNameEn),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      category: Value(category),
      state: Value(state),
      isDefaultStaple: Value(isDefaultStaple),
      usageRank: usageRank == null && nullToAbsent
          ? const Value.absent()
          : Value(usageRank),
      changedAt: Value(changedAt),
      createdAt: Value(createdAt),
    );
  }

  factory CachedKitchenItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedKitchenItem(
      id: serializer.fromJson<String>(json['id']),
      position: serializer.fromJson<int>(json['position']),
      ingredientId: serializer.fromJson<String?>(json['ingredientId']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      displayNameId: serializer.fromJson<String?>(json['displayNameId']),
      displayNameEn: serializer.fromJson<String?>(json['displayNameEn']),
      customName: serializer.fromJson<String?>(json['customName']),
      category: serializer.fromJson<String>(json['category']),
      state: serializer.fromJson<String>(json['state']),
      isDefaultStaple: serializer.fromJson<bool>(json['isDefaultStaple']),
      usageRank: serializer.fromJson<int?>(json['usageRank']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'position': serializer.toJson<int>(position),
      'ingredientId': serializer.toJson<String?>(ingredientId),
      'isCustom': serializer.toJson<bool>(isCustom),
      'displayNameId': serializer.toJson<String?>(displayNameId),
      'displayNameEn': serializer.toJson<String?>(displayNameEn),
      'customName': serializer.toJson<String?>(customName),
      'category': serializer.toJson<String>(category),
      'state': serializer.toJson<String>(state),
      'isDefaultStaple': serializer.toJson<bool>(isDefaultStaple),
      'usageRank': serializer.toJson<int?>(usageRank),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CachedKitchenItem copyWith({
    String? id,
    int? position,
    Value<String?> ingredientId = const Value.absent(),
    bool? isCustom,
    Value<String?> displayNameId = const Value.absent(),
    Value<String?> displayNameEn = const Value.absent(),
    Value<String?> customName = const Value.absent(),
    String? category,
    String? state,
    bool? isDefaultStaple,
    Value<int?> usageRank = const Value.absent(),
    DateTime? changedAt,
    DateTime? createdAt,
  }) => CachedKitchenItem(
    id: id ?? this.id,
    position: position ?? this.position,
    ingredientId: ingredientId.present ? ingredientId.value : this.ingredientId,
    isCustom: isCustom ?? this.isCustom,
    displayNameId: displayNameId.present
        ? displayNameId.value
        : this.displayNameId,
    displayNameEn: displayNameEn.present
        ? displayNameEn.value
        : this.displayNameEn,
    customName: customName.present ? customName.value : this.customName,
    category: category ?? this.category,
    state: state ?? this.state,
    isDefaultStaple: isDefaultStaple ?? this.isDefaultStaple,
    usageRank: usageRank.present ? usageRank.value : this.usageRank,
    changedAt: changedAt ?? this.changedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedKitchenItem copyWithCompanion(CachedKitchenItemsCompanion data) {
    return CachedKitchenItem(
      id: data.id.present ? data.id.value : this.id,
      position: data.position.present ? data.position.value : this.position,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      displayNameId: data.displayNameId.present
          ? data.displayNameId.value
          : this.displayNameId,
      displayNameEn: data.displayNameEn.present
          ? data.displayNameEn.value
          : this.displayNameEn,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      category: data.category.present ? data.category.value : this.category,
      state: data.state.present ? data.state.value : this.state,
      isDefaultStaple: data.isDefaultStaple.present
          ? data.isDefaultStaple.value
          : this.isDefaultStaple,
      usageRank: data.usageRank.present ? data.usageRank.value : this.usageRank,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedKitchenItem(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('isCustom: $isCustom, ')
          ..write('displayNameId: $displayNameId, ')
          ..write('displayNameEn: $displayNameEn, ')
          ..write('customName: $customName, ')
          ..write('category: $category, ')
          ..write('state: $state, ')
          ..write('isDefaultStaple: $isDefaultStaple, ')
          ..write('usageRank: $usageRank, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    position,
    ingredientId,
    isCustom,
    displayNameId,
    displayNameEn,
    customName,
    category,
    state,
    isDefaultStaple,
    usageRank,
    changedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedKitchenItem &&
          other.id == this.id &&
          other.position == this.position &&
          other.ingredientId == this.ingredientId &&
          other.isCustom == this.isCustom &&
          other.displayNameId == this.displayNameId &&
          other.displayNameEn == this.displayNameEn &&
          other.customName == this.customName &&
          other.category == this.category &&
          other.state == this.state &&
          other.isDefaultStaple == this.isDefaultStaple &&
          other.usageRank == this.usageRank &&
          other.changedAt == this.changedAt &&
          other.createdAt == this.createdAt);
}

class CachedKitchenItemsCompanion extends UpdateCompanion<CachedKitchenItem> {
  final Value<String> id;
  final Value<int> position;
  final Value<String?> ingredientId;
  final Value<bool> isCustom;
  final Value<String?> displayNameId;
  final Value<String?> displayNameEn;
  final Value<String?> customName;
  final Value<String> category;
  final Value<String> state;
  final Value<bool> isDefaultStaple;
  final Value<int?> usageRank;
  final Value<DateTime> changedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CachedKitchenItemsCompanion({
    this.id = const Value.absent(),
    this.position = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.displayNameId = const Value.absent(),
    this.displayNameEn = const Value.absent(),
    this.customName = const Value.absent(),
    this.category = const Value.absent(),
    this.state = const Value.absent(),
    this.isDefaultStaple = const Value.absent(),
    this.usageRank = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedKitchenItemsCompanion.insert({
    required String id,
    required int position,
    this.ingredientId = const Value.absent(),
    required bool isCustom,
    this.displayNameId = const Value.absent(),
    this.displayNameEn = const Value.absent(),
    this.customName = const Value.absent(),
    required String category,
    required String state,
    required bool isDefaultStaple,
    this.usageRank = const Value.absent(),
    required DateTime changedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       position = Value(position),
       isCustom = Value(isCustom),
       category = Value(category),
       state = Value(state),
       isDefaultStaple = Value(isDefaultStaple),
       changedAt = Value(changedAt),
       createdAt = Value(createdAt);
  static Insertable<CachedKitchenItem> custom({
    Expression<String>? id,
    Expression<int>? position,
    Expression<String>? ingredientId,
    Expression<bool>? isCustom,
    Expression<String>? displayNameId,
    Expression<String>? displayNameEn,
    Expression<String>? customName,
    Expression<String>? category,
    Expression<String>? state,
    Expression<bool>? isDefaultStaple,
    Expression<int>? usageRank,
    Expression<DateTime>? changedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (position != null) 'position': position,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (isCustom != null) 'is_custom': isCustom,
      if (displayNameId != null) 'display_name_id': displayNameId,
      if (displayNameEn != null) 'display_name_en': displayNameEn,
      if (customName != null) 'custom_name': customName,
      if (category != null) 'category': category,
      if (state != null) 'state': state,
      if (isDefaultStaple != null) 'is_default_staple': isDefaultStaple,
      if (usageRank != null) 'usage_rank': usageRank,
      if (changedAt != null) 'changed_at': changedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedKitchenItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? position,
    Value<String?>? ingredientId,
    Value<bool>? isCustom,
    Value<String?>? displayNameId,
    Value<String?>? displayNameEn,
    Value<String?>? customName,
    Value<String>? category,
    Value<String>? state,
    Value<bool>? isDefaultStaple,
    Value<int?>? usageRank,
    Value<DateTime>? changedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedKitchenItemsCompanion(
      id: id ?? this.id,
      position: position ?? this.position,
      ingredientId: ingredientId ?? this.ingredientId,
      isCustom: isCustom ?? this.isCustom,
      displayNameId: displayNameId ?? this.displayNameId,
      displayNameEn: displayNameEn ?? this.displayNameEn,
      customName: customName ?? this.customName,
      category: category ?? this.category,
      state: state ?? this.state,
      isDefaultStaple: isDefaultStaple ?? this.isDefaultStaple,
      usageRank: usageRank ?? this.usageRank,
      changedAt: changedAt ?? this.changedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (displayNameId.present) {
      map['display_name_id'] = Variable<String>(displayNameId.value);
    }
    if (displayNameEn.present) {
      map['display_name_en'] = Variable<String>(displayNameEn.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (isDefaultStaple.present) {
      map['is_default_staple'] = Variable<bool>(isDefaultStaple.value);
    }
    if (usageRank.present) {
      map['usage_rank'] = Variable<int>(usageRank.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedKitchenItemsCompanion(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('isCustom: $isCustom, ')
          ..write('displayNameId: $displayNameId, ')
          ..write('displayNameEn: $displayNameEn, ')
          ..write('customName: $customName, ')
          ..write('category: $category, ')
          ..write('state: $state, ')
          ..write('isDefaultStaple: $isDefaultStaple, ')
          ..write('usageRank: $usageRank, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCatalogsTable extends CachedCatalogs
    with TableInfo<$CachedCatalogsTable, CachedCatalog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCatalogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceVersionMeta = const VerificationMeta(
    'referenceVersion',
  );
  @override
  late final GeneratedColumn<String> referenceVersion = GeneratedColumn<String>(
    'reference_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, referenceVersion, etag, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_catalogs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCatalog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reference_version')) {
      context.handle(
        _referenceVersionMeta,
        referenceVersion.isAcceptableOrUnknown(
          data['reference_version']!,
          _referenceVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceVersionMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCatalog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCatalog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      referenceVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_version'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCatalogsTable createAlias(String alias) {
    return $CachedCatalogsTable(attachedDatabase, alias);
  }
}

class CachedCatalog extends DataClass implements Insertable<CachedCatalog> {
  final int id;
  final String referenceVersion;
  final String? etag;
  final DateTime cachedAt;
  const CachedCatalog({
    required this.id,
    required this.referenceVersion,
    this.etag,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reference_version'] = Variable<String>(referenceVersion);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCatalogsCompanion toCompanion(bool nullToAbsent) {
    return CachedCatalogsCompanion(
      id: Value(id),
      referenceVersion: Value(referenceVersion),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCatalog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCatalog(
      id: serializer.fromJson<int>(json['id']),
      referenceVersion: serializer.fromJson<String>(json['referenceVersion']),
      etag: serializer.fromJson<String?>(json['etag']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'referenceVersion': serializer.toJson<String>(referenceVersion),
      'etag': serializer.toJson<String?>(etag),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCatalog copyWith({
    int? id,
    String? referenceVersion,
    Value<String?> etag = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedCatalog(
    id: id ?? this.id,
    referenceVersion: referenceVersion ?? this.referenceVersion,
    etag: etag.present ? etag.value : this.etag,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCatalog copyWithCompanion(CachedCatalogsCompanion data) {
    return CachedCatalog(
      id: data.id.present ? data.id.value : this.id,
      referenceVersion: data.referenceVersion.present
          ? data.referenceVersion.value
          : this.referenceVersion,
      etag: data.etag.present ? data.etag.value : this.etag,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCatalog(')
          ..write('id: $id, ')
          ..write('referenceVersion: $referenceVersion, ')
          ..write('etag: $etag, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, referenceVersion, etag, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCatalog &&
          other.id == this.id &&
          other.referenceVersion == this.referenceVersion &&
          other.etag == this.etag &&
          other.cachedAt == this.cachedAt);
}

class CachedCatalogsCompanion extends UpdateCompanion<CachedCatalog> {
  final Value<int> id;
  final Value<String> referenceVersion;
  final Value<String?> etag;
  final Value<DateTime> cachedAt;
  const CachedCatalogsCompanion({
    this.id = const Value.absent(),
    this.referenceVersion = const Value.absent(),
    this.etag = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedCatalogsCompanion.insert({
    this.id = const Value.absent(),
    required String referenceVersion,
    this.etag = const Value.absent(),
    required DateTime cachedAt,
  }) : referenceVersion = Value(referenceVersion),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCatalog> custom({
    Expression<int>? id,
    Expression<String>? referenceVersion,
    Expression<String>? etag,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (referenceVersion != null) 'reference_version': referenceVersion,
      if (etag != null) 'etag': etag,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedCatalogsCompanion copyWith({
    Value<int>? id,
    Value<String>? referenceVersion,
    Value<String?>? etag,
    Value<DateTime>? cachedAt,
  }) {
    return CachedCatalogsCompanion(
      id: id ?? this.id,
      referenceVersion: referenceVersion ?? this.referenceVersion,
      etag: etag ?? this.etag,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (referenceVersion.present) {
      map['reference_version'] = Variable<String>(referenceVersion.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCatalogsCompanion(')
          ..write('id: $id, ')
          ..write('referenceVersion: $referenceVersion, ')
          ..write('etag: $etag, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedCatalogIngredientsTable extends CachedCatalogIngredients
    with TableInfo<$CachedCatalogIngredientsTable, CachedCatalogIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCatalogIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameIdMeta = const VerificationMeta('nameId');
  @override
  late final GeneratedColumn<String> nameId = GeneratedColumn<String>(
    'name_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localNamesMeta = const VerificationMeta(
    'localNames',
  );
  @override
  late final GeneratedColumn<String> localNames = GeneratedColumn<String>(
    'local_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandVariesMeta = const VerificationMeta(
    'brandVaries',
  );
  @override
  late final GeneratedColumn<bool> brandVaries = GeneratedColumn<bool>(
    'brand_varies',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("brand_varies" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ingredientId,
    position,
    nameId,
    nameEn,
    localNames,
    category,
    brandVaries,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_catalog_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCatalogIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name_id')) {
      context.handle(
        _nameIdMeta,
        nameId.isAcceptableOrUnknown(data['name_id']!, _nameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nameIdMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('local_names')) {
      context.handle(
        _localNamesMeta,
        localNames.isAcceptableOrUnknown(data['local_names']!, _localNamesMeta),
      );
    } else if (isInserting) {
      context.missing(_localNamesMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('brand_varies')) {
      context.handle(
        _brandVariesMeta,
        brandVaries.isAcceptableOrUnknown(
          data['brand_varies']!,
          _brandVariesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_brandVariesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ingredientId};
  @override
  CachedCatalogIngredient map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCatalogIngredient(
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      nameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_id'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      localNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_names'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      brandVaries: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}brand_varies'],
      )!,
    );
  }

  @override
  $CachedCatalogIngredientsTable createAlias(String alias) {
    return $CachedCatalogIngredientsTable(attachedDatabase, alias);
  }
}

class CachedCatalogIngredient extends DataClass
    implements Insertable<CachedCatalogIngredient> {
  final String ingredientId;
  final int position;
  final String nameId;
  final String nameEn;

  /// JSON array of strings.
  final String localNames;

  /// Contract `KitchenCategory` wire value, or null.
  final String? category;
  final bool brandVaries;
  const CachedCatalogIngredient({
    required this.ingredientId,
    required this.position,
    required this.nameId,
    required this.nameEn,
    required this.localNames,
    this.category,
    required this.brandVaries,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['position'] = Variable<int>(position);
    map['name_id'] = Variable<String>(nameId);
    map['name_en'] = Variable<String>(nameEn);
    map['local_names'] = Variable<String>(localNames);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['brand_varies'] = Variable<bool>(brandVaries);
    return map;
  }

  CachedCatalogIngredientsCompanion toCompanion(bool nullToAbsent) {
    return CachedCatalogIngredientsCompanion(
      ingredientId: Value(ingredientId),
      position: Value(position),
      nameId: Value(nameId),
      nameEn: Value(nameEn),
      localNames: Value(localNames),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      brandVaries: Value(brandVaries),
    );
  }

  factory CachedCatalogIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCatalogIngredient(
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      position: serializer.fromJson<int>(json['position']),
      nameId: serializer.fromJson<String>(json['nameId']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      localNames: serializer.fromJson<String>(json['localNames']),
      category: serializer.fromJson<String?>(json['category']),
      brandVaries: serializer.fromJson<bool>(json['brandVaries']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ingredientId': serializer.toJson<String>(ingredientId),
      'position': serializer.toJson<int>(position),
      'nameId': serializer.toJson<String>(nameId),
      'nameEn': serializer.toJson<String>(nameEn),
      'localNames': serializer.toJson<String>(localNames),
      'category': serializer.toJson<String?>(category),
      'brandVaries': serializer.toJson<bool>(brandVaries),
    };
  }

  CachedCatalogIngredient copyWith({
    String? ingredientId,
    int? position,
    String? nameId,
    String? nameEn,
    String? localNames,
    Value<String?> category = const Value.absent(),
    bool? brandVaries,
  }) => CachedCatalogIngredient(
    ingredientId: ingredientId ?? this.ingredientId,
    position: position ?? this.position,
    nameId: nameId ?? this.nameId,
    nameEn: nameEn ?? this.nameEn,
    localNames: localNames ?? this.localNames,
    category: category.present ? category.value : this.category,
    brandVaries: brandVaries ?? this.brandVaries,
  );
  CachedCatalogIngredient copyWithCompanion(
    CachedCatalogIngredientsCompanion data,
  ) {
    return CachedCatalogIngredient(
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      position: data.position.present ? data.position.value : this.position,
      nameId: data.nameId.present ? data.nameId.value : this.nameId,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      localNames: data.localNames.present
          ? data.localNames.value
          : this.localNames,
      category: data.category.present ? data.category.value : this.category,
      brandVaries: data.brandVaries.present
          ? data.brandVaries.value
          : this.brandVaries,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCatalogIngredient(')
          ..write('ingredientId: $ingredientId, ')
          ..write('position: $position, ')
          ..write('nameId: $nameId, ')
          ..write('nameEn: $nameEn, ')
          ..write('localNames: $localNames, ')
          ..write('category: $category, ')
          ..write('brandVaries: $brandVaries')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ingredientId,
    position,
    nameId,
    nameEn,
    localNames,
    category,
    brandVaries,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCatalogIngredient &&
          other.ingredientId == this.ingredientId &&
          other.position == this.position &&
          other.nameId == this.nameId &&
          other.nameEn == this.nameEn &&
          other.localNames == this.localNames &&
          other.category == this.category &&
          other.brandVaries == this.brandVaries);
}

class CachedCatalogIngredientsCompanion
    extends UpdateCompanion<CachedCatalogIngredient> {
  final Value<String> ingredientId;
  final Value<int> position;
  final Value<String> nameId;
  final Value<String> nameEn;
  final Value<String> localNames;
  final Value<String?> category;
  final Value<bool> brandVaries;
  final Value<int> rowid;
  const CachedCatalogIngredientsCompanion({
    this.ingredientId = const Value.absent(),
    this.position = const Value.absent(),
    this.nameId = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.localNames = const Value.absent(),
    this.category = const Value.absent(),
    this.brandVaries = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCatalogIngredientsCompanion.insert({
    required String ingredientId,
    required int position,
    required String nameId,
    required String nameEn,
    required String localNames,
    this.category = const Value.absent(),
    required bool brandVaries,
    this.rowid = const Value.absent(),
  }) : ingredientId = Value(ingredientId),
       position = Value(position),
       nameId = Value(nameId),
       nameEn = Value(nameEn),
       localNames = Value(localNames),
       brandVaries = Value(brandVaries);
  static Insertable<CachedCatalogIngredient> custom({
    Expression<String>? ingredientId,
    Expression<int>? position,
    Expression<String>? nameId,
    Expression<String>? nameEn,
    Expression<String>? localNames,
    Expression<String>? category,
    Expression<bool>? brandVaries,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (position != null) 'position': position,
      if (nameId != null) 'name_id': nameId,
      if (nameEn != null) 'name_en': nameEn,
      if (localNames != null) 'local_names': localNames,
      if (category != null) 'category': category,
      if (brandVaries != null) 'brand_varies': brandVaries,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCatalogIngredientsCompanion copyWith({
    Value<String>? ingredientId,
    Value<int>? position,
    Value<String>? nameId,
    Value<String>? nameEn,
    Value<String>? localNames,
    Value<String?>? category,
    Value<bool>? brandVaries,
    Value<int>? rowid,
  }) {
    return CachedCatalogIngredientsCompanion(
      ingredientId: ingredientId ?? this.ingredientId,
      position: position ?? this.position,
      nameId: nameId ?? this.nameId,
      nameEn: nameEn ?? this.nameEn,
      localNames: localNames ?? this.localNames,
      category: category ?? this.category,
      brandVaries: brandVaries ?? this.brandVaries,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (nameId.present) {
      map['name_id'] = Variable<String>(nameId.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (localNames.present) {
      map['local_names'] = Variable<String>(localNames.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brandVaries.present) {
      map['brand_varies'] = Variable<bool>(brandVaries.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCatalogIngredientsCompanion(')
          ..write('ingredientId: $ingredientId, ')
          ..write('position: $position, ')
          ..write('nameId: $nameId, ')
          ..write('nameEn: $nameEn, ')
          ..write('localNames: $localNames, ')
          ..write('category: $category, ')
          ..write('brandVaries: $brandVaries, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CachedHouseholdsTable cachedHouseholds = $CachedHouseholdsTable(
    this,
  );
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedAllergensTable cachedAllergens = $CachedAllergensTable(
    this,
  );
  late final $CachedKitchensTable cachedKitchens = $CachedKitchensTable(this);
  late final $CachedKitchenItemsTable cachedKitchenItems =
      $CachedKitchenItemsTable(this);
  late final $CachedCatalogsTable cachedCatalogs = $CachedCatalogsTable(this);
  late final $CachedCatalogIngredientsTable cachedCatalogIngredients =
      $CachedCatalogIngredientsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    cachedHouseholds,
    cachedProfiles,
    cachedAllergens,
    cachedKitchens,
    cachedKitchenItems,
    cachedCatalogs,
    cachedCatalogIngredients,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$CachedHouseholdsTableCreateCompanionBuilder =
    CachedHouseholdsCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> city,
      required String timeZone,
      required String language,
      required String managerAccountId,
      required String managerProfileId,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedHouseholdsTableUpdateCompanionBuilder =
    CachedHouseholdsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> city,
      Value<String> timeZone,
      Value<String> language,
      Value<String> managerAccountId,
      Value<String> managerProfileId,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedHouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedHouseholdsTable> {
  $$CachedHouseholdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managerAccountId => $composableBuilder(
    column: $table.managerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managerProfileId => $composableBuilder(
    column: $table.managerProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedHouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedHouseholdsTable> {
  $$CachedHouseholdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managerAccountId => $composableBuilder(
    column: $table.managerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managerProfileId => $composableBuilder(
    column: $table.managerProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedHouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedHouseholdsTable> {
  $$CachedHouseholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get managerAccountId => $composableBuilder(
    column: $table.managerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managerProfileId => $composableBuilder(
    column: $table.managerProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedHouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedHouseholdsTable,
          CachedHousehold,
          $$CachedHouseholdsTableFilterComposer,
          $$CachedHouseholdsTableOrderingComposer,
          $$CachedHouseholdsTableAnnotationComposer,
          $$CachedHouseholdsTableCreateCompanionBuilder,
          $$CachedHouseholdsTableUpdateCompanionBuilder,
          (
            CachedHousehold,
            BaseReferences<
              _$AppDatabase,
              $CachedHouseholdsTable,
              CachedHousehold
            >,
          ),
          CachedHousehold,
          PrefetchHooks Function()
        > {
  $$CachedHouseholdsTableTableManager(
    _$AppDatabase db,
    $CachedHouseholdsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedHouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedHouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedHouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> managerAccountId = const Value.absent(),
                Value<String> managerProfileId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedHouseholdsCompanion(
                id: id,
                name: name,
                city: city,
                timeZone: timeZone,
                language: language,
                managerAccountId: managerAccountId,
                managerProfileId: managerProfileId,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> city = const Value.absent(),
                required String timeZone,
                required String language,
                required String managerAccountId,
                required String managerProfileId,
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedHouseholdsCompanion.insert(
                id: id,
                name: name,
                city: city,
                timeZone: timeZone,
                language: language,
                managerAccountId: managerAccountId,
                managerProfileId: managerProfileId,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedHouseholdsTable, CachedHousehold>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedHouseholdsTable,
                    CachedHousehold
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedHouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedHouseholdsTable,
      CachedHousehold,
      $$CachedHouseholdsTableFilterComposer,
      $$CachedHouseholdsTableOrderingComposer,
      $$CachedHouseholdsTableAnnotationComposer,
      $$CachedHouseholdsTableCreateCompanionBuilder,
      $$CachedHouseholdsTableUpdateCompanionBuilder,
      (
        CachedHousehold,
        BaseReferences<_$AppDatabase, $CachedHouseholdsTable, CachedHousehold>,
      ),
      CachedHousehold,
      PrefetchHooks Function()
    >;
typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String id,
      required int position,
      required String name,
      required String ageGroup,
      required bool isChild,
      required bool isManager,
      required String avatarStyle,
      Value<String?> avatarColorToken,
      Value<String?> avatarIllustrationId,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> id,
      Value<int> position,
      Value<String> name,
      Value<String> ageGroup,
      Value<bool> isChild,
      Value<bool> isManager,
      Value<String> avatarStyle,
      Value<String?> avatarColorToken,
      Value<String?> avatarIllustrationId,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageGroup => $composableBuilder(
    column: $table.ageGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChild => $composableBuilder(
    column: $table.isChild,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManager => $composableBuilder(
    column: $table.isManager,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarStyle => $composableBuilder(
    column: $table.avatarStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarColorToken => $composableBuilder(
    column: $table.avatarColorToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarIllustrationId => $composableBuilder(
    column: $table.avatarIllustrationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageGroup => $composableBuilder(
    column: $table.ageGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChild => $composableBuilder(
    column: $table.isChild,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManager => $composableBuilder(
    column: $table.isManager,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarStyle => $composableBuilder(
    column: $table.avatarStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarColorToken => $composableBuilder(
    column: $table.avatarColorToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarIllustrationId => $composableBuilder(
    column: $table.avatarIllustrationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ageGroup =>
      $composableBuilder(column: $table.ageGroup, builder: (column) => column);

  GeneratedColumn<bool> get isChild =>
      $composableBuilder(column: $table.isChild, builder: (column) => column);

  GeneratedColumn<bool> get isManager =>
      $composableBuilder(column: $table.isManager, builder: (column) => column);

  GeneratedColumn<String> get avatarStyle => $composableBuilder(
    column: $table.avatarStyle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarColorToken => $composableBuilder(
    column: $table.avatarColorToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarIllustrationId => $composableBuilder(
    column: $table.avatarIllustrationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ageGroup = const Value.absent(),
                Value<bool> isChild = const Value.absent(),
                Value<bool> isManager = const Value.absent(),
                Value<String> avatarStyle = const Value.absent(),
                Value<String?> avatarColorToken = const Value.absent(),
                Value<String?> avatarIllustrationId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                id: id,
                position: position,
                name: name,
                ageGroup: ageGroup,
                isChild: isChild,
                isManager: isManager,
                avatarStyle: avatarStyle,
                avatarColorToken: avatarColorToken,
                avatarIllustrationId: avatarIllustrationId,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int position,
                required String name,
                required String ageGroup,
                required bool isChild,
                required bool isManager,
                required String avatarStyle,
                Value<String?> avatarColorToken = const Value.absent(),
                Value<String?> avatarIllustrationId = const Value.absent(),
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                id: id,
                position: position,
                name: name,
                ageGroup: ageGroup,
                isChild: isChild,
                isManager: isManager,
                avatarStyle: avatarStyle,
                avatarColorToken: avatarColorToken,
                avatarIllustrationId: avatarIllustrationId,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedProfilesTable, CachedProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedProfilesTable,
                    CachedProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedAllergensTableCreateCompanionBuilder =
    CachedAllergensCompanion Function({
      required String code,
      required int position,
      required String ruleSetVersion,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedAllergensTableUpdateCompanionBuilder =
    CachedAllergensCompanion Function({
      Value<String> code,
      Value<int> position,
      Value<String> ruleSetVersion,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedAllergensTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAllergensTable> {
  $$CachedAllergensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleSetVersion => $composableBuilder(
    column: $table.ruleSetVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAllergensTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAllergensTable> {
  $$CachedAllergensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleSetVersion => $composableBuilder(
    column: $table.ruleSetVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAllergensTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAllergensTable> {
  $$CachedAllergensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get ruleSetVersion => $composableBuilder(
    column: $table.ruleSetVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedAllergensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAllergensTable,
          CachedAllergen,
          $$CachedAllergensTableFilterComposer,
          $$CachedAllergensTableOrderingComposer,
          $$CachedAllergensTableAnnotationComposer,
          $$CachedAllergensTableCreateCompanionBuilder,
          $$CachedAllergensTableUpdateCompanionBuilder,
          (
            CachedAllergen,
            BaseReferences<
              _$AppDatabase,
              $CachedAllergensTable,
              CachedAllergen
            >,
          ),
          CachedAllergen,
          PrefetchHooks Function()
        > {
  $$CachedAllergensTableTableManager(
    _$AppDatabase db,
    $CachedAllergensTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAllergensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAllergensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAllergensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> ruleSetVersion = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAllergensCompanion(
                code: code,
                position: position,
                ruleSetVersion: ruleSetVersion,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required int position,
                required String ruleSetVersion,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAllergensCompanion.insert(
                code: code,
                position: position,
                ruleSetVersion: ruleSetVersion,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedAllergensTable, CachedAllergen>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedAllergensTable,
                    CachedAllergen
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAllergensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAllergensTable,
      CachedAllergen,
      $$CachedAllergensTableFilterComposer,
      $$CachedAllergensTableOrderingComposer,
      $$CachedAllergensTableAnnotationComposer,
      $$CachedAllergensTableCreateCompanionBuilder,
      $$CachedAllergensTableUpdateCompanionBuilder,
      (
        CachedAllergen,
        BaseReferences<_$AppDatabase, $CachedAllergensTable, CachedAllergen>,
      ),
      CachedAllergen,
      PrefetchHooks Function()
    >;
typedef $$CachedKitchensTableCreateCompanionBuilder =
    CachedKitchensCompanion Function({
      Value<int> id,
      required int maxItems,
      Value<String?> referenceVersion,
      required DateTime cachedAt,
    });
typedef $$CachedKitchensTableUpdateCompanionBuilder =
    CachedKitchensCompanion Function({
      Value<int> id,
      Value<int> maxItems,
      Value<String?> referenceVersion,
      Value<DateTime> cachedAt,
    });

class $$CachedKitchensTableFilterComposer
    extends Composer<_$AppDatabase, $CachedKitchensTable> {
  $$CachedKitchensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxItems => $composableBuilder(
    column: $table.maxItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceVersion => $composableBuilder(
    column: $table.referenceVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedKitchensTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedKitchensTable> {
  $$CachedKitchensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxItems => $composableBuilder(
    column: $table.maxItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceVersion => $composableBuilder(
    column: $table.referenceVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedKitchensTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedKitchensTable> {
  $$CachedKitchensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get maxItems =>
      $composableBuilder(column: $table.maxItems, builder: (column) => column);

  GeneratedColumn<String> get referenceVersion => $composableBuilder(
    column: $table.referenceVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedKitchensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedKitchensTable,
          CachedKitchen,
          $$CachedKitchensTableFilterComposer,
          $$CachedKitchensTableOrderingComposer,
          $$CachedKitchensTableAnnotationComposer,
          $$CachedKitchensTableCreateCompanionBuilder,
          $$CachedKitchensTableUpdateCompanionBuilder,
          (
            CachedKitchen,
            BaseReferences<_$AppDatabase, $CachedKitchensTable, CachedKitchen>,
          ),
          CachedKitchen,
          PrefetchHooks Function()
        > {
  $$CachedKitchensTableTableManager(
    _$AppDatabase db,
    $CachedKitchensTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedKitchensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedKitchensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedKitchensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> maxItems = const Value.absent(),
                Value<String?> referenceVersion = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedKitchensCompanion(
                id: id,
                maxItems: maxItems,
                referenceVersion: referenceVersion,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int maxItems,
                Value<String?> referenceVersion = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedKitchensCompanion.insert(
                id: id,
                maxItems: maxItems,
                referenceVersion: referenceVersion,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedKitchensTable, CachedKitchen>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedKitchensTable,
                    CachedKitchen
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedKitchensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedKitchensTable,
      CachedKitchen,
      $$CachedKitchensTableFilterComposer,
      $$CachedKitchensTableOrderingComposer,
      $$CachedKitchensTableAnnotationComposer,
      $$CachedKitchensTableCreateCompanionBuilder,
      $$CachedKitchensTableUpdateCompanionBuilder,
      (
        CachedKitchen,
        BaseReferences<_$AppDatabase, $CachedKitchensTable, CachedKitchen>,
      ),
      CachedKitchen,
      PrefetchHooks Function()
    >;
typedef $$CachedKitchenItemsTableCreateCompanionBuilder =
    CachedKitchenItemsCompanion Function({
      required String id,
      required int position,
      Value<String?> ingredientId,
      required bool isCustom,
      Value<String?> displayNameId,
      Value<String?> displayNameEn,
      Value<String?> customName,
      required String category,
      required String state,
      required bool isDefaultStaple,
      Value<int?> usageRank,
      required DateTime changedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CachedKitchenItemsTableUpdateCompanionBuilder =
    CachedKitchenItemsCompanion Function({
      Value<String> id,
      Value<int> position,
      Value<String?> ingredientId,
      Value<bool> isCustom,
      Value<String?> displayNameId,
      Value<String?> displayNameEn,
      Value<String?> customName,
      Value<String> category,
      Value<String> state,
      Value<bool> isDefaultStaple,
      Value<int?> usageRank,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CachedKitchenItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedKitchenItemsTable> {
  $$CachedKitchenItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameId => $composableBuilder(
    column: $table.displayNameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameEn => $composableBuilder(
    column: $table.displayNameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultStaple => $composableBuilder(
    column: $table.isDefaultStaple,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageRank => $composableBuilder(
    column: $table.usageRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedKitchenItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedKitchenItemsTable> {
  $$CachedKitchenItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameId => $composableBuilder(
    column: $table.displayNameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameEn => $composableBuilder(
    column: $table.displayNameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultStaple => $composableBuilder(
    column: $table.isDefaultStaple,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageRank => $composableBuilder(
    column: $table.usageRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedKitchenItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedKitchenItemsTable> {
  $$CachedKitchenItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get displayNameId => $composableBuilder(
    column: $table.displayNameId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayNameEn => $composableBuilder(
    column: $table.displayNameEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<bool> get isDefaultStaple => $composableBuilder(
    column: $table.isDefaultStaple,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usageRank =>
      $composableBuilder(column: $table.usageRank, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedKitchenItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedKitchenItemsTable,
          CachedKitchenItem,
          $$CachedKitchenItemsTableFilterComposer,
          $$CachedKitchenItemsTableOrderingComposer,
          $$CachedKitchenItemsTableAnnotationComposer,
          $$CachedKitchenItemsTableCreateCompanionBuilder,
          $$CachedKitchenItemsTableUpdateCompanionBuilder,
          (
            CachedKitchenItem,
            BaseReferences<
              _$AppDatabase,
              $CachedKitchenItemsTable,
              CachedKitchenItem
            >,
          ),
          CachedKitchenItem,
          PrefetchHooks Function()
        > {
  $$CachedKitchenItemsTableTableManager(
    _$AppDatabase db,
    $CachedKitchenItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedKitchenItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedKitchenItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedKitchenItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> ingredientId = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> displayNameId = const Value.absent(),
                Value<String?> displayNameEn = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<bool> isDefaultStaple = const Value.absent(),
                Value<int?> usageRank = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedKitchenItemsCompanion(
                id: id,
                position: position,
                ingredientId: ingredientId,
                isCustom: isCustom,
                displayNameId: displayNameId,
                displayNameEn: displayNameEn,
                customName: customName,
                category: category,
                state: state,
                isDefaultStaple: isDefaultStaple,
                usageRank: usageRank,
                changedAt: changedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int position,
                Value<String?> ingredientId = const Value.absent(),
                required bool isCustom,
                Value<String?> displayNameId = const Value.absent(),
                Value<String?> displayNameEn = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                required String category,
                required String state,
                required bool isDefaultStaple,
                Value<int?> usageRank = const Value.absent(),
                required DateTime changedAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedKitchenItemsCompanion.insert(
                id: id,
                position: position,
                ingredientId: ingredientId,
                isCustom: isCustom,
                displayNameId: displayNameId,
                displayNameEn: displayNameEn,
                customName: customName,
                category: category,
                state: state,
                isDefaultStaple: isDefaultStaple,
                usageRank: usageRank,
                changedAt: changedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedKitchenItemsTable, CachedKitchenItem>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedKitchenItemsTable,
                    CachedKitchenItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedKitchenItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedKitchenItemsTable,
      CachedKitchenItem,
      $$CachedKitchenItemsTableFilterComposer,
      $$CachedKitchenItemsTableOrderingComposer,
      $$CachedKitchenItemsTableAnnotationComposer,
      $$CachedKitchenItemsTableCreateCompanionBuilder,
      $$CachedKitchenItemsTableUpdateCompanionBuilder,
      (
        CachedKitchenItem,
        BaseReferences<
          _$AppDatabase,
          $CachedKitchenItemsTable,
          CachedKitchenItem
        >,
      ),
      CachedKitchenItem,
      PrefetchHooks Function()
    >;
typedef $$CachedCatalogsTableCreateCompanionBuilder =
    CachedCatalogsCompanion Function({
      Value<int> id,
      required String referenceVersion,
      Value<String?> etag,
      required DateTime cachedAt,
    });
typedef $$CachedCatalogsTableUpdateCompanionBuilder =
    CachedCatalogsCompanion Function({
      Value<int> id,
      Value<String> referenceVersion,
      Value<String?> etag,
      Value<DateTime> cachedAt,
    });

class $$CachedCatalogsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCatalogsTable> {
  $$CachedCatalogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceVersion => $composableBuilder(
    column: $table.referenceVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCatalogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCatalogsTable> {
  $$CachedCatalogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceVersion => $composableBuilder(
    column: $table.referenceVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCatalogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCatalogsTable> {
  $$CachedCatalogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get referenceVersion => $composableBuilder(
    column: $table.referenceVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCatalogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCatalogsTable,
          CachedCatalog,
          $$CachedCatalogsTableFilterComposer,
          $$CachedCatalogsTableOrderingComposer,
          $$CachedCatalogsTableAnnotationComposer,
          $$CachedCatalogsTableCreateCompanionBuilder,
          $$CachedCatalogsTableUpdateCompanionBuilder,
          (
            CachedCatalog,
            BaseReferences<_$AppDatabase, $CachedCatalogsTable, CachedCatalog>,
          ),
          CachedCatalog,
          PrefetchHooks Function()
        > {
  $$CachedCatalogsTableTableManager(
    _$AppDatabase db,
    $CachedCatalogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCatalogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCatalogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCatalogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> referenceVersion = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedCatalogsCompanion(
                id: id,
                referenceVersion: referenceVersion,
                etag: etag,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String referenceVersion,
                Value<String?> etag = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedCatalogsCompanion.insert(
                id: id,
                referenceVersion: referenceVersion,
                etag: etag,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedCatalogsTable, CachedCatalog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedCatalogsTable,
                    CachedCatalog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCatalogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCatalogsTable,
      CachedCatalog,
      $$CachedCatalogsTableFilterComposer,
      $$CachedCatalogsTableOrderingComposer,
      $$CachedCatalogsTableAnnotationComposer,
      $$CachedCatalogsTableCreateCompanionBuilder,
      $$CachedCatalogsTableUpdateCompanionBuilder,
      (
        CachedCatalog,
        BaseReferences<_$AppDatabase, $CachedCatalogsTable, CachedCatalog>,
      ),
      CachedCatalog,
      PrefetchHooks Function()
    >;
typedef $$CachedCatalogIngredientsTableCreateCompanionBuilder =
    CachedCatalogIngredientsCompanion Function({
      required String ingredientId,
      required int position,
      required String nameId,
      required String nameEn,
      required String localNames,
      Value<String?> category,
      required bool brandVaries,
      Value<int> rowid,
    });
typedef $$CachedCatalogIngredientsTableUpdateCompanionBuilder =
    CachedCatalogIngredientsCompanion Function({
      Value<String> ingredientId,
      Value<int> position,
      Value<String> nameId,
      Value<String> nameEn,
      Value<String> localNames,
      Value<String?> category,
      Value<bool> brandVaries,
      Value<int> rowid,
    });

class $$CachedCatalogIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCatalogIngredientsTable> {
  $$CachedCatalogIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameId => $composableBuilder(
    column: $table.nameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localNames => $composableBuilder(
    column: $table.localNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get brandVaries => $composableBuilder(
    column: $table.brandVaries,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCatalogIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCatalogIngredientsTable> {
  $$CachedCatalogIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameId => $composableBuilder(
    column: $table.nameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localNames => $composableBuilder(
    column: $table.localNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get brandVaries => $composableBuilder(
    column: $table.brandVaries,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCatalogIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCatalogIngredientsTable> {
  $$CachedCatalogIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get nameId =>
      $composableBuilder(column: $table.nameId, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get localNames => $composableBuilder(
    column: $table.localNames,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get brandVaries => $composableBuilder(
    column: $table.brandVaries,
    builder: (column) => column,
  );
}

class $$CachedCatalogIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCatalogIngredientsTable,
          CachedCatalogIngredient,
          $$CachedCatalogIngredientsTableFilterComposer,
          $$CachedCatalogIngredientsTableOrderingComposer,
          $$CachedCatalogIngredientsTableAnnotationComposer,
          $$CachedCatalogIngredientsTableCreateCompanionBuilder,
          $$CachedCatalogIngredientsTableUpdateCompanionBuilder,
          (
            CachedCatalogIngredient,
            BaseReferences<
              _$AppDatabase,
              $CachedCatalogIngredientsTable,
              CachedCatalogIngredient
            >,
          ),
          CachedCatalogIngredient,
          PrefetchHooks Function()
        > {
  $$CachedCatalogIngredientsTableTableManager(
    _$AppDatabase db,
    $CachedCatalogIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCatalogIngredientsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedCatalogIngredientsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCatalogIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ingredientId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> nameId = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> localNames = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> brandVaries = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCatalogIngredientsCompanion(
                ingredientId: ingredientId,
                position: position,
                nameId: nameId,
                nameEn: nameEn,
                localNames: localNames,
                category: category,
                brandVaries: brandVaries,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ingredientId,
                required int position,
                required String nameId,
                required String nameEn,
                required String localNames,
                Value<String?> category = const Value.absent(),
                required bool brandVaries,
                Value<int> rowid = const Value.absent(),
              }) => CachedCatalogIngredientsCompanion.insert(
                ingredientId: ingredientId,
                position: position,
                nameId: nameId,
                nameEn: nameEn,
                localNames: localNames,
                category: category,
                brandVaries: brandVaries,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedCatalogIngredientsTable,
                    CachedCatalogIngredient
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedCatalogIngredientsTable,
                    CachedCatalogIngredient
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCatalogIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCatalogIngredientsTable,
      CachedCatalogIngredient,
      $$CachedCatalogIngredientsTableFilterComposer,
      $$CachedCatalogIngredientsTableOrderingComposer,
      $$CachedCatalogIngredientsTableAnnotationComposer,
      $$CachedCatalogIngredientsTableCreateCompanionBuilder,
      $$CachedCatalogIngredientsTableUpdateCompanionBuilder,
      (
        CachedCatalogIngredient,
        BaseReferences<
          _$AppDatabase,
          $CachedCatalogIngredientsTable,
          CachedCatalogIngredient
        >,
      ),
      CachedCatalogIngredient,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CachedHouseholdsTableTableManager get cachedHouseholds =>
      $$CachedHouseholdsTableTableManager(_db, _db.cachedHouseholds);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedAllergensTableTableManager get cachedAllergens =>
      $$CachedAllergensTableTableManager(_db, _db.cachedAllergens);
  $$CachedKitchensTableTableManager get cachedKitchens =>
      $$CachedKitchensTableTableManager(_db, _db.cachedKitchens);
  $$CachedKitchenItemsTableTableManager get cachedKitchenItems =>
      $$CachedKitchenItemsTableTableManager(_db, _db.cachedKitchenItems);
  $$CachedCatalogsTableTableManager get cachedCatalogs =>
      $$CachedCatalogsTableTableManager(_db, _db.cachedCatalogs);
  $$CachedCatalogIngredientsTableTableManager get cachedCatalogIngredients =>
      $$CachedCatalogIngredientsTableTableManager(
        _db,
        _db.cachedCatalogIngredients,
      );
}
