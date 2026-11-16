//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// SUG-03. V1 serves `indonesian` only; a request for another cuisine answers 400 until V3 adds those collections (LIB-10).
enum Cuisine {
  indonesian._(r'indonesian'),
  japanese._(r'japanese'),
  chinese._(r'chinese'),
  fusion._(r'fusion'),
  ;

  /// Instantiate a new enum with the provided value.
  const Cuisine._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [Cuisine] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static Cuisine? fromJson(dynamic value) => CuisineTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [Cuisine]
  /// that were successfully decoded from the passed [JSON][json].
  static List<Cuisine> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Cuisine>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Cuisine.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Cuisine] to String,
/// and [decode] dynamic data back to [Cuisine].
class CuisineTypeTransformer {
  factory CuisineTypeTransformer() => _instance ??= const CuisineTypeTransformer._();

  const CuisineTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(Cuisine data) => data._value;

  /// Returns the instance of [Cuisine] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Cuisine? decode(dynamic data, {bool allowNull = true}) {
    if (data is Cuisine) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'indonesian': return Cuisine.indonesian;
        case r'japanese': return Cuisine.japanese;
        case r'chinese': return Cuisine.chinese;
        case r'fusion': return Cuisine.fusion;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CuisineTypeTransformer? _instance;
}

