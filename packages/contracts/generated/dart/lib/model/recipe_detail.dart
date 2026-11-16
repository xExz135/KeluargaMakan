//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeDetail {
  /// Returns a new [RecipeDetail] instance.
  RecipeDetail({
    required this.recipe,
    this.ingredients = const [],
    this.steps = const [],
    required this.servings,
    required this.kitchenMatch,
    required this.safety,
    required this.adaptation,
    required this.variant,
    this.appliedSubstitutionIds = const {},
    this.regionalVariants = const [],
    required this.nutritionPerServing,
    required this.tradeOff,
    required this.aiAvailability,
  });

  final RecipeSummary recipe;

  final List<RecipeIngredientLine> ingredients;

  final List<RecipeStep> steps;

  /// Minimum value: 1
  final int servings;

  final KitchenMatch kitchenMatch;

  final RecipeSafety safety;

  final AdaptationInfo? adaptation;

  final AppliedVariant? variant;

  final Set<String> appliedSubstitutionIds;

  final List<LibraryRecipeListItem> regionalVariants;

  final NutritionPerServing nutritionPerServing;

  final TradeOff? tradeOff;

  final AiAvailability aiAvailability;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeDetail &&
    other.recipe == recipe &&
    _deepEquality.equals(other.ingredients, ingredients) &&
    _deepEquality.equals(other.steps, steps) &&
    other.servings == servings &&
    other.kitchenMatch == kitchenMatch &&
    other.safety == safety &&
    other.adaptation == adaptation &&
    other.variant == variant &&
    _deepEquality.equals(other.appliedSubstitutionIds, appliedSubstitutionIds) &&
    _deepEquality.equals(other.regionalVariants, regionalVariants) &&
    other.nutritionPerServing == nutritionPerServing &&
    other.tradeOff == tradeOff &&
    other.aiAvailability == aiAvailability;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipe.hashCode) +
    (ingredients.hashCode) +
    (steps.hashCode) +
    (servings.hashCode) +
    (kitchenMatch.hashCode) +
    (safety.hashCode) +
    (adaptation == null ? 0 : adaptation!.hashCode) +
    (variant == null ? 0 : variant!.hashCode) +
    (appliedSubstitutionIds.hashCode) +
    (regionalVariants.hashCode) +
    (nutritionPerServing.hashCode) +
    (tradeOff == null ? 0 : tradeOff!.hashCode) +
    (aiAvailability.hashCode);

  @override
  String toString() => 'RecipeDetail[recipe=$recipe, ingredients=$ingredients, steps=$steps, servings=$servings, kitchenMatch=$kitchenMatch, safety=$safety, adaptation=$adaptation, variant=$variant, appliedSubstitutionIds=$appliedSubstitutionIds, regionalVariants=$regionalVariants, nutritionPerServing=$nutritionPerServing, tradeOff=$tradeOff, aiAvailability=$aiAvailability]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipe'] = this.recipe;
      json[r'ingredients'] = this.ingredients;
      json[r'steps'] = this.steps;
      json[r'servings'] = this.servings;
      json[r'kitchenMatch'] = this.kitchenMatch;
      json[r'safety'] = this.safety;
    if (this.adaptation != null) {
      json[r'adaptation'] = this.adaptation;
    } else {
      json[r'adaptation'] = null;
    }
    if (this.variant != null) {
      json[r'variant'] = this.variant;
    } else {
      json[r'variant'] = null;
    }
      json[r'appliedSubstitutionIds'] = this.appliedSubstitutionIds.toList(growable: false);
      json[r'regionalVariants'] = this.regionalVariants;
      json[r'nutritionPerServing'] = this.nutritionPerServing;
    if (this.tradeOff != null) {
      json[r'tradeOff'] = this.tradeOff;
    } else {
      json[r'tradeOff'] = null;
    }
      json[r'aiAvailability'] = this.aiAvailability;
    return json;
  }

  /// Clones this instance of [RecipeDetail] and returns a new one where some of the
  /// properties have changed.
  RecipeDetail copyWith({
    RecipeSummary? recipe,
    List<RecipeIngredientLine>? ingredients,
    List<RecipeStep>? steps,
    int? servings,
    KitchenMatch? kitchenMatch,
    RecipeSafety? safety,
    AdaptationInfo? adaptation,
    bool adaptationSetToNull = false,
    AppliedVariant? variant,
    bool variantSetToNull = false,
    Set<String>? appliedSubstitutionIds,
    List<LibraryRecipeListItem>? regionalVariants,
    NutritionPerServing? nutritionPerServing,
    TradeOff? tradeOff,
    bool tradeOffSetToNull = false,
    AiAvailability? aiAvailability,
  }) => RecipeDetail(
    recipe: recipe ?? this.recipe,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    servings: servings ?? this.servings,
    kitchenMatch: kitchenMatch ?? this.kitchenMatch,
    safety: safety ?? this.safety,
    adaptation: adaptationSetToNull ? null : adaptation ?? this.adaptation,
    variant: variantSetToNull ? null : variant ?? this.variant,
    appliedSubstitutionIds: appliedSubstitutionIds ?? this.appliedSubstitutionIds,
    regionalVariants: regionalVariants ?? this.regionalVariants,
    nutritionPerServing: nutritionPerServing ?? this.nutritionPerServing,
    tradeOff: tradeOffSetToNull ? null : tradeOff ?? this.tradeOff,
    aiAvailability: aiAvailability ?? this.aiAvailability,
  );

  /// Returns a new [RecipeDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipe'), 'Required key "RecipeDetail[recipe]" is missing from JSON.');
        assert(json[r'recipe'] != null, 'Required key "RecipeDetail[recipe]" has a null value in JSON.');
        assert(json.containsKey(r'ingredients'), 'Required key "RecipeDetail[ingredients]" is missing from JSON.');
        assert(json[r'ingredients'] != null, 'Required key "RecipeDetail[ingredients]" has a null value in JSON.');
        assert(json.containsKey(r'steps'), 'Required key "RecipeDetail[steps]" is missing from JSON.');
        assert(json[r'steps'] != null, 'Required key "RecipeDetail[steps]" has a null value in JSON.');
        assert(json.containsKey(r'servings'), 'Required key "RecipeDetail[servings]" is missing from JSON.');
        assert(json[r'servings'] != null, 'Required key "RecipeDetail[servings]" has a null value in JSON.');
        assert(json.containsKey(r'kitchenMatch'), 'Required key "RecipeDetail[kitchenMatch]" is missing from JSON.');
        assert(json[r'kitchenMatch'] != null, 'Required key "RecipeDetail[kitchenMatch]" has a null value in JSON.');
        assert(json.containsKey(r'safety'), 'Required key "RecipeDetail[safety]" is missing from JSON.');
        assert(json[r'safety'] != null, 'Required key "RecipeDetail[safety]" has a null value in JSON.');
        assert(json.containsKey(r'adaptation'), 'Required key "RecipeDetail[adaptation]" is missing from JSON.');
        assert(json.containsKey(r'variant'), 'Required key "RecipeDetail[variant]" is missing from JSON.');
        assert(json.containsKey(r'appliedSubstitutionIds'), 'Required key "RecipeDetail[appliedSubstitutionIds]" is missing from JSON.');
        assert(json[r'appliedSubstitutionIds'] != null, 'Required key "RecipeDetail[appliedSubstitutionIds]" has a null value in JSON.');
        assert(json.containsKey(r'regionalVariants'), 'Required key "RecipeDetail[regionalVariants]" is missing from JSON.');
        assert(json[r'regionalVariants'] != null, 'Required key "RecipeDetail[regionalVariants]" has a null value in JSON.');
        assert(json.containsKey(r'nutritionPerServing'), 'Required key "RecipeDetail[nutritionPerServing]" is missing from JSON.');
        assert(json[r'nutritionPerServing'] != null, 'Required key "RecipeDetail[nutritionPerServing]" has a null value in JSON.');
        assert(json.containsKey(r'tradeOff'), 'Required key "RecipeDetail[tradeOff]" is missing from JSON.');
        assert(json.containsKey(r'aiAvailability'), 'Required key "RecipeDetail[aiAvailability]" is missing from JSON.');
        assert(json[r'aiAvailability'] != null, 'Required key "RecipeDetail[aiAvailability]" has a null value in JSON.');
        return true;
      }());

      return RecipeDetail(
        recipe: RecipeSummary.fromJson(json[r'recipe'])!,
        ingredients: RecipeIngredientLine.listFromJson(json[r'ingredients']),
        steps: RecipeStep.listFromJson(json[r'steps']),
        servings: mapValueOfType<int>(json, r'servings')!,
        kitchenMatch: KitchenMatch.fromJson(json[r'kitchenMatch'])!,
        safety: RecipeSafety.fromJson(json[r'safety'])!,
        adaptation: AdaptationInfo.fromJson(json[r'adaptation']),
        variant: AppliedVariant.fromJson(json[r'variant']),
        appliedSubstitutionIds: json[r'appliedSubstitutionIds'] is Iterable
            ? (json[r'appliedSubstitutionIds'] as Iterable).cast<String>().toSet()
            : const {},
        regionalVariants: LibraryRecipeListItem.listFromJson(json[r'regionalVariants']),
        nutritionPerServing: NutritionPerServing.fromJson(json[r'nutritionPerServing'])!,
        tradeOff: TradeOff.fromJson(json[r'tradeOff']),
        aiAvailability: AiAvailability.fromJson(json[r'aiAvailability'])!,
      );
    }
    return null;
  }

  static List<RecipeDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeDetail> mapFromJson(dynamic json) {
    final map = <String, RecipeDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeDetail-objects as value to a dart map
  static Map<String, List<RecipeDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recipe',
    'ingredients',
    'steps',
    'servings',
    'kitchenMatch',
    'safety',
    'adaptation',
    'variant',
    'appliedSubstitutionIds',
    'regionalVariants',
    'nutritionPerServing',
    'tradeOff',
    'aiAvailability',
  };
}

