//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LibraryRecipeListItem {
  /// Returns a new [LibraryRecipeListItem] instance.
  LibraryRecipeListItem({
    required this.recipe,
    required this.safety,
  });

  final RecipeSummary recipe;

  final RecipeSafety safety;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LibraryRecipeListItem &&
    other.recipe == recipe &&
    other.safety == safety;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipe.hashCode) +
    (safety.hashCode);

  @override
  String toString() => 'LibraryRecipeListItem[recipe=$recipe, safety=$safety]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipe'] = this.recipe;
      json[r'safety'] = this.safety;
    return json;
  }

  /// Clones this instance of [LibraryRecipeListItem] and returns a new one where some of the
  /// properties have changed.
  LibraryRecipeListItem copyWith({
    RecipeSummary? recipe,
    RecipeSafety? safety,
  }) => LibraryRecipeListItem(
    recipe: recipe ?? this.recipe,
    safety: safety ?? this.safety,
  );

  /// Returns a new [LibraryRecipeListItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LibraryRecipeListItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipe'), 'Required key "LibraryRecipeListItem[recipe]" is missing from JSON.');
        assert(json[r'recipe'] != null, 'Required key "LibraryRecipeListItem[recipe]" has a null value in JSON.');
        assert(json.containsKey(r'safety'), 'Required key "LibraryRecipeListItem[safety]" is missing from JSON.');
        assert(json[r'safety'] != null, 'Required key "LibraryRecipeListItem[safety]" has a null value in JSON.');
        return true;
      }());

      return LibraryRecipeListItem(
        recipe: RecipeSummary.fromJson(json[r'recipe'])!,
        safety: RecipeSafety.fromJson(json[r'safety'])!,
      );
    }
    return null;
  }

  static List<LibraryRecipeListItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LibraryRecipeListItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibraryRecipeListItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LibraryRecipeListItem> mapFromJson(dynamic json) {
    final map = <String, LibraryRecipeListItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LibraryRecipeListItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LibraryRecipeListItem-objects as value to a dart map
  static Map<String, List<LibraryRecipeListItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LibraryRecipeListItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LibraryRecipeListItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recipe',
    'safety',
  };
}

