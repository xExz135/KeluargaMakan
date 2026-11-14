//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientSetInput {
  /// Returns a new [IngredientSetInput] instance.
  IngredientSetInput({
    required this.name,
    this.itemIds = const {},
  });

  final String name;

  final Set<String> itemIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientSetInput &&
    other.name == name &&
    _deepEquality.equals(other.itemIds, itemIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (itemIds.hashCode);

  @override
  String toString() => 'IngredientSetInput[name=$name, itemIds=$itemIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'itemIds'] = this.itemIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [IngredientSetInput] and returns a new one where some of the
  /// properties have changed.
  IngredientSetInput copyWith({
    String? name,
    Set<String>? itemIds,
  }) => IngredientSetInput(
    name: name ?? this.name,
    itemIds: itemIds ?? this.itemIds,
  );

  /// Returns a new [IngredientSetInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientSetInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "IngredientSetInput[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "IngredientSetInput[name]" has a null value in JSON.');
        assert(json.containsKey(r'itemIds'), 'Required key "IngredientSetInput[itemIds]" is missing from JSON.');
        assert(json[r'itemIds'] != null, 'Required key "IngredientSetInput[itemIds]" has a null value in JSON.');
        return true;
      }());

      return IngredientSetInput(
        name: mapValueOfType<String>(json, r'name')!,
        itemIds: json[r'itemIds'] is Iterable
            ? (json[r'itemIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<IngredientSetInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientSetInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientSetInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientSetInput> mapFromJson(dynamic json) {
    final map = <String, IngredientSetInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientSetInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientSetInput-objects as value to a dart map
  static Map<String, List<IngredientSetInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientSetInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientSetInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'itemIds',
  };
}

