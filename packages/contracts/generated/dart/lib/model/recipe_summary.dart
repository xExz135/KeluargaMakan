//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeSummary {
  /// Returns a new [RecipeSummary] instance.
  RecipeSummary({
    required this.recipeId,
    required this.version,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.region,
    this.mealTypes = const {},
    required this.prepMinutes,
    required this.cookMinutes,
    required this.totalMinutes,
    required this.difficulty,
    required this.baseServings,
    required this.tags,
    this.images = const [],
    required this.origin,
    required this.testRecord,
    required this.baseRecipeId,
  });

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  /// Minimum value: 1
  final int version;

  final LocalizedText name;

  final LocalizedText description;

  final Cuisine cuisine;

  final RecipeRegion? region;

  final Set<MealType> mealTypes;

  /// Minimum value: 0
  final int prepMinutes;

  /// Minimum value: 0
  final int cookMinutes;

  /// Minimum value: 0
  final int totalMinutes;

  final RecipeDifficulty difficulty;

  /// Servings the quantities are written for.
  ///
  /// Minimum value: 1
  final int baseServings;

  final RecipeTags tags;

  /// First image first; empty when the recipe has none (the app shows an illustration).
  final List<RecipeImage> images;

  final RecipeOrigin origin;

  final RecipeTestRecord? testRecord;

  /// Identifier of a reference ingredient or library dish.
  final String? baseRecipeId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeSummary &&
    other.recipeId == recipeId &&
    other.version == version &&
    other.name == name &&
    other.description == description &&
    other.cuisine == cuisine &&
    other.region == region &&
    _deepEquality.equals(other.mealTypes, mealTypes) &&
    other.prepMinutes == prepMinutes &&
    other.cookMinutes == cookMinutes &&
    other.totalMinutes == totalMinutes &&
    other.difficulty == difficulty &&
    other.baseServings == baseServings &&
    other.tags == tags &&
    _deepEquality.equals(other.images, images) &&
    other.origin == origin &&
    other.testRecord == testRecord &&
    other.baseRecipeId == baseRecipeId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipeId.hashCode) +
    (version.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (cuisine.hashCode) +
    (region == null ? 0 : region!.hashCode) +
    (mealTypes.hashCode) +
    (prepMinutes.hashCode) +
    (cookMinutes.hashCode) +
    (totalMinutes.hashCode) +
    (difficulty.hashCode) +
    (baseServings.hashCode) +
    (tags.hashCode) +
    (images.hashCode) +
    (origin.hashCode) +
    (testRecord == null ? 0 : testRecord!.hashCode) +
    (baseRecipeId == null ? 0 : baseRecipeId!.hashCode);

  @override
  String toString() => 'RecipeSummary[recipeId=$recipeId, version=$version, name=$name, description=$description, cuisine=$cuisine, region=$region, mealTypes=$mealTypes, prepMinutes=$prepMinutes, cookMinutes=$cookMinutes, totalMinutes=$totalMinutes, difficulty=$difficulty, baseServings=$baseServings, tags=$tags, images=$images, origin=$origin, testRecord=$testRecord, baseRecipeId=$baseRecipeId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipeId'] = this.recipeId;
      json[r'version'] = this.version;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'cuisine'] = this.cuisine;
    if (this.region != null) {
      json[r'region'] = this.region;
    } else {
      json[r'region'] = null;
    }
      json[r'mealTypes'] = this.mealTypes.toList(growable: false);
      json[r'prepMinutes'] = this.prepMinutes;
      json[r'cookMinutes'] = this.cookMinutes;
      json[r'totalMinutes'] = this.totalMinutes;
      json[r'difficulty'] = this.difficulty;
      json[r'baseServings'] = this.baseServings;
      json[r'tags'] = this.tags;
      json[r'images'] = this.images;
      json[r'origin'] = this.origin;
    if (this.testRecord != null) {
      json[r'testRecord'] = this.testRecord;
    } else {
      json[r'testRecord'] = null;
    }
    if (this.baseRecipeId != null) {
      json[r'baseRecipeId'] = this.baseRecipeId;
    } else {
      json[r'baseRecipeId'] = null;
    }
    return json;
  }

  /// Clones this instance of [RecipeSummary] and returns a new one where some of the
  /// properties have changed.
  RecipeSummary copyWith({
    String? recipeId,
    int? version,
    LocalizedText? name,
    LocalizedText? description,
    Cuisine? cuisine,
    RecipeRegion? region,
    bool regionSetToNull = false,
    Set<MealType>? mealTypes,
    int? prepMinutes,
    int? cookMinutes,
    int? totalMinutes,
    RecipeDifficulty? difficulty,
    int? baseServings,
    RecipeTags? tags,
    List<RecipeImage>? images,
    RecipeOrigin? origin,
    RecipeTestRecord? testRecord,
    bool testRecordSetToNull = false,
    String? baseRecipeId,
    bool baseRecipeIdSetToNull = false,
  }) => RecipeSummary(
    recipeId: recipeId ?? this.recipeId,
    version: version ?? this.version,
    name: name ?? this.name,
    description: description ?? this.description,
    cuisine: cuisine ?? this.cuisine,
    region: regionSetToNull ? null : region ?? this.region,
    mealTypes: mealTypes ?? this.mealTypes,
    prepMinutes: prepMinutes ?? this.prepMinutes,
    cookMinutes: cookMinutes ?? this.cookMinutes,
    totalMinutes: totalMinutes ?? this.totalMinutes,
    difficulty: difficulty ?? this.difficulty,
    baseServings: baseServings ?? this.baseServings,
    tags: tags ?? this.tags,
    images: images ?? this.images,
    origin: origin ?? this.origin,
    testRecord: testRecordSetToNull ? null : testRecord ?? this.testRecord,
    baseRecipeId: baseRecipeIdSetToNull ? null : baseRecipeId ?? this.baseRecipeId,
  );

  /// Returns a new [RecipeSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipeId'), 'Required key "RecipeSummary[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "RecipeSummary[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'version'), 'Required key "RecipeSummary[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "RecipeSummary[version]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "RecipeSummary[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "RecipeSummary[name]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "RecipeSummary[description]" is missing from JSON.');
        assert(json[r'description'] != null, 'Required key "RecipeSummary[description]" has a null value in JSON.');
        assert(json.containsKey(r'cuisine'), 'Required key "RecipeSummary[cuisine]" is missing from JSON.');
        assert(json[r'cuisine'] != null, 'Required key "RecipeSummary[cuisine]" has a null value in JSON.');
        assert(json.containsKey(r'region'), 'Required key "RecipeSummary[region]" is missing from JSON.');
        assert(json.containsKey(r'mealTypes'), 'Required key "RecipeSummary[mealTypes]" is missing from JSON.');
        assert(json[r'mealTypes'] != null, 'Required key "RecipeSummary[mealTypes]" has a null value in JSON.');
        assert(json.containsKey(r'prepMinutes'), 'Required key "RecipeSummary[prepMinutes]" is missing from JSON.');
        assert(json[r'prepMinutes'] != null, 'Required key "RecipeSummary[prepMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'cookMinutes'), 'Required key "RecipeSummary[cookMinutes]" is missing from JSON.');
        assert(json[r'cookMinutes'] != null, 'Required key "RecipeSummary[cookMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'totalMinutes'), 'Required key "RecipeSummary[totalMinutes]" is missing from JSON.');
        assert(json[r'totalMinutes'] != null, 'Required key "RecipeSummary[totalMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'difficulty'), 'Required key "RecipeSummary[difficulty]" is missing from JSON.');
        assert(json[r'difficulty'] != null, 'Required key "RecipeSummary[difficulty]" has a null value in JSON.');
        assert(json.containsKey(r'baseServings'), 'Required key "RecipeSummary[baseServings]" is missing from JSON.');
        assert(json[r'baseServings'] != null, 'Required key "RecipeSummary[baseServings]" has a null value in JSON.');
        assert(json.containsKey(r'tags'), 'Required key "RecipeSummary[tags]" is missing from JSON.');
        assert(json[r'tags'] != null, 'Required key "RecipeSummary[tags]" has a null value in JSON.');
        assert(json.containsKey(r'images'), 'Required key "RecipeSummary[images]" is missing from JSON.');
        assert(json[r'images'] != null, 'Required key "RecipeSummary[images]" has a null value in JSON.');
        assert(json.containsKey(r'origin'), 'Required key "RecipeSummary[origin]" is missing from JSON.');
        assert(json[r'origin'] != null, 'Required key "RecipeSummary[origin]" has a null value in JSON.');
        assert(json.containsKey(r'testRecord'), 'Required key "RecipeSummary[testRecord]" is missing from JSON.');
        assert(json.containsKey(r'baseRecipeId'), 'Required key "RecipeSummary[baseRecipeId]" is missing from JSON.');
        return true;
      }());

      return RecipeSummary(
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        version: mapValueOfType<int>(json, r'version')!,
        name: LocalizedText.fromJson(json[r'name'])!,
        description: LocalizedText.fromJson(json[r'description'])!,
        cuisine: Cuisine.fromJson(json[r'cuisine'])!,
        region: RecipeRegion.fromJson(json[r'region']),
        mealTypes: MealType.listFromJson(json[r'mealTypes']).toSet(),
        prepMinutes: mapValueOfType<int>(json, r'prepMinutes')!,
        cookMinutes: mapValueOfType<int>(json, r'cookMinutes')!,
        totalMinutes: mapValueOfType<int>(json, r'totalMinutes')!,
        difficulty: RecipeDifficulty.fromJson(json[r'difficulty'])!,
        baseServings: mapValueOfType<int>(json, r'baseServings')!,
        tags: RecipeTags.fromJson(json[r'tags'])!,
        images: RecipeImage.listFromJson(json[r'images']),
        origin: RecipeOrigin.fromJson(json[r'origin'])!,
        testRecord: RecipeTestRecord.fromJson(json[r'testRecord']),
        baseRecipeId: mapValueOfType<String>(json, r'baseRecipeId'),
      );
    }
    return null;
  }

  static List<RecipeSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeSummary> mapFromJson(dynamic json) {
    final map = <String, RecipeSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeSummary-objects as value to a dart map
  static Map<String, List<RecipeSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recipeId',
    'version',
    'name',
    'description',
    'cuisine',
    'region',
    'mealTypes',
    'prepMinutes',
    'cookMinutes',
    'totalMinutes',
    'difficulty',
    'baseServings',
    'tags',
    'images',
    'origin',
    'testRecord',
    'baseRecipeId',
  };
}

