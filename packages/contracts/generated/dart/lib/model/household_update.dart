//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HouseholdUpdate {
  /// Returns a new [HouseholdUpdate] instance.
  HouseholdUpdate({
    this.name = const Optional.absent(),
    this.city = const Optional.absent(),
    this.timeZone = const Optional.absent(),
    this.language = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> city;

  /// IANA time zone name (NFR-16).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> timeZone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<Language?> language;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HouseholdUpdate &&
    other.name == name &&
    other.city == city &&
    other.timeZone == timeZone &&
    other.language == language;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (city == null ? 0 : city!.hashCode) +
    (timeZone == null ? 0 : timeZone!.hashCode) +
    (language == null ? 0 : language!.hashCode);

  @override
  String toString() => 'HouseholdUpdate[name=$name, city=$city, timeZone=$timeZone, language=$language]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.city.isPresent) {
      final value = this.city.value;
      json[r'city'] = value;
    }
    if (this.timeZone.isPresent) {
      final value = this.timeZone.value;
      json[r'timeZone'] = value;
    }
    if (this.language.isPresent) {
      final value = this.language.value;
      json[r'language'] = value;
    }
    return json;
  }

  /// Clones this instance of [HouseholdUpdate] and returns a new one where some of the
  /// properties have changed.
  HouseholdUpdate copyWith({
    Optional<String?>? name,
    Optional<String?>? city,
    Optional<String?>? timeZone,
    Optional<Language?>? language,
  }) => HouseholdUpdate(
    name: name ?? this.name,
    city: city ?? this.city,
    timeZone: timeZone ?? this.timeZone,
    language: language ?? this.language,
  );

  /// Returns a new [HouseholdUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HouseholdUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return HouseholdUpdate(
        name: json.containsKey(r'name') ? Optional.present(mapValueOfType<String>(json, r'name')) : const Optional.absent(),
        city: json.containsKey(r'city') ? Optional.present(mapValueOfType<String>(json, r'city')) : const Optional.absent(),
        timeZone: json.containsKey(r'timeZone') ? Optional.present(mapValueOfType<String>(json, r'timeZone')) : const Optional.absent(),
        language: json.containsKey(r'language') ? Optional.present(Language.fromJson(json[r'language'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<HouseholdUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HouseholdUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HouseholdUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HouseholdUpdate> mapFromJson(dynamic json) {
    final map = <String, HouseholdUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HouseholdUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HouseholdUpdate-objects as value to a dart map
  static Map<String, List<HouseholdUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HouseholdUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HouseholdUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

