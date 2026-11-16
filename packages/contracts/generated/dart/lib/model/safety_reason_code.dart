//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Reason codes from the Cek Aman engine (`packages/cek-aman`). Like `ErrorCode`, codes may be added: a client that does not know a code still renders the member's `status` and shows the generic missing-data line, and never hides a Not safe result or shows it as safe. Until the app decodes unknown codes that way, new codes come with a version bump (QUESTIONS #82).
enum SafetyReasonCode {
  allergenContains._(r'allergen_contains'),
  halalNotHalal._(r'halal_not_halal'),
  dietNotSuitable._(r'diet_not_suitable'),
  excludedIngredient._(r'excluded_ingredient'),
  noIngredients._(r'no_ingredients'),
  ingredientUnresolved._(r'ingredient_unresolved'),
  ingredientNotInReference._(r'ingredient_not_in_reference'),
  componentsUnverified._(r'components_unverified'),
  componentNotInReference._(r'component_not_in_reference'),
  componentCycle._(r'component_cycle'),
  allergensUnverified._(r'allergens_unverified'),
  allergenMayContain._(r'allergen_may_contain'),
  allergenRelated._(r'allergen_related'),
  allergenUnrecognized._(r'allergen_unrecognized'),
  halalUncertain._(r'halal_uncertain'),
  dietUncertain._(r'diet_uncertain'),
  brandNotRecorded._(r'brand_not_recorded'),
  brandUnverified._(r'brand_unverified'),
  componentBrandVaries._(r'component_brand_varies'),
  ruleUnmapped._(r'rule_unmapped'),
  ruleMappingUnconfirmed._(r'rule_mapping_unconfirmed'),
  ruleMappingUnknownIngredient._(r'rule_mapping_unknown_ingredient'),
  ruleInvalid._(r'rule_invalid'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetyReasonCode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetyReasonCode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetyReasonCode? fromJson(dynamic value) => SafetyReasonCodeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetyReasonCode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetyReasonCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReasonCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReasonCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetyReasonCode] to String,
/// and [decode] dynamic data back to [SafetyReasonCode].
class SafetyReasonCodeTypeTransformer {
  factory SafetyReasonCodeTypeTransformer() => _instance ??= const SafetyReasonCodeTypeTransformer._();

  const SafetyReasonCodeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetyReasonCode data) => data._value;

  /// Returns the instance of [SafetyReasonCode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetyReasonCode? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetyReasonCode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'allergen_contains': return SafetyReasonCode.allergenContains;
        case r'halal_not_halal': return SafetyReasonCode.halalNotHalal;
        case r'diet_not_suitable': return SafetyReasonCode.dietNotSuitable;
        case r'excluded_ingredient': return SafetyReasonCode.excludedIngredient;
        case r'no_ingredients': return SafetyReasonCode.noIngredients;
        case r'ingredient_unresolved': return SafetyReasonCode.ingredientUnresolved;
        case r'ingredient_not_in_reference': return SafetyReasonCode.ingredientNotInReference;
        case r'components_unverified': return SafetyReasonCode.componentsUnverified;
        case r'component_not_in_reference': return SafetyReasonCode.componentNotInReference;
        case r'component_cycle': return SafetyReasonCode.componentCycle;
        case r'allergens_unverified': return SafetyReasonCode.allergensUnverified;
        case r'allergen_may_contain': return SafetyReasonCode.allergenMayContain;
        case r'allergen_related': return SafetyReasonCode.allergenRelated;
        case r'allergen_unrecognized': return SafetyReasonCode.allergenUnrecognized;
        case r'halal_uncertain': return SafetyReasonCode.halalUncertain;
        case r'diet_uncertain': return SafetyReasonCode.dietUncertain;
        case r'brand_not_recorded': return SafetyReasonCode.brandNotRecorded;
        case r'brand_unverified': return SafetyReasonCode.brandUnverified;
        case r'component_brand_varies': return SafetyReasonCode.componentBrandVaries;
        case r'rule_unmapped': return SafetyReasonCode.ruleUnmapped;
        case r'rule_mapping_unconfirmed': return SafetyReasonCode.ruleMappingUnconfirmed;
        case r'rule_mapping_unknown_ingredient': return SafetyReasonCode.ruleMappingUnknownIngredient;
        case r'rule_invalid': return SafetyReasonCode.ruleInvalid;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetyReasonCodeTypeTransformer? _instance;
}

