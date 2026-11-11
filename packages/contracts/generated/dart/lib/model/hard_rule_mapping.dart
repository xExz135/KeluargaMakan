//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HardRuleMapping {
  /// Returns a new [HardRuleMapping] instance.
  HardRuleMapping({
    required this.status,
    this.ingredients = const [],
    required this.confirmedBy,
    required this.updatedAt,
  });

  final MappingStatus status;

  final List<MappedIngredient> ingredients;

  final MappingConfirmer? confirmedBy;

  final DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HardRuleMapping &&
    other.status == status &&
    _deepEquality.equals(other.ingredients, ingredients) &&
    other.confirmedBy == confirmedBy &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (ingredients.hashCode) +
    (confirmedBy == null ? 0 : confirmedBy!.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'HardRuleMapping[status=$status, ingredients=$ingredients, confirmedBy=$confirmedBy, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
      json[r'ingredients'] = this.ingredients;
    if (this.confirmedBy != null) {
      json[r'confirmedBy'] = this.confirmedBy;
    } else {
      json[r'confirmedBy'] = null;
    }
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [HardRuleMapping] and returns a new one where some of the
  /// properties have changed.
  HardRuleMapping copyWith({
    MappingStatus? status,
    List<MappedIngredient>? ingredients,
    MappingConfirmer? confirmedBy,
    bool confirmedBySetToNull = false,
    DateTime? updatedAt,
  }) => HardRuleMapping(
    status: status ?? this.status,
    ingredients: ingredients ?? this.ingredients,
    confirmedBy: confirmedBySetToNull ? null : confirmedBy ?? this.confirmedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a new [HardRuleMapping] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HardRuleMapping? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'), 'Required key "HardRuleMapping[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "HardRuleMapping[status]" has a null value in JSON.');
        assert(json.containsKey(r'ingredients'), 'Required key "HardRuleMapping[ingredients]" is missing from JSON.');
        assert(json[r'ingredients'] != null, 'Required key "HardRuleMapping[ingredients]" has a null value in JSON.');
        assert(json.containsKey(r'confirmedBy'), 'Required key "HardRuleMapping[confirmedBy]" is missing from JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "HardRuleMapping[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "HardRuleMapping[updatedAt]" has a null value in JSON.');
        return true;
      }());

      return HardRuleMapping(
        status: MappingStatus.fromJson(json[r'status'])!,
        ingredients: MappedIngredient.listFromJson(json[r'ingredients']),
        confirmedBy: MappingConfirmer.fromJson(json[r'confirmedBy']),
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<HardRuleMapping> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HardRuleMapping>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HardRuleMapping.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HardRuleMapping> mapFromJson(dynamic json) {
    final map = <String, HardRuleMapping>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HardRuleMapping.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HardRuleMapping-objects as value to a dart map
  static Map<String, List<HardRuleMapping>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HardRuleMapping>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HardRuleMapping.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'ingredients',
    'confirmedBy',
    'updatedAt',
  };
}

