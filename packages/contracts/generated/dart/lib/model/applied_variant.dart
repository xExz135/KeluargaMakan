//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AppliedVariant {
  /// Returns a new [AppliedVariant] instance.
  AppliedVariant({
    required this.variantId,
    required this.label,
    this.separatedMemberIds = const {},
    required this.separateBeforeStepId,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String variantId;

  final LocalizedText label;

  final Set<String> separatedMemberIds;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String separateBeforeStepId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppliedVariant &&
    other.variantId == variantId &&
    other.label == label &&
    _deepEquality.equals(other.separatedMemberIds, separatedMemberIds) &&
    other.separateBeforeStepId == separateBeforeStepId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (variantId.hashCode) +
    (label.hashCode) +
    (separatedMemberIds.hashCode) +
    (separateBeforeStepId.hashCode);

  @override
  String toString() => 'AppliedVariant[variantId=$variantId, label=$label, separatedMemberIds=$separatedMemberIds, separateBeforeStepId=$separateBeforeStepId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'variantId'] = this.variantId;
      json[r'label'] = this.label;
      json[r'separatedMemberIds'] = this.separatedMemberIds.toList(growable: false);
      json[r'separateBeforeStepId'] = this.separateBeforeStepId;
    return json;
  }

  /// Clones this instance of [AppliedVariant] and returns a new one where some of the
  /// properties have changed.
  AppliedVariant copyWith({
    String? variantId,
    LocalizedText? label,
    Set<String>? separatedMemberIds,
    String? separateBeforeStepId,
  }) => AppliedVariant(
    variantId: variantId ?? this.variantId,
    label: label ?? this.label,
    separatedMemberIds: separatedMemberIds ?? this.separatedMemberIds,
    separateBeforeStepId: separateBeforeStepId ?? this.separateBeforeStepId,
  );

  /// Returns a new [AppliedVariant] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppliedVariant? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'variantId'), 'Required key "AppliedVariant[variantId]" is missing from JSON.');
        assert(json[r'variantId'] != null, 'Required key "AppliedVariant[variantId]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "AppliedVariant[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "AppliedVariant[label]" has a null value in JSON.');
        assert(json.containsKey(r'separatedMemberIds'), 'Required key "AppliedVariant[separatedMemberIds]" is missing from JSON.');
        assert(json[r'separatedMemberIds'] != null, 'Required key "AppliedVariant[separatedMemberIds]" has a null value in JSON.');
        assert(json.containsKey(r'separateBeforeStepId'), 'Required key "AppliedVariant[separateBeforeStepId]" is missing from JSON.');
        assert(json[r'separateBeforeStepId'] != null, 'Required key "AppliedVariant[separateBeforeStepId]" has a null value in JSON.');
        return true;
      }());

      return AppliedVariant(
        variantId: mapValueOfType<String>(json, r'variantId')!,
        label: LocalizedText.fromJson(json[r'label'])!,
        separatedMemberIds: json[r'separatedMemberIds'] is Iterable
            ? (json[r'separatedMemberIds'] as Iterable).cast<String>().toSet()
            : const {},
        separateBeforeStepId: mapValueOfType<String>(json, r'separateBeforeStepId')!,
      );
    }
    return null;
  }

  static List<AppliedVariant> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppliedVariant>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppliedVariant.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppliedVariant> mapFromJson(dynamic json) {
    final map = <String, AppliedVariant>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppliedVariant.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppliedVariant-objects as value to a dart map
  static Map<String, List<AppliedVariant>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppliedVariant>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppliedVariant.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'variantId',
    'label',
    'separatedMemberIds',
    'separateBeforeStepId',
  };
}

