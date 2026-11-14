//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ExpectedConsentState {
  /// Returns a new [ExpectedConsentState] instance.
  ExpectedConsentState({
    required this.status,
    required this.consentRecordId,
  });

  final RulesConsentStatus status;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? consentRecordId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ExpectedConsentState &&
    other.status == status &&
    other.consentRecordId == consentRecordId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (consentRecordId == null ? 0 : consentRecordId!.hashCode);

  @override
  String toString() => 'ExpectedConsentState[status=$status, consentRecordId=$consentRecordId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
    if (this.consentRecordId != null) {
      json[r'consentRecordId'] = this.consentRecordId;
    } else {
      json[r'consentRecordId'] = null;
    }
    return json;
  }

  /// Clones this instance of [ExpectedConsentState] and returns a new one where some of the
  /// properties have changed.
  ExpectedConsentState copyWith({
    RulesConsentStatus? status,
    String? consentRecordId,
    bool consentRecordIdSetToNull = false,
  }) => ExpectedConsentState(
    status: status ?? this.status,
    consentRecordId: consentRecordIdSetToNull ? null : consentRecordId ?? this.consentRecordId,
  );

  /// Returns a new [ExpectedConsentState] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExpectedConsentState? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'), 'Required key "ExpectedConsentState[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "ExpectedConsentState[status]" has a null value in JSON.');
        assert(json.containsKey(r'consentRecordId'), 'Required key "ExpectedConsentState[consentRecordId]" is missing from JSON.');
        return true;
      }());

      return ExpectedConsentState(
        status: RulesConsentStatus.fromJson(json[r'status'])!,
        consentRecordId: mapValueOfType<String>(json, r'consentRecordId'),
      );
    }
    return null;
  }

  static List<ExpectedConsentState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ExpectedConsentState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExpectedConsentState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExpectedConsentState> mapFromJson(dynamic json) {
    final map = <String, ExpectedConsentState>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExpectedConsentState.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExpectedConsentState-objects as value to a dart map
  static Map<String, List<ExpectedConsentState>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ExpectedConsentState>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExpectedConsentState.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'consentRecordId',
  };
}

