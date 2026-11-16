//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyReportCreate {
  /// Returns a new [SafetyReportCreate] instance.
  SafetyReportCreate({
    required this.subject,
    required this.checkId,
    required this.ruleSetVersion,
    required this.referenceVersion,
    this.memberIds = const {},
    required this.reportType,
    required this.ingredientLineId,
    required this.note,
  });

  final SafetyReportSubject subject;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String checkId;

  final String ruleSetVersion;

  final String referenceVersion;

  /// The members the report is about, from the check's members.
  final Set<String> memberIds;

  final SafetyReportType reportType;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? ingredientLineId;

  final String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyReportCreate &&
    other.subject == subject &&
    other.checkId == checkId &&
    other.ruleSetVersion == ruleSetVersion &&
    other.referenceVersion == referenceVersion &&
    _deepEquality.equals(other.memberIds, memberIds) &&
    other.reportType == reportType &&
    other.ingredientLineId == ingredientLineId &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (subject.hashCode) +
    (checkId.hashCode) +
    (ruleSetVersion.hashCode) +
    (referenceVersion.hashCode) +
    (memberIds.hashCode) +
    (reportType.hashCode) +
    (ingredientLineId == null ? 0 : ingredientLineId!.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'SafetyReportCreate[subject=$subject, checkId=$checkId, ruleSetVersion=$ruleSetVersion, referenceVersion=$referenceVersion, memberIds=$memberIds, reportType=$reportType, ingredientLineId=$ingredientLineId, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'subject'] = this.subject;
      json[r'checkId'] = this.checkId;
      json[r'ruleSetVersion'] = this.ruleSetVersion;
      json[r'referenceVersion'] = this.referenceVersion;
      json[r'memberIds'] = this.memberIds.toList(growable: false);
      json[r'reportType'] = this.reportType;
    if (this.ingredientLineId != null) {
      json[r'ingredientLineId'] = this.ingredientLineId;
    } else {
      json[r'ingredientLineId'] = null;
    }
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Clones this instance of [SafetyReportCreate] and returns a new one where some of the
  /// properties have changed.
  SafetyReportCreate copyWith({
    SafetyReportSubject? subject,
    String? checkId,
    String? ruleSetVersion,
    String? referenceVersion,
    Set<String>? memberIds,
    SafetyReportType? reportType,
    String? ingredientLineId,
    bool ingredientLineIdSetToNull = false,
    String? note,
    bool noteSetToNull = false,
  }) => SafetyReportCreate(
    subject: subject ?? this.subject,
    checkId: checkId ?? this.checkId,
    ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
    referenceVersion: referenceVersion ?? this.referenceVersion,
    memberIds: memberIds ?? this.memberIds,
    reportType: reportType ?? this.reportType,
    ingredientLineId: ingredientLineIdSetToNull ? null : ingredientLineId ?? this.ingredientLineId,
    note: noteSetToNull ? null : note ?? this.note,
  );

  /// Returns a new [SafetyReportCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyReportCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'subject'), 'Required key "SafetyReportCreate[subject]" is missing from JSON.');
        assert(json[r'subject'] != null, 'Required key "SafetyReportCreate[subject]" has a null value in JSON.');
        assert(json.containsKey(r'checkId'), 'Required key "SafetyReportCreate[checkId]" is missing from JSON.');
        assert(json[r'checkId'] != null, 'Required key "SafetyReportCreate[checkId]" has a null value in JSON.');
        assert(json.containsKey(r'ruleSetVersion'), 'Required key "SafetyReportCreate[ruleSetVersion]" is missing from JSON.');
        assert(json[r'ruleSetVersion'] != null, 'Required key "SafetyReportCreate[ruleSetVersion]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "SafetyReportCreate[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "SafetyReportCreate[referenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'memberIds'), 'Required key "SafetyReportCreate[memberIds]" is missing from JSON.');
        assert(json[r'memberIds'] != null, 'Required key "SafetyReportCreate[memberIds]" has a null value in JSON.');
        assert(json.containsKey(r'reportType'), 'Required key "SafetyReportCreate[reportType]" is missing from JSON.');
        assert(json[r'reportType'] != null, 'Required key "SafetyReportCreate[reportType]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientLineId'), 'Required key "SafetyReportCreate[ingredientLineId]" is missing from JSON.');
        assert(json.containsKey(r'note'), 'Required key "SafetyReportCreate[note]" is missing from JSON.');
        return true;
      }());

      return SafetyReportCreate(
        subject: SafetyReportSubject.fromJson(json[r'subject'])!,
        checkId: mapValueOfType<String>(json, r'checkId')!,
        ruleSetVersion: mapValueOfType<String>(json, r'ruleSetVersion')!,
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
        memberIds: json[r'memberIds'] is Iterable
            ? (json[r'memberIds'] as Iterable).cast<String>().toSet()
            : const {},
        reportType: SafetyReportType.fromJson(json[r'reportType'])!,
        ingredientLineId: mapValueOfType<String>(json, r'ingredientLineId'),
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<SafetyReportCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyReportCreate> mapFromJson(dynamic json) {
    final map = <String, SafetyReportCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyReportCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyReportCreate-objects as value to a dart map
  static Map<String, List<SafetyReportCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyReportCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyReportCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'subject',
    'checkId',
    'ruleSetVersion',
    'referenceVersion',
    'memberIds',
    'reportType',
    'ingredientLineId',
    'note',
  };
}

