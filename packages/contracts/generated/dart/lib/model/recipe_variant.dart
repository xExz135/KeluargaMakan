//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeVariant {
  /// Returns a new [RecipeVariant] instance.
  RecipeVariant({
    required this.variant,
    required this.safety,
  });

  final AppliedVariant variant;

  final RecipeSafety safety;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeVariant &&
    other.variant == variant &&
    other.safety == safety;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (variant.hashCode) +
    (safety.hashCode);

  @override
  String toString() => 'RecipeVariant[variant=$variant, safety=$safety]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'variant'] = this.variant;
      json[r'safety'] = this.safety;
    return json;
  }

  /// Clones this instance of [RecipeVariant] and returns a new one where some of the
  /// properties have changed.
  RecipeVariant copyWith({
    AppliedVariant? variant,
    RecipeSafety? safety,
  }) => RecipeVariant(
    variant: variant ?? this.variant,
    safety: safety ?? this.safety,
  );

  /// Returns a new [RecipeVariant] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeVariant? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'variant'), 'Required key "RecipeVariant[variant]" is missing from JSON.');
        assert(json[r'variant'] != null, 'Required key "RecipeVariant[variant]" has a null value in JSON.');
        assert(json.containsKey(r'safety'), 'Required key "RecipeVariant[safety]" is missing from JSON.');
        assert(json[r'safety'] != null, 'Required key "RecipeVariant[safety]" has a null value in JSON.');
        return true;
      }());

      return RecipeVariant(
        variant: AppliedVariant.fromJson(json[r'variant'])!,
        safety: RecipeSafety.fromJson(json[r'safety'])!,
      );
    }
    return null;
  }

  static List<RecipeVariant> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeVariant>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeVariant.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeVariant> mapFromJson(dynamic json) {
    final map = <String, RecipeVariant>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeVariant.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeVariant-objects as value to a dart map
  static Map<String, List<RecipeVariant>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeVariant>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeVariant.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'variant',
    'safety',
  };
}

