//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class DraftReview {
  /// Returns a new [DraftReview] instance.
  DraftReview({
    required this.decision,
    required this.reviewerStaffId,
    required this.decidedAt,
    required this.note,
  });

  final DraftDecision decision;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String reviewerStaffId;

  final DateTime decidedAt;

  final String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DraftReview &&
    other.decision == decision &&
    other.reviewerStaffId == reviewerStaffId &&
    other.decidedAt == decidedAt &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (decision.hashCode) +
    (reviewerStaffId.hashCode) +
    (decidedAt.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'DraftReview[decision=$decision, reviewerStaffId=$reviewerStaffId, decidedAt=$decidedAt, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'decision'] = this.decision;
      json[r'reviewerStaffId'] = this.reviewerStaffId;
      json[r'decidedAt'] = this.decidedAt.toUtc().toIso8601String();
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Clones this instance of [DraftReview] and returns a new one where some of the
  /// properties have changed.
  DraftReview copyWith({
    DraftDecision? decision,
    String? reviewerStaffId,
    DateTime? decidedAt,
    String? note,
    bool noteSetToNull = false,
  }) => DraftReview(
    decision: decision ?? this.decision,
    reviewerStaffId: reviewerStaffId ?? this.reviewerStaffId,
    decidedAt: decidedAt ?? this.decidedAt,
    note: noteSetToNull ? null : note ?? this.note,
  );

  /// Returns a new [DraftReview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DraftReview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'decision'), 'Required key "DraftReview[decision]" is missing from JSON.');
        assert(json[r'decision'] != null, 'Required key "DraftReview[decision]" has a null value in JSON.');
        assert(json.containsKey(r'reviewerStaffId'), 'Required key "DraftReview[reviewerStaffId]" is missing from JSON.');
        assert(json[r'reviewerStaffId'] != null, 'Required key "DraftReview[reviewerStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'decidedAt'), 'Required key "DraftReview[decidedAt]" is missing from JSON.');
        assert(json[r'decidedAt'] != null, 'Required key "DraftReview[decidedAt]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "DraftReview[note]" is missing from JSON.');
        return true;
      }());

      return DraftReview(
        decision: DraftDecision.fromJson(json[r'decision'])!,
        reviewerStaffId: mapValueOfType<String>(json, r'reviewerStaffId')!,
        decidedAt: mapDateTime(json, r'decidedAt', r'')!,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<DraftReview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DraftReview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DraftReview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DraftReview> mapFromJson(dynamic json) {
    final map = <String, DraftReview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DraftReview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DraftReview-objects as value to a dart map
  static Map<String, List<DraftReview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DraftReview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DraftReview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'decision',
    'reviewerStaffId',
    'decidedAt',
    'note',
  };
}

