//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientSetList {
  /// Returns a new [IngredientSetList] instance.
  IngredientSetList({
    this.items = const [],
    required this.maxSets,
  });

  final List<IngredientSet> items;

  /// The configured limit of sets per household.
  ///
  /// Minimum value: 1
  final int maxSets;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientSetList &&
    _deepEquality.equals(other.items, items) &&
    other.maxSets == maxSets;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (maxSets.hashCode);

  @override
  String toString() => 'IngredientSetList[items=$items, maxSets=$maxSets]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
      json[r'maxSets'] = this.maxSets;
    return json;
  }

  /// Clones this instance of [IngredientSetList] and returns a new one where some of the
  /// properties have changed.
  IngredientSetList copyWith({
    List<IngredientSet>? items,
    int? maxSets,
  }) => IngredientSetList(
    items: items ?? this.items,
    maxSets: maxSets ?? this.maxSets,
  );

  /// Returns a new [IngredientSetList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientSetList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "IngredientSetList[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "IngredientSetList[items]" has a null value in JSON.');
        assert(json.containsKey(r'maxSets'), 'Required key "IngredientSetList[maxSets]" is missing from JSON.');
        assert(json[r'maxSets'] != null, 'Required key "IngredientSetList[maxSets]" has a null value in JSON.');
        return true;
      }());

      return IngredientSetList(
        items: IngredientSet.listFromJson(json[r'items']),
        maxSets: mapValueOfType<int>(json, r'maxSets')!,
      );
    }
    return null;
  }

  static List<IngredientSetList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientSetList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientSetList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientSetList> mapFromJson(dynamic json) {
    final map = <String, IngredientSetList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientSetList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientSetList-objects as value to a dart map
  static Map<String, List<IngredientSetList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientSetList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientSetList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'maxSets',
  };
}

