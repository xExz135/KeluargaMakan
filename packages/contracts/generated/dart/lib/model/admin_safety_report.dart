//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminSafetyReport {
  /// Returns a new [AdminSafetyReport] instance.
  AdminSafetyReport({
    required this.id,
    required this.receivedAt,
    required this.status,
    required this.subject,
    required this.reportType,
    required this.ingredient,
    required this.note,
    required this.ruleSetVersion,
    required this.referenceVersion,
    this.members = const [],
    required this.review,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final DateTime receivedAt;

  final SafetyReportStatus status;

  final SafetyReportSubject subject;

  final SafetyReportType reportType;

  final SafetyIngredientRef? ingredient;

  final String? note;

  final String ruleSetVersion;

  final String referenceVersion;

  final List<AdminReportMember> members;

  final SafetyReportReview? review;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminSafetyReport &&
    other.id == id &&
    other.receivedAt == receivedAt &&
    other.status == status &&
    other.subject == subject &&
    other.reportType == reportType &&
    other.ingredient == ingredient &&
    other.note == note &&
    other.ruleSetVersion == ruleSetVersion &&
    other.referenceVersion == referenceVersion &&
    _deepEquality.equals(other.members, members) &&
    other.review == review;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (receivedAt.hashCode) +
    (status.hashCode) +
    (subject.hashCode) +
    (reportType.hashCode) +
    (ingredient == null ? 0 : ingredient!.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (ruleSetVersion.hashCode) +
    (referenceVersion.hashCode) +
    (members.hashCode) +
    (review == null ? 0 : review!.hashCode);

  @override
  String toString() => 'AdminSafetyReport[id=$id, receivedAt=$receivedAt, status=$status, subject=$subject, reportType=$reportType, ingredient=$ingredient, note=$note, ruleSetVersion=$ruleSetVersion, referenceVersion=$referenceVersion, members=$members, review=$review]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'receivedAt'] = this.receivedAt.toUtc().toIso8601String();
      json[r'status'] = this.status;
      json[r'subject'] = this.subject;
      json[r'reportType'] = this.reportType;
    if (this.ingredient != null) {
      json[r'ingredient'] = this.ingredient;
    } else {
      json[r'ingredient'] = null;
    }
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'ruleSetVersion'] = this.ruleSetVersion;
      json[r'referenceVersion'] = this.referenceVersion;
      json[r'members'] = this.members;
    if (this.review != null) {
      json[r'review'] = this.review;
    } else {
      json[r'review'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdminSafetyReport] and returns a new one where some of the
  /// properties have changed.
  AdminSafetyReport copyWith({
    String? id,
    DateTime? receivedAt,
    SafetyReportStatus? status,
    SafetyReportSubject? subject,
    SafetyReportType? reportType,
    SafetyIngredientRef? ingredient,
    bool ingredientSetToNull = false,
    String? note,
    bool noteSetToNull = false,
    String? ruleSetVersion,
    String? referenceVersion,
    List<AdminReportMember>? members,
    SafetyReportReview? review,
    bool reviewSetToNull = false,
  }) => AdminSafetyReport(
    id: id ?? this.id,
    receivedAt: receivedAt ?? this.receivedAt,
    status: status ?? this.status,
    subject: subject ?? this.subject,
    reportType: reportType ?? this.reportType,
    ingredient: ingredientSetToNull ? null : ingredient ?? this.ingredient,
    note: noteSetToNull ? null : note ?? this.note,
    ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
    referenceVersion: referenceVersion ?? this.referenceVersion,
    members: members ?? this.members,
    review: reviewSetToNull ? null : review ?? this.review,
  );

  /// Returns a new [AdminSafetyReport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminSafetyReport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "AdminSafetyReport[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "AdminSafetyReport[id]" has a null value in JSON.');
        assert(json.containsKey(r'receivedAt'), 'Required key "AdminSafetyReport[receivedAt]" is missing from JSON.');
        assert(json[r'receivedAt'] != null, 'Required key "AdminSafetyReport[receivedAt]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "AdminSafetyReport[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "AdminSafetyReport[status]" has a null value in JSON.');
        assert(json.containsKey(r'subject'), 'Required key "AdminSafetyReport[subject]" is missing from JSON.');
        assert(json[r'subject'] != null, 'Required key "AdminSafetyReport[subject]" has a null value in JSON.');
        assert(json.containsKey(r'reportType'), 'Required key "AdminSafetyReport[reportType]" is missing from JSON.');
        assert(json[r'reportType'] != null, 'Required key "AdminSafetyReport[reportType]" has a null value in JSON.');
        assert(json.containsKey(r'ingredient'), 'Required key "AdminSafetyReport[ingredient]" is missing from JSON.');
        assert(json.containsKey(r'note'), 'Required key "AdminSafetyReport[note]" is missing from JSON.');
        assert(json.containsKey(r'ruleSetVersion'), 'Required key "AdminSafetyReport[ruleSetVersion]" is missing from JSON.');
        assert(json[r'ruleSetVersion'] != null, 'Required key "AdminSafetyReport[ruleSetVersion]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "AdminSafetyReport[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "AdminSafetyReport[referenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'members'), 'Required key "AdminSafetyReport[members]" is missing from JSON.');
        assert(json[r'members'] != null, 'Required key "AdminSafetyReport[members]" has a null value in JSON.');
        assert(json.containsKey(r'review'), 'Required key "AdminSafetyReport[review]" is missing from JSON.');
        return true;
      }());

      return AdminSafetyReport(
        id: mapValueOfType<String>(json, r'id')!,
        receivedAt: mapDateTime(json, r'receivedAt', r'')!,
        status: SafetyReportStatus.fromJson(json[r'status'])!,
        subject: SafetyReportSubject.fromJson(json[r'subject'])!,
        reportType: SafetyReportType.fromJson(json[r'reportType'])!,
        ingredient: SafetyIngredientRef.fromJson(json[r'ingredient']),
        note: mapValueOfType<String>(json, r'note'),
        ruleSetVersion: mapValueOfType<String>(json, r'ruleSetVersion')!,
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
        members: AdminReportMember.listFromJson(json[r'members']),
        review: SafetyReportReview.fromJson(json[r'review']),
      );
    }
    return null;
  }

  static List<AdminSafetyReport> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminSafetyReport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminSafetyReport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminSafetyReport> mapFromJson(dynamic json) {
    final map = <String, AdminSafetyReport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminSafetyReport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminSafetyReport-objects as value to a dart map
  static Map<String, List<AdminSafetyReport>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminSafetyReport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminSafetyReport.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'receivedAt',
    'status',
    'subject',
    'reportType',
    'ingredient',
    'note',
    'ruleSetVersion',
    'referenceVersion',
    'members',
    'review',
  };
}

