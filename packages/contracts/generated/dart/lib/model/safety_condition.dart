//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyCondition {
  /// Returns a new [SafetyCondition] instance.
  SafetyCondition({
    required this.kind,
    required this.variantId,
    required this.separateBeforeStepId,
    this.omittedLineIds = const {},
  });

  final SafetyConditionKind kind;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String variantId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String separateBeforeStepId;

  final Set<String> omittedLineIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyCondition &&
    other.kind == kind &&
    other.variantId == variantId &&
    other.separateBeforeStepId == separateBeforeStepId &&
    _deepEquality.equals(other.omittedLineIds, omittedLineIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (variantId.hashCode) +
    (separateBeforeStepId.hashCode) +
    (omittedLineIds.hashCode);

  @override
  String toString() => 'SafetyCondition[kind=$kind, variantId=$variantId, separateBeforeStepId=$separateBeforeStepId, omittedLineIds=$omittedLineIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'variantId'] = this.variantId;
      json[r'separateBeforeStepId'] = this.separateBeforeStepId;
      json[r'omittedLineIds'] = this.omittedLineIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [SafetyCondition] and returns a new one where some of the
  /// properties have changed.
  SafetyCondition copyWith({
    SafetyConditionKind? kind,
    String? variantId,
    String? separateBeforeStepId,
    Set<String>? omittedLineIds,
  }) => SafetyCondition(
    kind: kind ?? this.kind,
    variantId: variantId ?? this.variantId,
    separateBeforeStepId: separateBeforeStepId ?? this.separateBeforeStepId,
    omittedLineIds: omittedLineIds ?? this.omittedLineIds,
  );

  /// Returns a new [SafetyCondition] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyCondition? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "SafetyCondition[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "SafetyCondition[kind]" has a null value in JSON.');
        assert(json.containsKey(r'variantId'), 'Required key "SafetyCondition[variantId]" is missing from JSON.');
        assert(json[r'variantId'] != null, 'Required key "SafetyCondition[variantId]" has a null value in JSON.');
        assert(json.containsKey(r'separateBeforeStepId'), 'Required key "SafetyCondition[separateBeforeStepId]" is missing from JSON.');
        assert(json[r'separateBeforeStepId'] != null, 'Required key "SafetyCondition[separateBeforeStepId]" has a null value in JSON.');
        assert(json.containsKey(r'omittedLineIds'), 'Required key "SafetyCondition[omittedLineIds]" is missing from JSON.');
        assert(json[r'omittedLineIds'] != null, 'Required key "SafetyCondition[omittedLineIds]" has a null value in JSON.');
        return true;
      }());

      return SafetyCondition(
        kind: SafetyConditionKind.fromJson(json[r'kind'])!,
        variantId: mapValueOfType<String>(json, r'variantId')!,
        separateBeforeStepId: mapValueOfType<String>(json, r'separateBeforeStepId')!,
        omittedLineIds: json[r'omittedLineIds'] is Iterable
            ? (json[r'omittedLineIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<SafetyCondition> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyCondition>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyCondition.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyCondition> mapFromJson(dynamic json) {
    final map = <String, SafetyCondition>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyCondition.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyCondition-objects as value to a dart map
  static Map<String, List<SafetyCondition>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyCondition>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyCondition.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'variantId',
    'separateBeforeStepId',
    'omittedLineIds',
  };
}

