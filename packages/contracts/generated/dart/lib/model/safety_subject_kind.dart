//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// SAF-02 kinds of food item a check is about, matching the Cek Aman safety log. V1 reports concern `library_recipe`, `suggestion` and `substitution`.
enum SafetySubjectKind {
  libraryRecipe._(r'library_recipe'),
  suggestion._(r'suggestion'),
  substitution._(r'substitution'),
  tasteTweakFix._(r'taste_tweak_fix'),
  plannedMeal._(r'planned_meal'),
  familyRecipe._(r'family_recipe'),
  leftoverRemake._(r'leftover_remake'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetySubjectKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetySubjectKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetySubjectKind? fromJson(dynamic value) => SafetySubjectKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetySubjectKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetySubjectKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetySubjectKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetySubjectKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetySubjectKind] to String,
/// and [decode] dynamic data back to [SafetySubjectKind].
class SafetySubjectKindTypeTransformer {
  factory SafetySubjectKindTypeTransformer() => _instance ??= const SafetySubjectKindTypeTransformer._();

  const SafetySubjectKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetySubjectKind data) => data._value;

  /// Returns the instance of [SafetySubjectKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetySubjectKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetySubjectKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'library_recipe': return SafetySubjectKind.libraryRecipe;
        case r'suggestion': return SafetySubjectKind.suggestion;
        case r'substitution': return SafetySubjectKind.substitution;
        case r'taste_tweak_fix': return SafetySubjectKind.tasteTweakFix;
        case r'planned_meal': return SafetySubjectKind.plannedMeal;
        case r'family_recipe': return SafetySubjectKind.familyRecipe;
        case r'leftover_remake': return SafetySubjectKind.leftoverRemake;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetySubjectKindTypeTransformer? _instance;
}

