//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeRetireInput {
  /// Returns a new [RecipeRetireInput] instance.
  RecipeRetireInput({
    required this.expectedVersion,
    required this.note,
  });

  /// Minimum value: 1
  final int expectedVersion;

  final String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeRetireInput &&
    other.expectedVersion == expectedVersion &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (expectedVersion.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'RecipeRetireInput[expectedVersion=$expectedVersion, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'expectedVersion'] = this.expectedVersion;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Clones this instance of [RecipeRetireInput] and returns a new one where some of the
  /// properties have changed.
  RecipeRetireInput copyWith({
    int? expectedVersion,
    String? note,
    bool noteSetToNull = false,
  }) => RecipeRetireInput(
    expectedVersion: expectedVersion ?? this.expectedVersion,
    note: noteSetToNull ? null : note ?? this.note,
  );

  /// Returns a new [RecipeRetireInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeRetireInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expectedVersion'), 'Required key "RecipeRetireInput[expectedVersion]" is missing from JSON.');
        assert(json[r'expectedVersion'] != null, 'Required key "RecipeRetireInput[expectedVersion]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "RecipeRetireInput[note]" is missing from JSON.');
        return true;
      }());

      return RecipeRetireInput(
        expectedVersion: mapValueOfType<int>(json, r'expectedVersion')!,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<RecipeRetireInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeRetireInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeRetireInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeRetireInput> mapFromJson(dynamic json) {
    final map = <String, RecipeRetireInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeRetireInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeRetireInput-objects as value to a dart map
  static Map<String, List<RecipeRetireInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeRetireInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeRetireInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expectedVersion',
    'note',
  };
}

