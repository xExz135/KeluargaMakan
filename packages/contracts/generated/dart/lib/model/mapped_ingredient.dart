//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class MappedIngredient {
  /// Returns a new [MappedIngredient] instance.
  MappedIngredient({
    required this.ingredientId,
    required this.displayName,
  });

  /// Identifier of a reference ingredient or library dish.
  final String ingredientId;

  final LocalizedText displayName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MappedIngredient &&
    other.ingredientId == ingredientId &&
    other.displayName == displayName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ingredientId.hashCode) +
    (displayName.hashCode);

  @override
  String toString() => 'MappedIngredient[ingredientId=$ingredientId, displayName=$displayName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ingredientId'] = this.ingredientId;
      json[r'displayName'] = this.displayName;
    return json;
  }

  /// Clones this instance of [MappedIngredient] and returns a new one where some of the
  /// properties have changed.
  MappedIngredient copyWith({
    String? ingredientId,
    LocalizedText? displayName,
  }) => MappedIngredient(
    ingredientId: ingredientId ?? this.ingredientId,
    displayName: displayName ?? this.displayName,
  );

  /// Returns a new [MappedIngredient] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MappedIngredient? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ingredientId'), 'Required key "MappedIngredient[ingredientId]" is missing from JSON.');
        assert(json[r'ingredientId'] != null, 'Required key "MappedIngredient[ingredientId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "MappedIngredient[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "MappedIngredient[displayName]" has a null value in JSON.');
        return true;
      }());

      return MappedIngredient(
        ingredientId: mapValueOfType<String>(json, r'ingredientId')!,
        displayName: LocalizedText.fromJson(json[r'displayName'])!,
      );
    }
    return null;
  }

  static List<MappedIngredient> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MappedIngredient>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MappedIngredient.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MappedIngredient> mapFromJson(dynamic json) {
    final map = <String, MappedIngredient>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MappedIngredient.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MappedIngredient-objects as value to a dart map
  static Map<String, List<MappedIngredient>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MappedIngredient>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MappedIngredient.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ingredientId',
    'displayName',
  };
}

