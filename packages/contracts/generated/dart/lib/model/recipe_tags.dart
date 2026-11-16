//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeTags {
  /// Returns a new [RecipeTags] instance.
  RecipeTags({
    required this.fried,
    required this.santan,
    required this.spiceLevel,
  });

  final bool fried;

  final bool santan;

  final RecipeSpiceLevel spiceLevel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeTags &&
    other.fried == fried &&
    other.santan == santan &&
    other.spiceLevel == spiceLevel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fried.hashCode) +
    (santan.hashCode) +
    (spiceLevel.hashCode);

  @override
  String toString() => 'RecipeTags[fried=$fried, santan=$santan, spiceLevel=$spiceLevel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fried'] = this.fried;
      json[r'santan'] = this.santan;
      json[r'spiceLevel'] = this.spiceLevel;
    return json;
  }

  /// Clones this instance of [RecipeTags] and returns a new one where some of the
  /// properties have changed.
  RecipeTags copyWith({
    bool? fried,
    bool? santan,
    RecipeSpiceLevel? spiceLevel,
  }) => RecipeTags(
    fried: fried ?? this.fried,
    santan: santan ?? this.santan,
    spiceLevel: spiceLevel ?? this.spiceLevel,
  );

  /// Returns a new [RecipeTags] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeTags? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fried'), 'Required key "RecipeTags[fried]" is missing from JSON.');
        assert(json[r'fried'] != null, 'Required key "RecipeTags[fried]" has a null value in JSON.');
        assert(json.containsKey(r'santan'), 'Required key "RecipeTags[santan]" is missing from JSON.');
        assert(json[r'santan'] != null, 'Required key "RecipeTags[santan]" has a null value in JSON.');
        assert(json.containsKey(r'spiceLevel'), 'Required key "RecipeTags[spiceLevel]" is missing from JSON.');
        assert(json[r'spiceLevel'] != null, 'Required key "RecipeTags[spiceLevel]" has a null value in JSON.');
        return true;
      }());

      return RecipeTags(
        fried: mapValueOfType<bool>(json, r'fried')!,
        santan: mapValueOfType<bool>(json, r'santan')!,
        spiceLevel: RecipeSpiceLevel.fromJson(json[r'spiceLevel'])!,
      );
    }
    return null;
  }

  static List<RecipeTags> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeTags>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeTags.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeTags> mapFromJson(dynamic json) {
    final map = <String, RecipeTags>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeTags.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeTags-objects as value to a dart map
  static Map<String, List<RecipeTags>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeTags>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeTags.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fried',
    'santan',
    'spiceLevel',
  };
}

