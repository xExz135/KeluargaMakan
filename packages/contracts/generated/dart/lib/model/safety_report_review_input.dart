//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyReportReviewInput {
  /// Returns a new [SafetyReportReviewInput] instance.
  SafetyReportReviewInput({
    required this.outcome,
    required this.note,
    required this.fixReference,
  });

  final SafetyReportOutcome outcome;

  final String? note;

  final String? fixReference;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyReportReviewInput &&
    other.outcome == outcome &&
    other.note == note &&
    other.fixReference == fixReference;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (outcome.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (fixReference == null ? 0 : fixReference!.hashCode);

  @override
  String toString() => 'SafetyReportReviewInput[outcome=$outcome, note=$note, fixReference=$fixReference]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'outcome'] = this.outcome;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.fixReference != null) {
      json[r'fixReference'] = this.fixReference;
    } else {
      json[r'fixReference'] = null;
    }
    return json;
  }

  /// Clones this instance of [SafetyReportReviewInput] and returns a new one where some of the
  /// properties have changed.
  SafetyReportReviewInput copyWith({
    SafetyReportOutcome? outcome,
    String? note,
    bool noteSetToNull = false,
    String? fixReference,
    bool fixReferenceSetToNull = false,
  }) => SafetyReportReviewInput(
    outcome: outcome ?? this.outcome,
    note: noteSetToNull ? null : note ?? this.note,
    fixReference: fixReferenceSetToNull ? null : fixReference ?? this.fixReference,
  );

  /// Returns a new [SafetyReportReviewInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyReportReviewInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'outcome'), 'Required key "SafetyReportReviewInput[outcome]" is missing from JSON.');
        assert(json[r'outcome'] != null, 'Required key "SafetyReportReviewInput[outcome]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "SafetyReportReviewInput[note]" is missing from JSON.');
        assert(json.containsKey(r'fixReference'), 'Required key "SafetyReportReviewInput[fixReference]" is missing from JSON.');
        return true;
      }());

      return SafetyReportReviewInput(
        outcome: SafetyReportOutcome.fromJson(json[r'outcome'])!,
        note: mapValueOfType<String>(json, r'note'),
        fixReference: mapValueOfType<String>(json, r'fixReference'),
      );
    }
    return null;
  }

  static List<SafetyReportReviewInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportReviewInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportReviewInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyReportReviewInput> mapFromJson(dynamic json) {
    final map = <String, SafetyReportReviewInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyReportReviewInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyReportReviewInput-objects as value to a dart map
  static Map<String, List<SafetyReportReviewInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyReportReviewInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyReportReviewInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'outcome',
    'note',
    'fixReference',
  };
}

