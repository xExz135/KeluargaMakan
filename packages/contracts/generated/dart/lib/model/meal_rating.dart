//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-13 \"Semua suka?\": Ya, suka · Campur · Kurang suka.
enum MealRating {
  yes._(r'yes'),
  mixed._(r'mixed'),
  no._(r'no'),
  ;

  /// Instantiate a new enum with the provided value.
  const MealRating._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MealRating] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MealRating? fromJson(dynamic value) => MealRatingTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MealRating]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MealRating> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MealRating>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MealRating.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MealRating] to String,
/// and [decode] dynamic data back to [MealRating].
class MealRatingTypeTransformer {
  factory MealRatingTypeTransformer() => _instance ??= const MealRatingTypeTransformer._();

  const MealRatingTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MealRating data) => data._value;

  /// Returns the instance of [MealRating] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MealRating? decode(dynamic data, {bool allowNull = true}) {
    if (data is MealRating) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'yes': return MealRating.yes;
        case r'mixed': return MealRating.mixed;
        case r'no': return MealRating.no;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MealRatingTypeTransformer? _instance;
}

