//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SoftPreferencesInput {
  /// Returns a new [SoftPreferencesInput] instance.
  SoftPreferencesInput({
    required this.spiceLevel,
    this.lessOf = const {},
    this.textures = const {},
  });

  /// Null when not chosen (ranked as `medium`).
  final SpiceLevel? spiceLevel;

  final Set<LessOf> lessOf;

  final Set<TexturePreference> textures;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SoftPreferencesInput &&
    other.spiceLevel == spiceLevel &&
    _deepEquality.equals(other.lessOf, lessOf) &&
    _deepEquality.equals(other.textures, textures);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (spiceLevel == null ? 0 : spiceLevel!.hashCode) +
    (lessOf.hashCode) +
    (textures.hashCode);

  @override
  String toString() => 'SoftPreferencesInput[spiceLevel=$spiceLevel, lessOf=$lessOf, textures=$textures]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.spiceLevel != null) {
      json[r'spiceLevel'] = this.spiceLevel;
    } else {
      json[r'spiceLevel'] = null;
    }
      json[r'lessOf'] = this.lessOf.toList(growable: false);
      json[r'textures'] = this.textures.toList(growable: false);
    return json;
  }

  /// Clones this instance of [SoftPreferencesInput] and returns a new one where some of the
  /// properties have changed.
  SoftPreferencesInput copyWith({
    SpiceLevel? spiceLevel,
    bool spiceLevelSetToNull = false,
    Set<LessOf>? lessOf,
    Set<TexturePreference>? textures,
  }) => SoftPreferencesInput(
    spiceLevel: spiceLevelSetToNull ? null : spiceLevel ?? this.spiceLevel,
    lessOf: lessOf ?? this.lessOf,
    textures: textures ?? this.textures,
  );

  /// Returns a new [SoftPreferencesInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SoftPreferencesInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'spiceLevel'), 'Required key "SoftPreferencesInput[spiceLevel]" is missing from JSON.');
        assert(json.containsKey(r'lessOf'), 'Required key "SoftPreferencesInput[lessOf]" is missing from JSON.');
        assert(json[r'lessOf'] != null, 'Required key "SoftPreferencesInput[lessOf]" has a null value in JSON.');
        assert(json.containsKey(r'textures'), 'Required key "SoftPreferencesInput[textures]" is missing from JSON.');
        assert(json[r'textures'] != null, 'Required key "SoftPreferencesInput[textures]" has a null value in JSON.');
        return true;
      }());

      return SoftPreferencesInput(
        spiceLevel: SpiceLevel.fromJson(json[r'spiceLevel']),
        lessOf: LessOf.listFromJson(json[r'lessOf']).toSet(),
        textures: TexturePreference.listFromJson(json[r'textures']).toSet(),
      );
    }
    return null;
  }

  static List<SoftPreferencesInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SoftPreferencesInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SoftPreferencesInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SoftPreferencesInput> mapFromJson(dynamic json) {
    final map = <String, SoftPreferencesInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SoftPreferencesInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SoftPreferencesInput-objects as value to a dart map
  static Map<String, List<SoftPreferencesInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SoftPreferencesInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SoftPreferencesInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'spiceLevel',
    'lessOf',
    'textures',
  };
}

