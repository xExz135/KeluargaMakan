//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// SUG-02 meal types. `sahur` and `buka` are plain meal types in V1 with no Ramadan logic (QUESTIONS #25).
enum MealType {
  breakfast._(r'breakfast'),
  lunch._(r'lunch'),
  dinner._(r'dinner'),
  snack._(r'snack'),
  sahur._(r'sahur'),
  buka._(r'buka'),
  ;

  /// Instantiate a new enum with the provided value.
  const MealType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MealType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MealType? fromJson(dynamic value) => MealTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MealType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MealType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MealType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MealType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MealType] to String,
/// and [decode] dynamic data back to [MealType].
class MealTypeTypeTransformer {
  factory MealTypeTypeTransformer() => _instance ??= const MealTypeTypeTransformer._();

  const MealTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MealType data) => data._value;

  /// Returns the instance of [MealType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MealType? decode(dynamic data, {bool allowNull = true}) {
    if (data is MealType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'breakfast': return MealType.breakfast;
        case r'lunch': return MealType.lunch;
        case r'dinner': return MealType.dinner;
        case r'snack': return MealType.snack;
        case r'sahur': return MealType.sahur;
        case r'buka': return MealType.buka;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MealTypeTypeTransformer? _instance;
}

