//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ConsentRecord {
  /// Returns a new [ConsentRecord] instance.
  ConsentRecord({
    required this.id,
    required this.profileId,
    required this.purpose,
    required this.decision,
    required this.textVersion,
    required this.language,
    required this.decidedAt,
    required this.recordedByAccountId,
    required this.withdrawnAt,
    required this.deletionDueBy,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String profileId;

  final ConsentPurpose purpose;

  final ConsentDecision decision;

  final String textVersion;

  final Language language;

  final DateTime decidedAt;

  /// The manager account that recorded the decision.
  final String recordedByAccountId;

  final DateTime? withdrawnAt;

  /// Set on withdrawal of `health_data` consent (SET-04).
  final DateTime? deletionDueBy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConsentRecord &&
    other.id == id &&
    other.profileId == profileId &&
    other.purpose == purpose &&
    other.decision == decision &&
    other.textVersion == textVersion &&
    other.language == language &&
    other.decidedAt == decidedAt &&
    other.recordedByAccountId == recordedByAccountId &&
    other.withdrawnAt == withdrawnAt &&
    other.deletionDueBy == deletionDueBy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (profileId.hashCode) +
    (purpose.hashCode) +
    (decision.hashCode) +
    (textVersion.hashCode) +
    (language.hashCode) +
    (decidedAt.hashCode) +
    (recordedByAccountId.hashCode) +
    (withdrawnAt == null ? 0 : withdrawnAt!.hashCode) +
    (deletionDueBy == null ? 0 : deletionDueBy!.hashCode);

  @override
  String toString() => 'ConsentRecord[id=$id, profileId=$profileId, purpose=$purpose, decision=$decision, textVersion=$textVersion, language=$language, decidedAt=$decidedAt, recordedByAccountId=$recordedByAccountId, withdrawnAt=$withdrawnAt, deletionDueBy=$deletionDueBy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'profileId'] = this.profileId;
      json[r'purpose'] = this.purpose;
      json[r'decision'] = this.decision;
      json[r'textVersion'] = this.textVersion;
      json[r'language'] = this.language;
      json[r'decidedAt'] = this.decidedAt.toUtc().toIso8601String();
      json[r'recordedByAccountId'] = this.recordedByAccountId;
    if (this.withdrawnAt != null) {
      json[r'withdrawnAt'] = this.withdrawnAt!.toUtc().toIso8601String();
    } else {
      json[r'withdrawnAt'] = null;
    }
    if (this.deletionDueBy != null) {
      json[r'deletionDueBy'] = this.deletionDueBy!.toUtc().toIso8601String();
    } else {
      json[r'deletionDueBy'] = null;
    }
    return json;
  }

  /// Clones this instance of [ConsentRecord] and returns a new one where some of the
  /// properties have changed.
  ConsentRecord copyWith({
    String? id,
    String? profileId,
    ConsentPurpose? purpose,
    ConsentDecision? decision,
    String? textVersion,
    Language? language,
    DateTime? decidedAt,
    String? recordedByAccountId,
    DateTime? withdrawnAt,
    bool withdrawnAtSetToNull = false,
    DateTime? deletionDueBy,
    bool deletionDueBySetToNull = false,
  }) => ConsentRecord(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    purpose: purpose ?? this.purpose,
    decision: decision ?? this.decision,
    textVersion: textVersion ?? this.textVersion,
    language: language ?? this.language,
    decidedAt: decidedAt ?? this.decidedAt,
    recordedByAccountId: recordedByAccountId ?? this.recordedByAccountId,
    withdrawnAt: withdrawnAtSetToNull ? null : withdrawnAt ?? this.withdrawnAt,
    deletionDueBy: deletionDueBySetToNull ? null : deletionDueBy ?? this.deletionDueBy,
  );

  /// Returns a new [ConsentRecord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConsentRecord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ConsentRecord[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ConsentRecord[id]" has a null value in JSON.');
        assert(json.containsKey(r'profileId'), 'Required key "ConsentRecord[profileId]" is missing from JSON.');
        assert(json[r'profileId'] != null, 'Required key "ConsentRecord[profileId]" has a null value in JSON.');
        assert(json.containsKey(r'purpose'), 'Required key "ConsentRecord[purpose]" is missing from JSON.');
        assert(json[r'purpose'] != null, 'Required key "ConsentRecord[purpose]" has a null value in JSON.');
        assert(json.containsKey(r'decision'), 'Required key "ConsentRecord[decision]" is missing from JSON.');
        assert(json[r'decision'] != null, 'Required key "ConsentRecord[decision]" has a null value in JSON.');
        assert(json.containsKey(r'textVersion'), 'Required key "ConsentRecord[textVersion]" is missing from JSON.');
        assert(json[r'textVersion'] != null, 'Required key "ConsentRecord[textVersion]" has a null value in JSON.');
        assert(json.containsKey(r'language'), 'Required key "ConsentRecord[language]" is missing from JSON.');
        assert(json[r'language'] != null, 'Required key "ConsentRecord[language]" has a null value in JSON.');
        assert(json.containsKey(r'decidedAt'), 'Required key "ConsentRecord[decidedAt]" is missing from JSON.');
        assert(json[r'decidedAt'] != null, 'Required key "ConsentRecord[decidedAt]" has a null value in JSON.');
        assert(json.containsKey(r'recordedByAccountId'), 'Required key "ConsentRecord[recordedByAccountId]" is missing from JSON.');
        assert(json[r'recordedByAccountId'] != null, 'Required key "ConsentRecord[recordedByAccountId]" has a null value in JSON.');
        assert(json.containsKey(r'withdrawnAt'), 'Required key "ConsentRecord[withdrawnAt]" is missing from JSON.');
        assert(json.containsKey(r'deletionDueBy'), 'Required key "ConsentRecord[deletionDueBy]" is missing from JSON.');
        return true;
      }());

      return ConsentRecord(
        id: mapValueOfType<String>(json, r'id')!,
        profileId: mapValueOfType<String>(json, r'profileId')!,
        purpose: ConsentPurpose.fromJson(json[r'purpose'])!,
        decision: ConsentDecision.fromJson(json[r'decision'])!,
        textVersion: mapValueOfType<String>(json, r'textVersion')!,
        language: Language.fromJson(json[r'language'])!,
        decidedAt: mapDateTime(json, r'decidedAt', r'')!,
        recordedByAccountId: mapValueOfType<String>(json, r'recordedByAccountId')!,
        withdrawnAt: mapDateTime(json, r'withdrawnAt', r''),
        deletionDueBy: mapDateTime(json, r'deletionDueBy', r''),
      );
    }
    return null;
  }

  static List<ConsentRecord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConsentRecord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConsentRecord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConsentRecord> mapFromJson(dynamic json) {
    final map = <String, ConsentRecord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConsentRecord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConsentRecord-objects as value to a dart map
  static Map<String, List<ConsentRecord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConsentRecord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConsentRecord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'profileId',
    'purpose',
    'decision',
    'textVersion',
    'language',
    'decidedAt',
    'recordedByAccountId',
    'withdrawnAt',
    'deletionDueBy',
  };
}

