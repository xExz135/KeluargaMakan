//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeTestRecordInput {
  /// Returns a new [RecipeTestRecordInput] instance.
  RecipeTestRecordInput({
    required this.expectedRevision,
    required this.testedBy,
    required this.testedOn,
    this.notes = const Optional.absent(),
  });

  /// Minimum value: 1
  final int expectedRevision;

  final String testedBy;

  final DateTime testedOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeTestRecordInput &&
    other.expectedRevision == expectedRevision &&
    other.testedBy == testedBy &&
    other.testedOn == testedOn &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (expectedRevision.hashCode) +
    (testedBy.hashCode) +
    (testedOn.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'RecipeTestRecordInput[expectedRevision=$expectedRevision, testedBy=$testedBy, testedOn=$testedOn, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'expectedRevision'] = this.expectedRevision;
      json[r'testedBy'] = this.testedBy;
      json[r'testedOn'] = _dateFormatter.format(this.testedOn);
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    return json;
  }

  /// Clones this instance of [RecipeTestRecordInput] and returns a new one where some of the
  /// properties have changed.
  RecipeTestRecordInput copyWith({
    int? expectedRevision,
    String? testedBy,
    DateTime? testedOn,
    Optional<String?>? notes,
  }) => RecipeTestRecordInput(
    expectedRevision: expectedRevision ?? this.expectedRevision,
    testedBy: testedBy ?? this.testedBy,
    testedOn: testedOn ?? this.testedOn,
    notes: notes ?? this.notes,
  );

  /// Returns a new [RecipeTestRecordInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeTestRecordInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expectedRevision'), 'Required key "RecipeTestRecordInput[expectedRevision]" is missing from JSON.');
        assert(json[r'expectedRevision'] != null, 'Required key "RecipeTestRecordInput[expectedRevision]" has a null value in JSON.');
        assert(json.containsKey(r'testedBy'), 'Required key "RecipeTestRecordInput[testedBy]" is missing from JSON.');
        assert(json[r'testedBy'] != null, 'Required key "RecipeTestRecordInput[testedBy]" has a null value in JSON.');
        assert(json.containsKey(r'testedOn'), 'Required key "RecipeTestRecordInput[testedOn]" is missing from JSON.');
        assert(json[r'testedOn'] != null, 'Required key "RecipeTestRecordInput[testedOn]" has a null value in JSON.');
        return true;
      }());

      return RecipeTestRecordInput(
        expectedRevision: mapValueOfType<int>(json, r'expectedRevision')!,
        testedBy: mapValueOfType<String>(json, r'testedBy')!,
        testedOn: mapDateTime(json, r'testedOn', r'')!,
        notes: json.containsKey(r'notes') ? Optional.present(mapValueOfType<String>(json, r'notes')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<RecipeTestRecordInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeTestRecordInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeTestRecordInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeTestRecordInput> mapFromJson(dynamic json) {
    final map = <String, RecipeTestRecordInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeTestRecordInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeTestRecordInput-objects as value to a dart map
  static Map<String, List<RecipeTestRecordInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeTestRecordInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeTestRecordInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expectedRevision',
    'testedBy',
    'testedOn',
  };
}

