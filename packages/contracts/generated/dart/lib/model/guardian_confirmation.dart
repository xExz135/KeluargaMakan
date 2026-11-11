//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class GuardianConfirmation {
  /// Returns a new [GuardianConfirmation] instance.
  GuardianConfirmation({
    required this.consentRecordId,
    required this.confirmedAt,
    required this.textVersion,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String consentRecordId;

  final DateTime confirmedAt;

  final String textVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GuardianConfirmation &&
    other.consentRecordId == consentRecordId &&
    other.confirmedAt == confirmedAt &&
    other.textVersion == textVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (consentRecordId.hashCode) +
    (confirmedAt.hashCode) +
    (textVersion.hashCode);

  @override
  String toString() => 'GuardianConfirmation[consentRecordId=$consentRecordId, confirmedAt=$confirmedAt, textVersion=$textVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'consentRecordId'] = this.consentRecordId;
      json[r'confirmedAt'] = this.confirmedAt.toUtc().toIso8601String();
      json[r'textVersion'] = this.textVersion;
    return json;
  }

  /// Clones this instance of [GuardianConfirmation] and returns a new one where some of the
  /// properties have changed.
  GuardianConfirmation copyWith({
    String? consentRecordId,
    DateTime? confirmedAt,
    String? textVersion,
  }) => GuardianConfirmation(
    consentRecordId: consentRecordId ?? this.consentRecordId,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    textVersion: textVersion ?? this.textVersion,
  );

  /// Returns a new [GuardianConfirmation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GuardianConfirmation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consentRecordId'), 'Required key "GuardianConfirmation[consentRecordId]" is missing from JSON.');
        assert(json[r'consentRecordId'] != null, 'Required key "GuardianConfirmation[consentRecordId]" has a null value in JSON.');
        assert(json.containsKey(r'confirmedAt'), 'Required key "GuardianConfirmation[confirmedAt]" is missing from JSON.');
        assert(json[r'confirmedAt'] != null, 'Required key "GuardianConfirmation[confirmedAt]" has a null value in JSON.');
        assert(json.containsKey(r'textVersion'), 'Required key "GuardianConfirmation[textVersion]" is missing from JSON.');
        assert(json[r'textVersion'] != null, 'Required key "GuardianConfirmation[textVersion]" has a null value in JSON.');
        return true;
      }());

      return GuardianConfirmation(
        consentRecordId: mapValueOfType<String>(json, r'consentRecordId')!,
        confirmedAt: mapDateTime(json, r'confirmedAt', r'')!,
        textVersion: mapValueOfType<String>(json, r'textVersion')!,
      );
    }
    return null;
  }

  static List<GuardianConfirmation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GuardianConfirmation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GuardianConfirmation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GuardianConfirmation> mapFromJson(dynamic json) {
    final map = <String, GuardianConfirmation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GuardianConfirmation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GuardianConfirmation-objects as value to a dart map
  static Map<String, List<GuardianConfirmation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GuardianConfirmation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GuardianConfirmation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consentRecordId',
    'confirmedAt',
    'textVersion',
  };
}

