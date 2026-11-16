//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeRegion {
  /// Returns a new [RecipeRegion] instance.
  RecipeRegion({
    required this.regionId,
    required this.displayName,
  });

  /// Identifier of a reference ingredient or library dish.
  final String regionId;

  final LocalizedText displayName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeRegion &&
    other.regionId == regionId &&
    other.displayName == displayName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (regionId.hashCode) +
    (displayName.hashCode);

  @override
  String toString() => 'RecipeRegion[regionId=$regionId, displayName=$displayName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'regionId'] = this.regionId;
      json[r'displayName'] = this.displayName;
    return json;
  }

  /// Clones this instance of [RecipeRegion] and returns a new one where some of the
  /// properties have changed.
  RecipeRegion copyWith({
    String? regionId,
    LocalizedText? displayName,
  }) => RecipeRegion(
    regionId: regionId ?? this.regionId,
    displayName: displayName ?? this.displayName,
  );

  /// Returns a new [RecipeRegion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeRegion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'regionId'), 'Required key "RecipeRegion[regionId]" is missing from JSON.');
        assert(json[r'regionId'] != null, 'Required key "RecipeRegion[regionId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "RecipeRegion[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "RecipeRegion[displayName]" has a null value in JSON.');
        return true;
      }());

      return RecipeRegion(
        regionId: mapValueOfType<String>(json, r'regionId')!,
        displayName: LocalizedText.fromJson(json[r'displayName'])!,
      );
    }
    return null;
  }

  static List<RecipeRegion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeRegion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeRegion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeRegion> mapFromJson(dynamic json) {
    final map = <String, RecipeRegion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeRegion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeRegion-objects as value to a dart map
  static Map<String, List<RecipeRegion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeRegion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeRegion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'regionId',
    'displayName',
  };
}

