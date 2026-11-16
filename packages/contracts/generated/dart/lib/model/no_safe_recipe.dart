//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class NoSafeRecipe {
  /// Returns a new [NoSafeRecipe] instance.
  NoSafeRecipe({
    this.closestOptions = const [],
    this.conflicts = const [],
  });

  final List<Suggestion> closestOptions;

  final List<SafetyConflict> conflicts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NoSafeRecipe &&
    _deepEquality.equals(other.closestOptions, closestOptions) &&
    _deepEquality.equals(other.conflicts, conflicts);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (closestOptions.hashCode) +
    (conflicts.hashCode);

  @override
  String toString() => 'NoSafeRecipe[closestOptions=$closestOptions, conflicts=$conflicts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'closestOptions'] = this.closestOptions;
      json[r'conflicts'] = this.conflicts;
    return json;
  }

  /// Clones this instance of [NoSafeRecipe] and returns a new one where some of the
  /// properties have changed.
  NoSafeRecipe copyWith({
    List<Suggestion>? closestOptions,
    List<SafetyConflict>? conflicts,
  }) => NoSafeRecipe(
    closestOptions: closestOptions ?? this.closestOptions,
    conflicts: conflicts ?? this.conflicts,
  );

  /// Returns a new [NoSafeRecipe] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NoSafeRecipe? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'closestOptions'), 'Required key "NoSafeRecipe[closestOptions]" is missing from JSON.');
        assert(json[r'closestOptions'] != null, 'Required key "NoSafeRecipe[closestOptions]" has a null value in JSON.');
        assert(json.containsKey(r'conflicts'), 'Required key "NoSafeRecipe[conflicts]" is missing from JSON.');
        assert(json[r'conflicts'] != null, 'Required key "NoSafeRecipe[conflicts]" has a null value in JSON.');
        return true;
      }());

      return NoSafeRecipe(
        closestOptions: Suggestion.listFromJson(json[r'closestOptions']),
        conflicts: SafetyConflict.listFromJson(json[r'conflicts']),
      );
    }
    return null;
  }

  static List<NoSafeRecipe> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NoSafeRecipe>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NoSafeRecipe.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NoSafeRecipe> mapFromJson(dynamic json) {
    final map = <String, NoSafeRecipe>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NoSafeRecipe.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NoSafeRecipe-objects as value to a dart map
  static Map<String, List<NoSafeRecipe>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NoSafeRecipe>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NoSafeRecipe.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'closestOptions',
    'conflicts',
  };
}

