//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class DraftDecisionInput {
  /// Returns a new [DraftDecisionInput] instance.
  DraftDecisionInput({
    required this.expectedRevision,
    required this.decision,
    required this.note,
  });

  /// Minimum value: 1
  final int expectedRevision;

  final DraftDecision decision;

  /// Required when rejecting.
  final String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DraftDecisionInput &&
    other.expectedRevision == expectedRevision &&
    other.decision == decision &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (expectedRevision.hashCode) +
    (decision.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'DraftDecisionInput[expectedRevision=$expectedRevision, decision=$decision, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'expectedRevision'] = this.expectedRevision;
      json[r'decision'] = this.decision;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Clones this instance of [DraftDecisionInput] and returns a new one where some of the
  /// properties have changed.
  DraftDecisionInput copyWith({
    int? expectedRevision,
    DraftDecision? decision,
    String? note,
    bool noteSetToNull = false,
  }) => DraftDecisionInput(
    expectedRevision: expectedRevision ?? this.expectedRevision,
    decision: decision ?? this.decision,
    note: noteSetToNull ? null : note ?? this.note,
  );

  /// Returns a new [DraftDecisionInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DraftDecisionInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expectedRevision'), 'Required key "DraftDecisionInput[expectedRevision]" is missing from JSON.');
        assert(json[r'expectedRevision'] != null, 'Required key "DraftDecisionInput[expectedRevision]" has a null value in JSON.');
        assert(json.containsKey(r'decision'), 'Required key "DraftDecisionInput[decision]" is missing from JSON.');
        assert(json[r'decision'] != null, 'Required key "DraftDecisionInput[decision]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "DraftDecisionInput[note]" is missing from JSON.');
        return true;
      }());

      return DraftDecisionInput(
        expectedRevision: mapValueOfType<int>(json, r'expectedRevision')!,
        decision: DraftDecision.fromJson(json[r'decision'])!,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<DraftDecisionInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DraftDecisionInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DraftDecisionInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DraftDecisionInput> mapFromJson(dynamic json) {
    final map = <String, DraftDecisionInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DraftDecisionInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DraftDecisionInput-objects as value to a dart map
  static Map<String, List<DraftDecisionInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DraftDecisionInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DraftDecisionInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expectedRevision',
    'decision',
    'note',
  };
}

