//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ReferenceVersions {
  /// Returns a new [ReferenceVersions] instance.
  ReferenceVersions({
    required this.ruleSetVersion,
    required this.referenceVersion,
    required this.libraryVersion,
    required this.refreshWithinHours,
  });

  /// Cek Aman rule-set version.
  final String ruleSetVersion;

  /// Version and content hash of the verified reference ingredient data.
  final String referenceVersion;

  /// Version of the published recipe library; changes whenever a recipe is published or retired.
  final String libraryVersion;

  /// Minimum value: 1
  final int refreshWithinHours;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReferenceVersions &&
    other.ruleSetVersion == ruleSetVersion &&
    other.referenceVersion == referenceVersion &&
    other.libraryVersion == libraryVersion &&
    other.refreshWithinHours == refreshWithinHours;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ruleSetVersion.hashCode) +
    (referenceVersion.hashCode) +
    (libraryVersion.hashCode) +
    (refreshWithinHours.hashCode);

  @override
  String toString() => 'ReferenceVersions[ruleSetVersion=$ruleSetVersion, referenceVersion=$referenceVersion, libraryVersion=$libraryVersion, refreshWithinHours=$refreshWithinHours]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ruleSetVersion'] = this.ruleSetVersion;
      json[r'referenceVersion'] = this.referenceVersion;
      json[r'libraryVersion'] = this.libraryVersion;
      json[r'refreshWithinHours'] = this.refreshWithinHours;
    return json;
  }

  /// Clones this instance of [ReferenceVersions] and returns a new one where some of the
  /// properties have changed.
  ReferenceVersions copyWith({
    String? ruleSetVersion,
    String? referenceVersion,
    String? libraryVersion,
    int? refreshWithinHours,
  }) => ReferenceVersions(
    ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
    referenceVersion: referenceVersion ?? this.referenceVersion,
    libraryVersion: libraryVersion ?? this.libraryVersion,
    refreshWithinHours: refreshWithinHours ?? this.refreshWithinHours,
  );

  /// Returns a new [ReferenceVersions] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReferenceVersions? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ruleSetVersion'), 'Required key "ReferenceVersions[ruleSetVersion]" is missing from JSON.');
        assert(json[r'ruleSetVersion'] != null, 'Required key "ReferenceVersions[ruleSetVersion]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "ReferenceVersions[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "ReferenceVersions[referenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'libraryVersion'), 'Required key "ReferenceVersions[libraryVersion]" is missing from JSON.');
        assert(json[r'libraryVersion'] != null, 'Required key "ReferenceVersions[libraryVersion]" has a null value in JSON.');
        assert(json.containsKey(r'refreshWithinHours'), 'Required key "ReferenceVersions[refreshWithinHours]" is missing from JSON.');
        assert(json[r'refreshWithinHours'] != null, 'Required key "ReferenceVersions[refreshWithinHours]" has a null value in JSON.');
        return true;
      }());

      return ReferenceVersions(
        ruleSetVersion: mapValueOfType<String>(json, r'ruleSetVersion')!,
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
        libraryVersion: mapValueOfType<String>(json, r'libraryVersion')!,
        refreshWithinHours: mapValueOfType<int>(json, r'refreshWithinHours')!,
      );
    }
    return null;
  }

  static List<ReferenceVersions> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReferenceVersions>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReferenceVersions.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReferenceVersions> mapFromJson(dynamic json) {
    final map = <String, ReferenceVersions>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReferenceVersions.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReferenceVersions-objects as value to a dart map
  static Map<String, List<ReferenceVersions>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReferenceVersions>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReferenceVersions.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ruleSetVersion',
    'referenceVersion',
    'libraryVersion',
    'refreshWithinHours',
  };
}

