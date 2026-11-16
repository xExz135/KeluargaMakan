//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class MemberSafetyResult {
  /// Returns a new [MemberSafetyResult] instance.
  MemberSafetyResult({
    required this.memberId,
    required this.rulesConsent,
    required this.status,
    required this.condition,
    this.reasons = const [],
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String memberId;

  final RulesConsentStatus rulesConsent;

  final SafetyStatus status;

  final SafetyCondition? condition;

  /// Empty for `safe`; at least one for the other states.
  final List<SafetyReason> reasons;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MemberSafetyResult &&
    other.memberId == memberId &&
    other.rulesConsent == rulesConsent &&
    other.status == status &&
    other.condition == condition &&
    _deepEquality.equals(other.reasons, reasons);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memberId.hashCode) +
    (rulesConsent.hashCode) +
    (status.hashCode) +
    (condition == null ? 0 : condition!.hashCode) +
    (reasons.hashCode);

  @override
  String toString() => 'MemberSafetyResult[memberId=$memberId, rulesConsent=$rulesConsent, status=$status, condition=$condition, reasons=$reasons]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'memberId'] = this.memberId;
      json[r'rulesConsent'] = this.rulesConsent;
      json[r'status'] = this.status;
    if (this.condition != null) {
      json[r'condition'] = this.condition;
    } else {
      json[r'condition'] = null;
    }
      json[r'reasons'] = this.reasons;
    return json;
  }

  /// Clones this instance of [MemberSafetyResult] and returns a new one where some of the
  /// properties have changed.
  MemberSafetyResult copyWith({
    String? memberId,
    RulesConsentStatus? rulesConsent,
    SafetyStatus? status,
    SafetyCondition? condition,
    bool conditionSetToNull = false,
    List<SafetyReason>? reasons,
  }) => MemberSafetyResult(
    memberId: memberId ?? this.memberId,
    rulesConsent: rulesConsent ?? this.rulesConsent,
    status: status ?? this.status,
    condition: conditionSetToNull ? null : condition ?? this.condition,
    reasons: reasons ?? this.reasons,
  );

  /// Returns a new [MemberSafetyResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemberSafetyResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'memberId'), 'Required key "MemberSafetyResult[memberId]" is missing from JSON.');
        assert(json[r'memberId'] != null, 'Required key "MemberSafetyResult[memberId]" has a null value in JSON.');
        assert(json.containsKey(r'rulesConsent'), 'Required key "MemberSafetyResult[rulesConsent]" is missing from JSON.');
        assert(json[r'rulesConsent'] != null, 'Required key "MemberSafetyResult[rulesConsent]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "MemberSafetyResult[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "MemberSafetyResult[status]" has a null value in JSON.');
        assert(json.containsKey(r'condition'), 'Required key "MemberSafetyResult[condition]" is missing from JSON.');
        assert(json.containsKey(r'reasons'), 'Required key "MemberSafetyResult[reasons]" is missing from JSON.');
        assert(json[r'reasons'] != null, 'Required key "MemberSafetyResult[reasons]" has a null value in JSON.');
        return true;
      }());

      return MemberSafetyResult(
        memberId: mapValueOfType<String>(json, r'memberId')!,
        rulesConsent: RulesConsentStatus.fromJson(json[r'rulesConsent'])!,
        status: SafetyStatus.fromJson(json[r'status'])!,
        condition: SafetyCondition.fromJson(json[r'condition']),
        reasons: SafetyReason.listFromJson(json[r'reasons']),
      );
    }
    return null;
  }

  static List<MemberSafetyResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MemberSafetyResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemberSafetyResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemberSafetyResult> mapFromJson(dynamic json) {
    final map = <String, MemberSafetyResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemberSafetyResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemberSafetyResult-objects as value to a dart map
  static Map<String, List<MemberSafetyResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MemberSafetyResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemberSafetyResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'memberId',
    'rulesConsent',
    'status',
    'condition',
    'reasons',
  };
}

