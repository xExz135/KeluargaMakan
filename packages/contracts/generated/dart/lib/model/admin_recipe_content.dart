//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRecipeContent {
  /// Returns a new [AdminRecipeContent] instance.
  AdminRecipeContent({
    required this.name,
    required this.description,
    required this.cuisine,
    required this.regionId,
    this.mealTypes = const {},
    required this.baseServings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    this.ingredients = const [],
    this.steps = const [],
    required this.tags,
    this.imageIds = const {},
    required this.baseRecipeId,
    this.substitutions = const [],
    this.variants = const [],
  });

  final LocalizedText name;

  final LocalizedText description;

  final Cuisine cuisine;

  /// Identifier of a reference ingredient or library dish.
  final String? regionId;

  final Set<MealType> mealTypes;

  /// Minimum value: 1
  /// Maximum value: 50
  final int baseServings;

  /// Minimum value: 0
  final int prepMinutes;

  /// Minimum value: 0
  final int cookMinutes;

  final RecipeDifficulty difficulty;

  final List<AdminIngredientLine> ingredients;

  final List<RecipeStep> steps;

  final RecipeTags tags;

  final Set<String> imageIds;

  /// For a regional variant, the base dish (LIB-04).
  final String? baseRecipeId;

  final List<AdminSubstitution> substitutions;

  final List<AdminRecipeVariant> variants;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRecipeContent &&
    other.name == name &&
    other.description == description &&
    other.cuisine == cuisine &&
    other.regionId == regionId &&
    _deepEquality.equals(other.mealTypes, mealTypes) &&
    other.baseServings == baseServings &&
    other.prepMinutes == prepMinutes &&
    other.cookMinutes == cookMinutes &&
    other.difficulty == difficulty &&
    _deepEquality.equals(other.ingredients, ingredients) &&
    _deepEquality.equals(other.steps, steps) &&
    other.tags == tags &&
    _deepEquality.equals(other.imageIds, imageIds) &&
    other.baseRecipeId == baseRecipeId &&
    _deepEquality.equals(other.substitutions, substitutions) &&
    _deepEquality.equals(other.variants, variants);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (description.hashCode) +
    (cuisine.hashCode) +
    (regionId == null ? 0 : regionId!.hashCode) +
    (mealTypes.hashCode) +
    (baseServings.hashCode) +
    (prepMinutes.hashCode) +
    (cookMinutes.hashCode) +
    (difficulty.hashCode) +
    (ingredients.hashCode) +
    (steps.hashCode) +
    (tags.hashCode) +
    (imageIds.hashCode) +
    (baseRecipeId == null ? 0 : baseRecipeId!.hashCode) +
    (substitutions.hashCode) +
    (variants.hashCode);

  @override
  String toString() => 'AdminRecipeContent[name=$name, description=$description, cuisine=$cuisine, regionId=$regionId, mealTypes=$mealTypes, baseServings=$baseServings, prepMinutes=$prepMinutes, cookMinutes=$cookMinutes, difficulty=$difficulty, ingredients=$ingredients, steps=$steps, tags=$tags, imageIds=$imageIds, baseRecipeId=$baseRecipeId, substitutions=$substitutions, variants=$variants]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'cuisine'] = this.cuisine;
    if (this.regionId != null) {
      json[r'regionId'] = this.regionId;
    } else {
      json[r'regionId'] = null;
    }
      json[r'mealTypes'] = this.mealTypes.toList(growable: false);
      json[r'baseServings'] = this.baseServings;
      json[r'prepMinutes'] = this.prepMinutes;
      json[r'cookMinutes'] = this.cookMinutes;
      json[r'difficulty'] = this.difficulty;
      json[r'ingredients'] = this.ingredients;
      json[r'steps'] = this.steps;
      json[r'tags'] = this.tags;
      json[r'imageIds'] = this.imageIds.toList(growable: false);
    if (this.baseRecipeId != null) {
      json[r'baseRecipeId'] = this.baseRecipeId;
    } else {
      json[r'baseRecipeId'] = null;
    }
      json[r'substitutions'] = this.substitutions;
      json[r'variants'] = this.variants;
    return json;
  }

  /// Clones this instance of [AdminRecipeContent] and returns a new one where some of the
  /// properties have changed.
  AdminRecipeContent copyWith({
    LocalizedText? name,
    LocalizedText? description,
    Cuisine? cuisine,
    String? regionId,
    bool regionIdSetToNull = false,
    Set<MealType>? mealTypes,
    int? baseServings,
    int? prepMinutes,
    int? cookMinutes,
    RecipeDifficulty? difficulty,
    List<AdminIngredientLine>? ingredients,
    List<RecipeStep>? steps,
    RecipeTags? tags,
    Set<String>? imageIds,
    String? baseRecipeId,
    bool baseRecipeIdSetToNull = false,
    List<AdminSubstitution>? substitutions,
    List<AdminRecipeVariant>? variants,
  }) => AdminRecipeContent(
    name: name ?? this.name,
    description: description ?? this.description,
    cuisine: cuisine ?? this.cuisine,
    regionId: regionIdSetToNull ? null : regionId ?? this.regionId,
    mealTypes: mealTypes ?? this.mealTypes,
    baseServings: baseServings ?? this.baseServings,
    prepMinutes: prepMinutes ?? this.prepMinutes,
    cookMinutes: cookMinutes ?? this.cookMinutes,
    difficulty: difficulty ?? this.difficulty,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    tags: tags ?? this.tags,
    imageIds: imageIds ?? this.imageIds,
    baseRecipeId: baseRecipeIdSetToNull ? null : baseRecipeId ?? this.baseRecipeId,
    substitutions: substitutions ?? this.substitutions,
    variants: variants ?? this.variants,
  );

  /// Returns a new [AdminRecipeContent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRecipeContent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "AdminRecipeContent[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "AdminRecipeContent[name]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "AdminRecipeContent[description]" is missing from JSON.');
        assert(json[r'description'] != null, 'Required key "AdminRecipeContent[description]" has a null value in JSON.');
        assert(json.containsKey(r'cuisine'), 'Required key "AdminRecipeContent[cuisine]" is missing from JSON.');
        assert(json[r'cuisine'] != null, 'Required key "AdminRecipeContent[cuisine]" has a null value in JSON.');
        assert(json.containsKey(r'regionId'), 'Required key "AdminRecipeContent[regionId]" is missing from JSON.');
        assert(json.containsKey(r'mealTypes'), 'Required key "AdminRecipeContent[mealTypes]" is missing from JSON.');
        assert(json[r'mealTypes'] != null, 'Required key "AdminRecipeContent[mealTypes]" has a null value in JSON.');
        assert(json.containsKey(r'baseServings'), 'Required key "AdminRecipeContent[baseServings]" is missing from JSON.');
        assert(json[r'baseServings'] != null, 'Required key "AdminRecipeContent[baseServings]" has a null value in JSON.');
        assert(json.containsKey(r'prepMinutes'), 'Required key "AdminRecipeContent[prepMinutes]" is missing from JSON.');
        assert(json[r'prepMinutes'] != null, 'Required key "AdminRecipeContent[prepMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'cookMinutes'), 'Required key "AdminRecipeContent[cookMinutes]" is missing from JSON.');
        assert(json[r'cookMinutes'] != null, 'Required key "AdminRecipeContent[cookMinutes]" has a null value in JSON.');
        assert(json.containsKey(r'difficulty'), 'Required key "AdminRecipeContent[difficulty]" is missing from JSON.');
        assert(json[r'difficulty'] != null, 'Required key "AdminRecipeContent[difficulty]" has a null value in JSON.');
        assert(json.containsKey(r'ingredients'), 'Required key "AdminRecipeContent[ingredients]" is missing from JSON.');
        assert(json[r'ingredients'] != null, 'Required key "AdminRecipeContent[ingredients]" has a null value in JSON.');
        assert(json.containsKey(r'steps'), 'Required key "AdminRecipeContent[steps]" is missing from JSON.');
        assert(json[r'steps'] != null, 'Required key "AdminRecipeContent[steps]" has a null value in JSON.');
        assert(json.containsKey(r'tags'), 'Required key "AdminRecipeContent[tags]" is missing from JSON.');
        assert(json[r'tags'] != null, 'Required key "AdminRecipeContent[tags]" has a null value in JSON.');
        assert(json.containsKey(r'imageIds'), 'Required key "AdminRecipeContent[imageIds]" is missing from JSON.');
        assert(json[r'imageIds'] != null, 'Required key "AdminRecipeContent[imageIds]" has a null value in JSON.');
        assert(json.containsKey(r'baseRecipeId'), 'Required key "AdminRecipeContent[baseRecipeId]" is missing from JSON.');
        assert(json.containsKey(r'substitutions'), 'Required key "AdminRecipeContent[substitutions]" is missing from JSON.');
        assert(json[r'substitutions'] != null, 'Required key "AdminRecipeContent[substitutions]" has a null value in JSON.');
        assert(json.containsKey(r'variants'), 'Required key "AdminRecipeContent[variants]" is missing from JSON.');
        assert(json[r'variants'] != null, 'Required key "AdminRecipeContent[variants]" has a null value in JSON.');
        return true;
      }());

      return AdminRecipeContent(
        name: LocalizedText.fromJson(json[r'name'])!,
        description: LocalizedText.fromJson(json[r'description'])!,
        cuisine: Cuisine.fromJson(json[r'cuisine'])!,
        regionId: mapValueOfType<String>(json, r'regionId'),
        mealTypes: MealType.listFromJson(json[r'mealTypes']).toSet(),
        baseServings: mapValueOfType<int>(json, r'baseServings')!,
        prepMinutes: mapValueOfType<int>(json, r'prepMinutes')!,
        cookMinutes: mapValueOfType<int>(json, r'cookMinutes')!,
        difficulty: RecipeDifficulty.fromJson(json[r'difficulty'])!,
        ingredients: AdminIngredientLine.listFromJson(json[r'ingredients']),
        steps: RecipeStep.listFromJson(json[r'steps']),
        tags: RecipeTags.fromJson(json[r'tags'])!,
        imageIds: json[r'imageIds'] is Iterable
            ? (json[r'imageIds'] as Iterable).cast<String>().toSet()
            : const {},
        baseRecipeId: mapValueOfType<String>(json, r'baseRecipeId'),
        substitutions: AdminSubstitution.listFromJson(json[r'substitutions']),
        variants: AdminRecipeVariant.listFromJson(json[r'variants']),
      );
    }
    return null;
  }

  static List<AdminRecipeContent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRecipeContent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRecipeContent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRecipeContent> mapFromJson(dynamic json) {
    final map = <String, AdminRecipeContent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRecipeContent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRecipeContent-objects as value to a dart map
  static Map<String, List<AdminRecipeContent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRecipeContent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRecipeContent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'description',
    'cuisine',
    'regionId',
    'mealTypes',
    'baseServings',
    'prepMinutes',
    'cookMinutes',
    'difficulty',
    'ingredients',
    'steps',
    'tags',
    'imageIds',
    'baseRecipeId',
    'substitutions',
    'variants',
  };
}

