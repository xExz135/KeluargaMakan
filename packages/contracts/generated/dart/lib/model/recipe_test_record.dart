//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeTestRecord {
  /// Returns a new [RecipeTestRecord] instance.
  RecipeTestRecord({
    required this.testedBy,
    required this.testedOn,
  });

  final String testedBy;

  final DateTime testedOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeTestRecord &&
    other.testedBy == testedBy &&
    other.testedOn == testedOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (testedBy.hashCode) +
    (testedOn.hashCode);

  @override
  String toString() => 'RecipeTestRecord[testedBy=$testedBy, testedOn=$testedOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'testedBy'] = this.testedBy;
      json[r'testedOn'] = _dateFormatter.format(this.testedOn);
    return json;
  }

  /// Clones this instance of [RecipeTestRecord] and returns a new one where some of the
  /// properties have changed.
  RecipeTestRecord copyWith({
    String? testedBy,
    DateTime? testedOn,
  }) => RecipeTestRecord(
    testedBy: testedBy ?? this.testedBy,
    testedOn: testedOn ?? this.testedOn,
  );

  /// Returns a new [RecipeTestRecord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeTestRecord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'testedBy'), 'Required key "RecipeTestRecord[testedBy]" is missing from JSON.');
        assert(json[r'testedBy'] != null, 'Required key "RecipeTestRecord[testedBy]" has a null value in JSON.');
        assert(json.containsKey(r'testedOn'), 'Required key "RecipeTestRecord[testedOn]" is missing from JSON.');
        assert(json[r'testedOn'] != null, 'Required key "RecipeTestRecord[testedOn]" has a null value in JSON.');
        return true;
      }());

      return RecipeTestRecord(
        testedBy: mapValueOfType<String>(json, r'testedBy')!,
        testedOn: mapDateTime(json, r'testedOn', r'')!,
      );
    }
    return null;
  }

  static List<RecipeTestRecord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeTestRecord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeTestRecord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeTestRecord> mapFromJson(dynamic json) {
    final map = <String, RecipeTestRecord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeTestRecord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeTestRecord-objects as value to a dart map
  static Map<String, List<RecipeTestRecord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeTestRecord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeTestRecord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'testedBy',
    'testedOn',
  };
}

