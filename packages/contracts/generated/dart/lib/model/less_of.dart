//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// \"Kurangi\" preferences: less fried food, sugar, salt or santan (PRF-05).
enum LessOf {
  fried._(r'fried'),
  sugar._(r'sugar'),
  salt._(r'salt'),
  santan._(r'santan'),
  ;

  /// Instantiate a new enum with the provided value.
  const LessOf._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [LessOf] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static LessOf? fromJson(dynamic value) => LessOfTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [LessOf]
  /// that were successfully decoded from the passed [JSON][json].
  static List<LessOf> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LessOf>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LessOf.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LessOf] to String,
/// and [decode] dynamic data back to [LessOf].
class LessOfTypeTransformer {
  factory LessOfTypeTransformer() => _instance ??= const LessOfTypeTransformer._();

  const LessOfTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(LessOf data) => data._value;

  /// Returns the instance of [LessOf] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LessOf? decode(dynamic data, {bool allowNull = true}) {
    if (data is LessOf) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'fried': return LessOf.fried;
        case r'sugar': return LessOf.sugar;
        case r'salt': return LessOf.salt;
        case r'santan': return LessOf.santan;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static LessOfTypeTransformer? _instance;
}

