//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class DraftRevisionInput {
  /// Returns a new [DraftRevisionInput] instance.
  DraftRevisionInput({
    required this.expectedRevision,
  });

  /// The draft revision the staff member was shown (409 `draft_changed` when it moved).
  ///
  /// Minimum value: 1
  final int expectedRevision;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DraftRevisionInput &&
    other.expectedRevision == expectedRevision;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (expectedRevision.hashCode);

  @override
  String toString() => 'DraftRevisionInput[expectedRevision=$expectedRevision]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'expectedRevision'] = this.expectedRevision;
    return json;
  }

  /// Clones this instance of [DraftRevisionInput] and returns a new one where some of the
  /// properties have changed.
  DraftRevisionInput copyWith({
    int? expectedRevision,
  }) => DraftRevisionInput(
    expectedRevision: expectedRevision ?? this.expectedRevision,
  );

  /// Returns a new [DraftRevisionInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DraftRevisionInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expectedRevision'), 'Required key "DraftRevisionInput[expectedRevision]" is missing from JSON.');
        assert(json[r'expectedRevision'] != null, 'Required key "DraftRevisionInput[expectedRevision]" has a null value in JSON.');
        return true;
      }());

      return DraftRevisionInput(
        expectedRevision: mapValueOfType<int>(json, r'expectedRevision')!,
      );
    }
    return null;
  }

  static List<DraftRevisionInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DraftRevisionInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DraftRevisionInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DraftRevisionInput> mapFromJson(dynamic json) {
    final map = <String, DraftRevisionInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DraftRevisionInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DraftRevisionInput-objects as value to a dart map
  static Map<String, List<DraftRevisionInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DraftRevisionInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DraftRevisionInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expectedRevision',
  };
}

