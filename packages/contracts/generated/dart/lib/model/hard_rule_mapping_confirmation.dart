//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HardRuleMappingConfirmation {
  /// Returns a new [HardRuleMappingConfirmation] instance.
  HardRuleMappingConfirmation({
    this.ingredientIds = const {},
  });

  final Set<String> ingredientIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HardRuleMappingConfirmation &&
    _deepEquality.equals(other.ingredientIds, ingredientIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ingredientIds.hashCode);

  @override
  String toString() => 'HardRuleMappingConfirmation[ingredientIds=$ingredientIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ingredientIds'] = this.ingredientIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [HardRuleMappingConfirmation] and returns a new one where some of the
  /// properties have changed.
  HardRuleMappingConfirmation copyWith({
    Set<String>? ingredientIds,
  }) => HardRuleMappingConfirmation(
    ingredientIds: ingredientIds ?? this.ingredientIds,
  );

  /// Returns a new [HardRuleMappingConfirmation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HardRuleMappingConfirmation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ingredientIds'), 'Required key "HardRuleMappingConfirmation[ingredientIds]" is missing from JSON.');
        assert(json[r'ingredientIds'] != null, 'Required key "HardRuleMappingConfirmation[ingredientIds]" has a null value in JSON.');
        return true;
      }());

      return HardRuleMappingConfirmation(
        ingredientIds: json[r'ingredientIds'] is Iterable
            ? (json[r'ingredientIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<HardRuleMappingConfirmation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HardRuleMappingConfirmation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HardRuleMappingConfirmation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HardRuleMappingConfirmation> mapFromJson(dynamic json) {
    final map = <String, HardRuleMappingConfirmation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HardRuleMappingConfirmation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HardRuleMappingConfirmation-objects as value to a dart map
  static Map<String, List<HardRuleMappingConfirmation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HardRuleMappingConfirmation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HardRuleMappingConfirmation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ingredientIds',
  };
}

