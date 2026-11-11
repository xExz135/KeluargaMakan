//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HouseholdCreate {
  /// Returns a new [HouseholdCreate] instance.
  HouseholdCreate({
    this.name = const Optional.absent(),
    this.city = const Optional.absent(),
    required this.timeZone,
    required this.language,
    required this.managerProfile,
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
  final String timeZone;

  final Language language;

  final ManagerProfileCreate managerProfile;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HouseholdCreate &&
    other.name == name &&
    other.city == city &&
    other.timeZone == timeZone &&
    other.language == language &&
    other.managerProfile == managerProfile;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (city == null ? 0 : city!.hashCode) +
    (timeZone.hashCode) +
    (language.hashCode) +
    (managerProfile.hashCode);

  @override
  String toString() => 'HouseholdCreate[name=$name, city=$city, timeZone=$timeZone, language=$language, managerProfile=$managerProfile]';

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
      json[r'timeZone'] = this.timeZone;
      json[r'language'] = this.language;
      json[r'managerProfile'] = this.managerProfile;
    return json;
  }

  /// Clones this instance of [HouseholdCreate] and returns a new one where some of the
  /// properties have changed.
  HouseholdCreate copyWith({
    Optional<String?>? name,
    Optional<String?>? city,
    String? timeZone,
    Language? language,
    ManagerProfileCreate? managerProfile,
  }) => HouseholdCreate(
    name: name ?? this.name,
    city: city ?? this.city,
    timeZone: timeZone ?? this.timeZone,
    language: language ?? this.language,
    managerProfile: managerProfile ?? this.managerProfile,
  );

  /// Returns a new [HouseholdCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HouseholdCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'timeZone'), 'Required key "HouseholdCreate[timeZone]" is missing from JSON.');
        assert(json[r'timeZone'] != null, 'Required key "HouseholdCreate[timeZone]" has a null value in JSON.');
        assert(json.containsKey(r'language'), 'Required key "HouseholdCreate[language]" is missing from JSON.');
        assert(json[r'language'] != null, 'Required key "HouseholdCreate[language]" has a null value in JSON.');
        assert(json.containsKey(r'managerProfile'), 'Required key "HouseholdCreate[managerProfile]" is missing from JSON.');
        assert(json[r'managerProfile'] != null, 'Required key "HouseholdCreate[managerProfile]" has a null value in JSON.');
        return true;
      }());

      return HouseholdCreate(
        name: json.containsKey(r'name') ? Optional.present(mapValueOfType<String>(json, r'name')) : const Optional.absent(),
        city: json.containsKey(r'city') ? Optional.present(mapValueOfType<String>(json, r'city')) : const Optional.absent(),
        timeZone: mapValueOfType<String>(json, r'timeZone')!,
        language: Language.fromJson(json[r'language'])!,
        managerProfile: ManagerProfileCreate.fromJson(json[r'managerProfile'])!,
      );
    }
    return null;
  }

  static List<HouseholdCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HouseholdCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HouseholdCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HouseholdCreate> mapFromJson(dynamic json) {
    final map = <String, HouseholdCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HouseholdCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HouseholdCreate-objects as value to a dart map
  static Map<String, List<HouseholdCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HouseholdCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HouseholdCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'timeZone',
    'language',
    'managerProfile',
  };
}

