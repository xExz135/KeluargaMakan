//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Suggestion {
  /// Returns a new [Suggestion] instance.
  Suggestion({
    required this.itemId,
    required this.recipe,
    required this.servings,
    required this.kitchenMatch,
    required this.safety,
    required this.tradeOff,
    required this.adaptation,
    required this.variant,
    required this.withinTimeAvailable,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String itemId;

  final RecipeSummary recipe;

  /// Minimum value: 1
  final int servings;

  final KitchenMatch kitchenMatch;

  final RecipeSafety safety;

  final TradeOff? tradeOff;

  final AdaptationInfo? adaptation;

  final AppliedVariant? variant;

  final bool withinTimeAvailable;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Suggestion &&
    other.itemId == itemId &&
    other.recipe == recipe &&
    other.servings == servings &&
    other.kitchenMatch == kitchenMatch &&
    other.safety == safety &&
    other.tradeOff == tradeOff &&
    other.adaptation == adaptation &&
    other.variant == variant &&
    other.withinTimeAvailable == withinTimeAvailable;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (itemId.hashCode) +
    (recipe.hashCode) +
    (servings.hashCode) +
    (kitchenMatch.hashCode) +
    (safety.hashCode) +
    (tradeOff == null ? 0 : tradeOff!.hashCode) +
    (adaptation == null ? 0 : adaptation!.hashCode) +
    (variant == null ? 0 : variant!.hashCode) +
    (withinTimeAvailable.hashCode);

  @override
  String toString() => 'Suggestion[itemId=$itemId, recipe=$recipe, servings=$servings, kitchenMatch=$kitchenMatch, safety=$safety, tradeOff=$tradeOff, adaptation=$adaptation, variant=$variant, withinTimeAvailable=$withinTimeAvailable]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'itemId'] = this.itemId;
      json[r'recipe'] = this.recipe;
      json[r'servings'] = this.servings;
      json[r'kitchenMatch'] = this.kitchenMatch;
      json[r'safety'] = this.safety;
    if (this.tradeOff != null) {
      json[r'tradeOff'] = this.tradeOff;
    } else {
      json[r'tradeOff'] = null;
    }
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
      json[r'withinTimeAvailable'] = this.withinTimeAvailable;
    return json;
  }

  /// Clones this instance of [Suggestion] and returns a new one where some of the
  /// properties have changed.
  Suggestion copyWith({
    String? itemId,
    RecipeSummary? recipe,
    int? servings,
    KitchenMatch? kitchenMatch,
    RecipeSafety? safety,
    TradeOff? tradeOff,
    bool tradeOffSetToNull = false,
    AdaptationInfo? adaptation,
    bool adaptationSetToNull = false,
    AppliedVariant? variant,
    bool variantSetToNull = false,
    bool? withinTimeAvailable,
  }) => Suggestion(
    itemId: itemId ?? this.itemId,
    recipe: recipe ?? this.recipe,
    servings: servings ?? this.servings,
    kitchenMatch: kitchenMatch ?? this.kitchenMatch,
    safety: safety ?? this.safety,
    tradeOff: tradeOffSetToNull ? null : tradeOff ?? this.tradeOff,
    adaptation: adaptationSetToNull ? null : adaptation ?? this.adaptation,
    variant: variantSetToNull ? null : variant ?? this.variant,
    withinTimeAvailable: withinTimeAvailable ?? this.withinTimeAvailable,
  );

  /// Returns a new [Suggestion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Suggestion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'itemId'), 'Required key "Suggestion[itemId]" is missing from JSON.');
        assert(json[r'itemId'] != null, 'Required key "Suggestion[itemId]" has a null value in JSON.');
        assert(json.containsKey(r'recipe'), 'Required key "Suggestion[recipe]" is missing from JSON.');
        assert(json[r'recipe'] != null, 'Required key "Suggestion[recipe]" has a null value in JSON.');
        assert(json.containsKey(r'servings'), 'Required key "Suggestion[servings]" is missing from JSON.');
        assert(json[r'servings'] != null, 'Required key "Suggestion[servings]" has a null value in JSON.');
        assert(json.containsKey(r'kitchenMatch'), 'Required key "Suggestion[kitchenMatch]" is missing from JSON.');
        assert(json[r'kitchenMatch'] != null, 'Required key "Suggestion[kitchenMatch]" has a null value in JSON.');
        assert(json.containsKey(r'safety'), 'Required key "Suggestion[safety]" is missing from JSON.');
        assert(json[r'safety'] != null, 'Required key "Suggestion[safety]" has a null value in JSON.');
        assert(json.containsKey(r'tradeOff'), 'Required key "Suggestion[tradeOff]" is missing from JSON.');
        assert(json.containsKey(r'adaptation'), 'Required key "Suggestion[adaptation]" is missing from JSON.');
        assert(json.containsKey(r'variant'), 'Required key "Suggestion[variant]" is missing from JSON.');
        assert(json.containsKey(r'withinTimeAvailable'), 'Required key "Suggestion[withinTimeAvailable]" is missing from JSON.');
        assert(json[r'withinTimeAvailable'] != null, 'Required key "Suggestion[withinTimeAvailable]" has a null value in JSON.');
        return true;
      }());

      return Suggestion(
        itemId: mapValueOfType<String>(json, r'itemId')!,
        recipe: RecipeSummary.fromJson(json[r'recipe'])!,
        servings: mapValueOfType<int>(json, r'servings')!,
        kitchenMatch: KitchenMatch.fromJson(json[r'kitchenMatch'])!,
        safety: RecipeSafety.fromJson(json[r'safety'])!,
        tradeOff: TradeOff.fromJson(json[r'tradeOff']),
        adaptation: AdaptationInfo.fromJson(json[r'adaptation']),
        variant: AppliedVariant.fromJson(json[r'variant']),
        withinTimeAvailable: mapValueOfType<bool>(json, r'withinTimeAvailable')!,
      );
    }
    return null;
  }

  static List<Suggestion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Suggestion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Suggestion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Suggestion> mapFromJson(dynamic json) {
    final map = <String, Suggestion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Suggestion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Suggestion-objects as value to a dart map
  static Map<String, List<Suggestion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Suggestion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Suggestion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'itemId',
    'recipe',
    'servings',
    'kitchenMatch',
    'safety',
    'tradeOff',
    'adaptation',
    'variant',
    'withinTimeAvailable',
  };
}

