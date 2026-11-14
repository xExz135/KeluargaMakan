//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientSearchHit {
  /// Returns a new [IngredientSearchHit] instance.
  IngredientSearchHit({
    required this.ingredient,
    required this.matchedName,
  });

  final CatalogIngredient ingredient;

  /// The local or regional name that matched, shown next to the display name; null when a display name matched.
  final String? matchedName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientSearchHit &&
    other.ingredient == ingredient &&
    other.matchedName == matchedName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ingredient.hashCode) +
    (matchedName == null ? 0 : matchedName!.hashCode);

  @override
  String toString() => 'IngredientSearchHit[ingredient=$ingredient, matchedName=$matchedName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ingredient'] = this.ingredient;
    if (this.matchedName != null) {
      json[r'matchedName'] = this.matchedName;
    } else {
      json[r'matchedName'] = null;
    }
    return json;
  }

  /// Clones this instance of [IngredientSearchHit] and returns a new one where some of the
  /// properties have changed.
  IngredientSearchHit copyWith({
    CatalogIngredient? ingredient,
    String? matchedName,
    bool matchedNameSetToNull = false,
  }) => IngredientSearchHit(
    ingredient: ingredient ?? this.ingredient,
    matchedName: matchedNameSetToNull ? null : matchedName ?? this.matchedName,
  );

  /// Returns a new [IngredientSearchHit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientSearchHit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ingredient'), 'Required key "IngredientSearchHit[ingredient]" is missing from JSON.');
        assert(json[r'ingredient'] != null, 'Required key "IngredientSearchHit[ingredient]" has a null value in JSON.');
        assert(json.containsKey(r'matchedName'), 'Required key "IngredientSearchHit[matchedName]" is missing from JSON.');
        return true;
      }());

      return IngredientSearchHit(
        ingredient: CatalogIngredient.fromJson(json[r'ingredient'])!,
        matchedName: mapValueOfType<String>(json, r'matchedName'),
      );
    }
    return null;
  }

  static List<IngredientSearchHit> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientSearchHit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientSearchHit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientSearchHit> mapFromJson(dynamic json) {
    final map = <String, IngredientSearchHit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientSearchHit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientSearchHit-objects as value to a dart map
  static Map<String, List<IngredientSearchHit>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientSearchHit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientSearchHit.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ingredient',
    'matchedName',
  };
}

