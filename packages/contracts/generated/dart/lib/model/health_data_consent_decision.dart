//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HealthDataConsentDecision {
  /// Returns a new [HealthDataConsentDecision] instance.
  HealthDataConsentDecision({
    required this.decision,
    required this.textVersion,
    required this.language,
  });

  final ConsentDecision decision;

  final String textVersion;

  /// Language of the text the manager was shown.
  final Language language;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HealthDataConsentDecision &&
    other.decision == decision &&
    other.textVersion == textVersion &&
    other.language == language;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (decision.hashCode) +
    (textVersion.hashCode) +
    (language.hashCode);

  @override
  String toString() => 'HealthDataConsentDecision[decision=$decision, textVersion=$textVersion, language=$language]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'decision'] = this.decision;
      json[r'textVersion'] = this.textVersion;
      json[r'language'] = this.language;
    return json;
  }

  /// Clones this instance of [HealthDataConsentDecision] and returns a new one where some of the
  /// properties have changed.
  HealthDataConsentDecision copyWith({
    ConsentDecision? decision,
    String? textVersion,
    Language? language,
  }) => HealthDataConsentDecision(
    decision: decision ?? this.decision,
    textVersion: textVersion ?? this.textVersion,
    language: language ?? this.language,
  );

  /// Returns a new [HealthDataConsentDecision] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthDataConsentDecision? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'decision'), 'Required key "HealthDataConsentDecision[decision]" is missing from JSON.');
        assert(json[r'decision'] != null, 'Required key "HealthDataConsentDecision[decision]" has a null value in JSON.');
        assert(json.containsKey(r'textVersion'), 'Required key "HealthDataConsentDecision[textVersion]" is missing from JSON.');
        assert(json[r'textVersion'] != null, 'Required key "HealthDataConsentDecision[textVersion]" has a null value in JSON.');
        assert(json.containsKey(r'language'), 'Required key "HealthDataConsentDecision[language]" is missing from JSON.');
        assert(json[r'language'] != null, 'Required key "HealthDataConsentDecision[language]" has a null value in JSON.');
        return true;
      }());

      return HealthDataConsentDecision(
        decision: ConsentDecision.fromJson(json[r'decision'])!,
        textVersion: mapValueOfType<String>(json, r'textVersion')!,
        language: Language.fromJson(json[r'language'])!,
      );
    }
    return null;
  }

  static List<HealthDataConsentDecision> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HealthDataConsentDecision>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthDataConsentDecision.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthDataConsentDecision> mapFromJson(dynamic json) {
    final map = <String, HealthDataConsentDecision>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthDataConsentDecision.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthDataConsentDecision-objects as value to a dart map
  static Map<String, List<HealthDataConsentDecision>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HealthDataConsentDecision>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthDataConsentDecision.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'decision',
    'textVersion',
    'language',
  };
}

