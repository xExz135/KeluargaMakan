//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRecipeTestRecord {
  /// Returns a new [AdminRecipeTestRecord] instance.
  AdminRecipeTestRecord({
    required this.testedBy,
    required this.testedOn,
    required this.notes,
    required this.recordedByStaffId,
    required this.recordedAt,
    required this.draftRevision,
  });

  final String testedBy;

  final DateTime testedOn;

  final String? notes;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String recordedByStaffId;

  final DateTime recordedAt;

  /// Minimum value: 1
  final int draftRevision;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRecipeTestRecord &&
    other.testedBy == testedBy &&
    other.testedOn == testedOn &&
    other.notes == notes &&
    other.recordedByStaffId == recordedByStaffId &&
    other.recordedAt == recordedAt &&
    other.draftRevision == draftRevision;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (testedBy.hashCode) +
    (testedOn.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (recordedByStaffId.hashCode) +
    (recordedAt.hashCode) +
    (draftRevision.hashCode);

  @override
  String toString() => 'AdminRecipeTestRecord[testedBy=$testedBy, testedOn=$testedOn, notes=$notes, recordedByStaffId=$recordedByStaffId, recordedAt=$recordedAt, draftRevision=$draftRevision]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'testedBy'] = this.testedBy;
      json[r'testedOn'] = _dateFormatter.format(this.testedOn);
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
      json[r'recordedByStaffId'] = this.recordedByStaffId;
      json[r'recordedAt'] = this.recordedAt.toUtc().toIso8601String();
      json[r'draftRevision'] = this.draftRevision;
    return json;
  }

  /// Clones this instance of [AdminRecipeTestRecord] and returns a new one where some of the
  /// properties have changed.
  AdminRecipeTestRecord copyWith({
    String? testedBy,
    DateTime? testedOn,
    String? notes,
    bool notesSetToNull = false,
    String? recordedByStaffId,
    DateTime? recordedAt,
    int? draftRevision,
  }) => AdminRecipeTestRecord(
    testedBy: testedBy ?? this.testedBy,
    testedOn: testedOn ?? this.testedOn,
    notes: notesSetToNull ? null : notes ?? this.notes,
    recordedByStaffId: recordedByStaffId ?? this.recordedByStaffId,
    recordedAt: recordedAt ?? this.recordedAt,
    draftRevision: draftRevision ?? this.draftRevision,
  );

  /// Returns a new [AdminRecipeTestRecord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRecipeTestRecord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'testedBy'), 'Required key "AdminRecipeTestRecord[testedBy]" is missing from JSON.');
        assert(json[r'testedBy'] != null, 'Required key "AdminRecipeTestRecord[testedBy]" has a null value in JSON.');
        assert(json.containsKey(r'testedOn'), 'Required key "AdminRecipeTestRecord[testedOn]" is missing from JSON.');
        assert(json[r'testedOn'] != null, 'Required key "AdminRecipeTestRecord[testedOn]" has a null value in JSON.');
        assert(json.containsKey(r'notes'), 'Required key "AdminRecipeTestRecord[notes]" is missing from JSON.');
        assert(json.containsKey(r'recordedByStaffId'), 'Required key "AdminRecipeTestRecord[recordedByStaffId]" is missing from JSON.');
        assert(json[r'recordedByStaffId'] != null, 'Required key "AdminRecipeTestRecord[recordedByStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'recordedAt'), 'Required key "AdminRecipeTestRecord[recordedAt]" is missing from JSON.');
        assert(json[r'recordedAt'] != null, 'Required key "AdminRecipeTestRecord[recordedAt]" has a null value in JSON.');
        assert(json.containsKey(r'draftRevision'), 'Required key "AdminRecipeTestRecord[draftRevision]" is missing from JSON.');
        assert(json[r'draftRevision'] != null, 'Required key "AdminRecipeTestRecord[draftRevision]" has a null value in JSON.');
        return true;
      }());

      return AdminRecipeTestRecord(
        testedBy: mapValueOfType<String>(json, r'testedBy')!,
        testedOn: mapDateTime(json, r'testedOn', r'')!,
        notes: mapValueOfType<String>(json, r'notes'),
        recordedByStaffId: mapValueOfType<String>(json, r'recordedByStaffId')!,
        recordedAt: mapDateTime(json, r'recordedAt', r'')!,
        draftRevision: mapValueOfType<int>(json, r'draftRevision')!,
      );
    }
    return null;
  }

  static List<AdminRecipeTestRecord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRecipeTestRecord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRecipeTestRecord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRecipeTestRecord> mapFromJson(dynamic json) {
    final map = <String, AdminRecipeTestRecord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRecipeTestRecord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRecipeTestRecord-objects as value to a dart map
  static Map<String, List<AdminRecipeTestRecord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRecipeTestRecord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRecipeTestRecord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'testedBy',
    'testedOn',
    'notes',
    'recordedByStaffId',
    'recordedAt',
    'draftRevision',
  };
}

