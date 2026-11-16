//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// NUT-04 nutrients.
enum NutrientCode {
  energy._(r'energy'),
  protein._(r'protein'),
  carbohydrate._(r'carbohydrate'),
  fat._(r'fat'),
  saturatedFat._(r'saturated_fat'),
  fiber._(r'fiber'),
  sugar._(r'sugar'),
  sodium._(r'sodium'),
  ;

  /// Instantiate a new enum with the provided value.
  const NutrientCode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NutrientCode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NutrientCode? fromJson(dynamic value) => NutrientCodeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NutrientCode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NutrientCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NutrientCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NutrientCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NutrientCode] to String,
/// and [decode] dynamic data back to [NutrientCode].
class NutrientCodeTypeTransformer {
  factory NutrientCodeTypeTransformer() => _instance ??= const NutrientCodeTypeTransformer._();

  const NutrientCodeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NutrientCode data) => data._value;

  /// Returns the instance of [NutrientCode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NutrientCode? decode(dynamic data, {bool allowNull = true}) {
    if (data is NutrientCode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'energy': return NutrientCode.energy;
        case r'protein': return NutrientCode.protein;
        case r'carbohydrate': return NutrientCode.carbohydrate;
        case r'fat': return NutrientCode.fat;
        case r'saturated_fat': return NutrientCode.saturatedFat;
        case r'fiber': return NutrientCode.fiber;
        case r'sugar': return NutrientCode.sugar;
        case r'sodium': return NutrientCode.sodium;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NutrientCodeTypeTransformer? _instance;
}

