//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientSet {
  /// Returns a new [IngredientSet] instance.
  IngredientSet({
    required this.id,
    required this.name,
    this.itemIds = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final String name;

  /// Kitchen items in the set; a removed item leaves the set.
  final Set<String> itemIds;

  final DateTime createdAt;

  final DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientSet &&
    other.id == id &&
    other.name == name &&
    _deepEquality.equals(other.itemIds, itemIds) &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (itemIds.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'IngredientSet[id=$id, name=$name, itemIds=$itemIds, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'itemIds'] = this.itemIds.toList(growable: false);
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [IngredientSet] and returns a new one where some of the
  /// properties have changed.
  IngredientSet copyWith({
    String? id,
    String? name,
    Set<String>? itemIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IngredientSet(
    id: id ?? this.id,
    name: name ?? this.name,
    itemIds: itemIds ?? this.itemIds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a new [IngredientSet] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientSet? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "IngredientSet[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "IngredientSet[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "IngredientSet[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "IngredientSet[name]" has a null value in JSON.');
        assert(json.containsKey(r'itemIds'), 'Required key "IngredientSet[itemIds]" is missing from JSON.');
        assert(json[r'itemIds'] != null, 'Required key "IngredientSet[itemIds]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "IngredientSet[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "IngredientSet[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "IngredientSet[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "IngredientSet[updatedAt]" has a null value in JSON.');
        return true;
      }());

      return IngredientSet(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        itemIds: json[r'itemIds'] is Iterable
            ? (json[r'itemIds'] as Iterable).cast<String>().toSet()
            : const {},
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<IngredientSet> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientSet>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientSet.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientSet> mapFromJson(dynamic json) {
    final map = <String, IngredientSet>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientSet.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientSet-objects as value to a dart map
  static Map<String, List<IngredientSet>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientSet>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientSet.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'itemIds',
    'createdAt',
    'updatedAt',
  };
}

