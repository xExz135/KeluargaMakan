//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RulesConsentState {
  /// Returns a new [RulesConsentState] instance.
  RulesConsentState({
    required this.status,
    required this.consentRecordId,
    required this.decidedAt,
    required this.textVersion,
    required this.deletionDueBy,
  });

  final RulesConsentStatus status;

  /// The latest health-data consent record, or null for `none`.
  final String? consentRecordId;

  final DateTime? decidedAt;

  final String? textVersion;

  /// For `withdrawn`, when stored rules will have been deleted (SET-04).
  final DateTime? deletionDueBy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RulesConsentState &&
    other.status == status &&
    other.consentRecordId == consentRecordId &&
    other.decidedAt == decidedAt &&
    other.textVersion == textVersion &&
    other.deletionDueBy == deletionDueBy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (consentRecordId == null ? 0 : consentRecordId!.hashCode) +
    (decidedAt == null ? 0 : decidedAt!.hashCode) +
    (textVersion == null ? 0 : textVersion!.hashCode) +
    (deletionDueBy == null ? 0 : deletionDueBy!.hashCode);

  @override
  String toString() => 'RulesConsentState[status=$status, consentRecordId=$consentRecordId, decidedAt=$decidedAt, textVersion=$textVersion, deletionDueBy=$deletionDueBy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
    if (this.consentRecordId != null) {
      json[r'consentRecordId'] = this.consentRecordId;
    } else {
      json[r'consentRecordId'] = null;
    }
    if (this.decidedAt != null) {
      json[r'decidedAt'] = this.decidedAt!.toUtc().toIso8601String();
    } else {
      json[r'decidedAt'] = null;
    }
    if (this.textVersion != null) {
      json[r'textVersion'] = this.textVersion;
    } else {
      json[r'textVersion'] = null;
    }
    if (this.deletionDueBy != null) {
      json[r'deletionDueBy'] = this.deletionDueBy!.toUtc().toIso8601String();
    } else {
      json[r'deletionDueBy'] = null;
    }
    return json;
  }

  /// Clones this instance of [RulesConsentState] and returns a new one where some of the
  /// properties have changed.
  RulesConsentState copyWith({
    RulesConsentStatus? status,
    String? consentRecordId,
    bool consentRecordIdSetToNull = false,
    DateTime? decidedAt,
    bool decidedAtSetToNull = false,
    String? textVersion,
    bool textVersionSetToNull = false,
    DateTime? deletionDueBy,
    bool deletionDueBySetToNull = false,
  }) => RulesConsentState(
    status: status ?? this.status,
    consentRecordId: consentRecordIdSetToNull ? null : consentRecordId ?? this.consentRecordId,
    decidedAt: decidedAtSetToNull ? null : decidedAt ?? this.decidedAt,
    textVersion: textVersionSetToNull ? null : textVersion ?? this.textVersion,
    deletionDueBy: deletionDueBySetToNull ? null : deletionDueBy ?? this.deletionDueBy,
  );

  /// Returns a new [RulesConsentState] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RulesConsentState? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'), 'Required key "RulesConsentState[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "RulesConsentState[status]" has a null value in JSON.');
        assert(json.containsKey(r'consentRecordId'), 'Required key "RulesConsentState[consentRecordId]" is missing from JSON.');
        assert(json.containsKey(r'decidedAt'), 'Required key "RulesConsentState[decidedAt]" is missing from JSON.');
        assert(json.containsKey(r'textVersion'), 'Required key "RulesConsentState[textVersion]" is missing from JSON.');
        assert(json.containsKey(r'deletionDueBy'), 'Required key "RulesConsentState[deletionDueBy]" is missing from JSON.');
        return true;
      }());

      return RulesConsentState(
        status: RulesConsentStatus.fromJson(json[r'status'])!,
        consentRecordId: mapValueOfType<String>(json, r'consentRecordId'),
        decidedAt: mapDateTime(json, r'decidedAt', r''),
        textVersion: mapValueOfType<String>(json, r'textVersion'),
        deletionDueBy: mapDateTime(json, r'deletionDueBy', r''),
      );
    }
    return null;
  }

  static List<RulesConsentState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RulesConsentState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RulesConsentState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RulesConsentState> mapFromJson(dynamic json) {
    final map = <String, RulesConsentState>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RulesConsentState.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RulesConsentState-objects as value to a dart map
  static Map<String, List<RulesConsentState>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RulesConsentState>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RulesConsentState.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'consentRecordId',
    'decidedAt',
    'textVersion',
    'deletionDueBy',
  };
}

