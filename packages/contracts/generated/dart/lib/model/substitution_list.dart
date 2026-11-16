//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SubstitutionList {
  /// Returns a new [SubstitutionList] instance.
  SubstitutionList({
    required this.recipeId,
    required this.recipeVersion,
    this.lines = const [],
    this.variants = const [],
    required this.hiddenCount,
    required this.aiAvailability,
  });

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  /// Minimum value: 1
  final int recipeVersion;

  /// Only lines that have at least one listed option.
  final List<SubstitutionLine> lines;

  final List<RecipeVariant> variants;

  /// Options left out because they are Not safe or could not be checked (`subs.hidden`).
  ///
  /// Minimum value: 0
  final int hiddenCount;

  final AiAvailability aiAvailability;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubstitutionList &&
    other.recipeId == recipeId &&
    other.recipeVersion == recipeVersion &&
    _deepEquality.equals(other.lines, lines) &&
    _deepEquality.equals(other.variants, variants) &&
    other.hiddenCount == hiddenCount &&
    other.aiAvailability == aiAvailability;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipeId.hashCode) +
    (recipeVersion.hashCode) +
    (lines.hashCode) +
    (variants.hashCode) +
    (hiddenCount.hashCode) +
    (aiAvailability.hashCode);

  @override
  String toString() => 'SubstitutionList[recipeId=$recipeId, recipeVersion=$recipeVersion, lines=$lines, variants=$variants, hiddenCount=$hiddenCount, aiAvailability=$aiAvailability]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipeId'] = this.recipeId;
      json[r'recipeVersion'] = this.recipeVersion;
      json[r'lines'] = this.lines;
      json[r'variants'] = this.variants;
      json[r'hiddenCount'] = this.hiddenCount;
      json[r'aiAvailability'] = this.aiAvailability;
    return json;
  }

  /// Clones this instance of [SubstitutionList] and returns a new one where some of the
  /// properties have changed.
  SubstitutionList copyWith({
    String? recipeId,
    int? recipeVersion,
    List<SubstitutionLine>? lines,
    List<RecipeVariant>? variants,
    int? hiddenCount,
    AiAvailability? aiAvailability,
  }) => SubstitutionList(
    recipeId: recipeId ?? this.recipeId,
    recipeVersion: recipeVersion ?? this.recipeVersion,
    lines: lines ?? this.lines,
    variants: variants ?? this.variants,
    hiddenCount: hiddenCount ?? this.hiddenCount,
    aiAvailability: aiAvailability ?? this.aiAvailability,
  );

  /// Returns a new [SubstitutionList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubstitutionList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipeId'), 'Required key "SubstitutionList[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "SubstitutionList[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'recipeVersion'), 'Required key "SubstitutionList[recipeVersion]" is missing from JSON.');
        assert(json[r'recipeVersion'] != null, 'Required key "SubstitutionList[recipeVersion]" has a null value in JSON.');
        assert(json.containsKey(r'lines'), 'Required key "SubstitutionList[lines]" is missing from JSON.');
        assert(json[r'lines'] != null, 'Required key "SubstitutionList[lines]" has a null value in JSON.');
        assert(json.containsKey(r'variants'), 'Required key "SubstitutionList[variants]" is missing from JSON.');
        assert(json[r'variants'] != null, 'Required key "SubstitutionList[variants]" has a null value in JSON.');
        assert(json.containsKey(r'hiddenCount'), 'Required key "SubstitutionList[hiddenCount]" is missing from JSON.');
        assert(json[r'hiddenCount'] != null, 'Required key "SubstitutionList[hiddenCount]" has a null value in JSON.');
        assert(json.containsKey(r'aiAvailability'), 'Required key "SubstitutionList[aiAvailability]" is missing from JSON.');
        assert(json[r'aiAvailability'] != null, 'Required key "SubstitutionList[aiAvailability]" has a null value in JSON.');
        return true;
      }());

      return SubstitutionList(
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        recipeVersion: mapValueOfType<int>(json, r'recipeVersion')!,
        lines: SubstitutionLine.listFromJson(json[r'lines']),
        variants: RecipeVariant.listFromJson(json[r'variants']),
        hiddenCount: mapValueOfType<int>(json, r'hiddenCount')!,
        aiAvailability: AiAvailability.fromJson(json[r'aiAvailability'])!,
      );
    }
    return null;
  }

  static List<SubstitutionList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubstitutionList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubstitutionList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubstitutionList> mapFromJson(dynamic json) {
    final map = <String, SubstitutionList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubstitutionList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubstitutionList-objects as value to a dart map
  static Map<String, List<SubstitutionList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubstitutionList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubstitutionList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recipeId',
    'recipeVersion',
    'lines',
    'variants',
    'hiddenCount',
    'aiAvailability',
  };
}

