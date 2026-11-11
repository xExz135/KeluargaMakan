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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    cachedHouseholds,
    cachedProfiles,
    cachedAllergens,
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
}
