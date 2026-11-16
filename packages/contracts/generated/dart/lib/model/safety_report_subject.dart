//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyReportSubject {
  /// Returns a new [SafetyReportSubject] instance.
  SafetyReportSubject({
    required this.kind,
    required this.recipeId,
    required this.recipeVersion,
    required this.adaptationId,
    required this.substitutionId,
    required this.variantId,
  });

  final SafetySubjectKind kind;

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  /// Minimum value: 1
  final int recipeVersion;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? adaptationId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? substitutionId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? variantId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyReportSubject &&
    other.kind == kind &&
    other.recipeId == recipeId &&
    other.recipeVersion == recipeVersion &&
    other.adaptationId == adaptationId &&
    other.substitutionId == substitutionId &&
    other.variantId == variantId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (recipeId.hashCode) +
    (recipeVersion.hashCode) +
    (adaptationId == null ? 0 : adaptationId!.hashCode) +
    (substitutionId == null ? 0 : substitutionId!.hashCode) +
    (variantId == null ? 0 : variantId!.hashCode);

  @override
  String toString() => 'SafetyReportSubject[kind=$kind, recipeId=$recipeId, recipeVersion=$recipeVersion, adaptationId=$adaptationId, substitutionId=$substitutionId, variantId=$variantId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'recipeId'] = this.recipeId;
      json[r'recipeVersion'] = this.recipeVersion;
    if (this.adaptationId != null) {
      json[r'adaptationId'] = this.adaptationId;
    } else {
      json[r'adaptationId'] = null;
    }
    if (this.substitutionId != null) {
      json[r'substitutionId'] = this.substitutionId;
    } else {
      json[r'substitutionId'] = null;
    }
    if (this.variantId != null) {
      json[r'variantId'] = this.variantId;
    } else {
      json[r'variantId'] = null;
    }
    return json;
  }

  /// Clones this instance of [SafetyReportSubject] and returns a new one where some of the
  /// properties have changed.
  SafetyReportSubject copyWith({
    SafetySubjectKind? kind,
    String? recipeId,
    int? recipeVersion,
    String? adaptationId,
    bool adaptationIdSetToNull = false,
    String? substitutionId,
    bool substitutionIdSetToNull = false,
    String? variantId,
    bool variantIdSetToNull = false,
  }) => SafetyReportSubject(
    kind: kind ?? this.kind,
    recipeId: recipeId ?? this.recipeId,
    recipeVersion: recipeVersion ?? this.recipeVersion,
    adaptationId: adaptationIdSetToNull ? null : adaptationId ?? this.adaptationId,
    substitutionId: substitutionIdSetToNull ? null : substitutionId ?? this.substitutionId,
    variantId: variantIdSetToNull ? null : variantId ?? this.variantId,
  );

  /// Returns a new [SafetyReportSubject] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyReportSubject? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "SafetyReportSubject[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "SafetyReportSubject[kind]" has a null value in JSON.');
        assert(json.containsKey(r'recipeId'), 'Required key "SafetyReportSubject[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "SafetyReportSubject[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'recipeVersion'), 'Required key "SafetyReportSubject[recipeVersion]" is missing from JSON.');
        assert(json[r'recipeVersion'] != null, 'Required key "SafetyReportSubject[recipeVersion]" has a null value in JSON.');
        assert(json.containsKey(r'adaptationId'), 'Required key "SafetyReportSubject[adaptationId]" is missing from JSON.');
        assert(json.containsKey(r'substitutionId'), 'Required key "SafetyReportSubject[substitutionId]" is missing from JSON.');
        assert(json.containsKey(r'variantId'), 'Required key "SafetyReportSubject[variantId]" is missing from JSON.');
        return true;
      }());

      return SafetyReportSubject(
        kind: SafetySubjectKind.fromJson(json[r'kind'])!,
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        recipeVersion: mapValueOfType<int>(json, r'recipeVersion')!,
        adaptationId: mapValueOfType<String>(json, r'adaptationId'),
        substitutionId: mapValueOfType<String>(json, r'substitutionId'),
        variantId: mapValueOfType<String>(json, r'variantId'),
      );
    }
    return null;
  }

  static List<SafetyReportSubject> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportSubject>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportSubject.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyReportSubject> mapFromJson(dynamic json) {
    final map = <String, SafetyReportSubject>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyReportSubject.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyReportSubject-objects as value to a dart map
  static Map<String, List<SafetyReportSubject>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyReportSubject>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyReportSubject.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'recipeId',
    'recipeVersion',
    'adaptationId',
    'substitutionId',
    'variantId',
  };
}

