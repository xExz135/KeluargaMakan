//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Household {
  /// Returns a new [Household] instance.
  Household({
    required this.id,
    required this.name,
    required this.city,
    required this.timeZone,
    required this.language,
    required this.managerAccountId,
    required this.managerProfileId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final String? name;

  final String? city;

  /// IANA time zone name (NFR-16).
  final String timeZone;

  final Language language;

  /// The household's only manager account (ACC-03).
  final String managerAccountId;

  /// The manager's own profile.
  final String managerProfileId;

  final DateTime createdAt;

  final DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Household &&
    other.id == id &&
    other.name == name &&
    other.city == city &&
    other.timeZone == timeZone &&
    other.language == language &&
    other.managerAccountId == managerAccountId &&
    other.managerProfileId == managerProfileId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (city == null ? 0 : city!.hashCode) +
    (timeZone.hashCode) +
    (language.hashCode) +
    (managerAccountId.hashCode) +
    (managerProfileId.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'Household[id=$id, name=$name, city=$city, timeZone=$timeZone, language=$language, managerAccountId=$managerAccountId, managerProfileId=$managerProfileId, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.city != null) {
      json[r'city'] = this.city;
    } else {
      json[r'city'] = null;
    }
      json[r'timeZone'] = this.timeZone;
      json[r'language'] = this.language;
      json[r'managerAccountId'] = this.managerAccountId;
      json[r'managerProfileId'] = this.managerProfileId;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [Household] and returns a new one where some of the
  /// properties have changed.
  Household copyWith({
    String? id,
    String? name,
    bool nameSetToNull = false,
    String? city,
    bool citySetToNull = false,
    String? timeZone,
    Language? language,
    String? managerAccountId,
    String? managerProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Household(
    id: id ?? this.id,
    name: nameSetToNull ? null : name ?? this.name,
    city: citySetToNull ? null : city ?? this.city,
    timeZone: timeZone ?? this.timeZone,
    language: language ?? this.language,
    managerAccountId: managerAccountId ?? this.managerAccountId,
    managerProfileId: managerProfileId ?? this.managerProfileId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a new [Household] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Household? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Household[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Household[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "Household[name]" is missing from JSON.');
        assert(json.containsKey(r'city'), 'Required key "Household[city]" is missing from JSON.');
        assert(json.containsKey(r'timeZone'), 'Required key "Household[timeZone]" is missing from JSON.');
        assert(json[r'timeZone'] != null, 'Required key "Household[timeZone]" has a null value in JSON.');
        assert(json.containsKey(r'language'), 'Required key "Household[language]" is missing from JSON.');
        assert(json[r'language'] != null, 'Required key "Household[language]" has a null value in JSON.');
        assert(json.containsKey(r'managerAccountId'), 'Required key "Household[managerAccountId]" is missing from JSON.');
        assert(json[r'managerAccountId'] != null, 'Required key "Household[managerAccountId]" has a null value in JSON.');
        assert(json.containsKey(r'managerProfileId'), 'Required key "Household[managerProfileId]" is missing from JSON.');
        assert(json[r'managerProfileId'] != null, 'Required key "Household[managerProfileId]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "Household[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "Household[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "Household[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "Household[updatedAt]" has a null value in JSON.');
        return true;
      }());

      return Household(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name'),
        city: mapValueOfType<String>(json, r'city'),
        timeZone: mapValueOfType<String>(json, r'timeZone')!,
        language: Language.fromJson(json[r'language'])!,
        managerAccountId: mapValueOfType<String>(json, r'managerAccountId')!,
        managerProfileId: mapValueOfType<String>(json, r'managerProfileId')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<Household> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Household>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Household.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Household> mapFromJson(dynamic json) {
    final map = <String, Household>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Household.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Household-objects as value to a dart map
  static Map<String, List<Household>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Household>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Household.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'city',
    'timeZone',
    'language',
    'managerAccountId',
    'managerProfileId',
    'createdAt',
    'updatedAt',
  };
}

