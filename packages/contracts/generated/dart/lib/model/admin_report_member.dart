//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminReportMember {
  /// Returns a new [AdminReportMember] instance.
  AdminReportMember({
    required this.memberLabel,
    required this.status,
    this.rules = const [],
    this.findings = const [],
  });

  final String memberLabel;

  final SafetyStatus? status;

  final List<AdminRuleSummary> rules;

  final List<SafetyFinding> findings;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminReportMember &&
    other.memberLabel == memberLabel &&
    other.status == status &&
    _deepEquality.equals(other.rules, rules) &&
    _deepEquality.equals(other.findings, findings);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memberLabel.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (rules.hashCode) +
    (findings.hashCode);

  @override
  String toString() => 'AdminReportMember[memberLabel=$memberLabel, status=$status, rules=$rules, findings=$findings]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'memberLabel'] = this.memberLabel;
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
      json[r'rules'] = this.rules;
      json[r'findings'] = this.findings;
    return json;
  }

  /// Clones this instance of [AdminReportMember] and returns a new one where some of the
  /// properties have changed.
  AdminReportMember copyWith({
    String? memberLabel,
    SafetyStatus? status,
    bool statusSetToNull = false,
    List<AdminRuleSummary>? rules,
    List<SafetyFinding>? findings,
  }) => AdminReportMember(
    memberLabel: memberLabel ?? this.memberLabel,
    status: statusSetToNull ? null : status ?? this.status,
    rules: rules ?? this.rules,
    findings: findings ?? this.findings,
  );

  /// Returns a new [AdminReportMember] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminReportMember? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'memberLabel'), 'Required key "AdminReportMember[memberLabel]" is missing from JSON.');
        assert(json[r'memberLabel'] != null, 'Required key "AdminReportMember[memberLabel]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "AdminReportMember[status]" is missing from JSON.');
        assert(json.containsKey(r'rules'), 'Required key "AdminReportMember[rules]" is missing from JSON.');
        assert(json[r'rules'] != null, 'Required key "AdminReportMember[rules]" has a null value in JSON.');
        assert(json.containsKey(r'findings'), 'Required key "AdminReportMember[findings]" is missing from JSON.');
        assert(json[r'findings'] != null, 'Required key "AdminReportMember[findings]" has a null value in JSON.');
        return true;
      }());

      return AdminReportMember(
        memberLabel: mapValueOfType<String>(json, r'memberLabel')!,
        status: SafetyStatus.fromJson(json[r'status']),
        rules: AdminRuleSummary.listFromJson(json[r'rules']),
        findings: SafetyFinding.listFromJson(json[r'findings']),
      );
    }
    return null;
  }

  static List<AdminReportMember> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminReportMember>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminReportMember.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminReportMember> mapFromJson(dynamic json) {
    final map = <String, AdminReportMember>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminReportMember.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminReportMember-objects as value to a dart map
  static Map<String, List<AdminReportMember>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminReportMember>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminReportMember.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'memberLabel',
    'status',
    'rules',
    'findings',
  };
}

