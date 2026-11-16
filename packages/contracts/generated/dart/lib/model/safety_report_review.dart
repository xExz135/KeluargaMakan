//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyReportReview {
  /// Returns a new [SafetyReportReview] instance.
  SafetyReportReview({
    required this.outcome,
    required this.reviewerStaffId,
    required this.reviewedAt,
    required this.note,
    required this.fixReference,
  });

  final SafetyReportOutcome outcome;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String reviewerStaffId;

  final DateTime reviewedAt;

  final String? note;

  /// What fixed it, for example an ingredient draft ID.
  final String? fixReference;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyReportReview &&
    other.outcome == outcome &&
    other.reviewerStaffId == reviewerStaffId &&
    other.reviewedAt == reviewedAt &&
    other.note == note &&
    other.fixReference == fixReference;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (outcome.hashCode) +
    (reviewerStaffId.hashCode) +
    (reviewedAt.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (fixReference == null ? 0 : fixReference!.hashCode);

  @override
  String toString() => 'SafetyReportReview[outcome=$outcome, reviewerStaffId=$reviewerStaffId, reviewedAt=$reviewedAt, note=$note, fixReference=$fixReference]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'outcome'] = this.outcome;
      json[r'reviewerStaffId'] = this.reviewerStaffId;
      json[r'reviewedAt'] = this.reviewedAt.toUtc().toIso8601String();
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

  /// Clones this instance of [SafetyReportReview] and returns a new one where some of the
  /// properties have changed.
  SafetyReportReview copyWith({
    SafetyReportOutcome? outcome,
    String? reviewerStaffId,
    DateTime? reviewedAt,
    String? note,
    bool noteSetToNull = false,
    String? fixReference,
    bool fixReferenceSetToNull = false,
  }) => SafetyReportReview(
    outcome: outcome ?? this.outcome,
    reviewerStaffId: reviewerStaffId ?? this.reviewerStaffId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    note: noteSetToNull ? null : note ?? this.note,
    fixReference: fixReferenceSetToNull ? null : fixReference ?? this.fixReference,
  );

  /// Returns a new [SafetyReportReview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyReportReview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'outcome'), 'Required key "SafetyReportReview[outcome]" is missing from JSON.');
        assert(json[r'outcome'] != null, 'Required key "SafetyReportReview[outcome]" has a null value in JSON.');
        assert(json.containsKey(r'reviewerStaffId'), 'Required key "SafetyReportReview[reviewerStaffId]" is missing from JSON.');
        assert(json[r'reviewerStaffId'] != null, 'Required key "SafetyReportReview[reviewerStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'reviewedAt'), 'Required key "SafetyReportReview[reviewedAt]" is missing from JSON.');
        assert(json[r'reviewedAt'] != null, 'Required key "SafetyReportReview[reviewedAt]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "SafetyReportReview[note]" is missing from JSON.');
        assert(json.containsKey(r'fixReference'), 'Required key "SafetyReportReview[fixReference]" is missing from JSON.');
        return true;
      }());

      return SafetyReportReview(
        outcome: SafetyReportOutcome.fromJson(json[r'outcome'])!,
        reviewerStaffId: mapValueOfType<String>(json, r'reviewerStaffId')!,
        reviewedAt: mapDateTime(json, r'reviewedAt', r'')!,
        note: mapValueOfType<String>(json, r'note'),
        fixReference: mapValueOfType<String>(json, r'fixReference'),
      );
    }
    return null;
  }

  static List<SafetyReportReview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportReview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportReview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyReportReview> mapFromJson(dynamic json) {
    final map = <String, SafetyReportReview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyReportReview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyReportReview-objects as value to a dart map
  static Map<String, List<SafetyReportReview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyReportReview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyReportReview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'outcome',
    'reviewerStaffId',
    'reviewedAt',
    'note',
    'fixReference',
  };
}

