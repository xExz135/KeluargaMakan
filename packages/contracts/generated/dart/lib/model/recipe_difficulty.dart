//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


enum RecipeDifficulty {
  easy._(r'easy'),
  medium._(r'medium'),
  hard._(r'hard'),
  ;

  /// Instantiate a new enum with the provided value.
  const RecipeDifficulty._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RecipeDifficulty] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RecipeDifficulty? fromJson(dynamic value) => RecipeDifficultyTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RecipeDifficulty]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RecipeDifficulty> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDifficulty>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDifficulty.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RecipeDifficulty] to String,
/// and [decode] dynamic data back to [RecipeDifficulty].
class RecipeDifficultyTypeTransformer {
  factory RecipeDifficultyTypeTransformer() => _instance ??= const RecipeDifficultyTypeTransformer._();

  const RecipeDifficultyTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RecipeDifficulty data) => data._value;

  /// Returns the instance of [RecipeDifficulty] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RecipeDifficulty? decode(dynamic data, {bool allowNull = true}) {
    if (data is RecipeDifficulty) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'easy': return RecipeDifficulty.easy;
        case r'medium': return RecipeDifficulty.medium;
        case r'hard': return RecipeDifficulty.hard;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RecipeDifficultyTypeTransformer? _instance;
}

