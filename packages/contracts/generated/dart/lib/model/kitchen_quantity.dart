//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// KIT-09 optional amount.
enum KitchenQuantity {
  aLittle._(r'a_little'),
  some._(r'some'),
  plenty._(r'plenty'),
  ;

  /// Instantiate a new enum with the provided value.
  const KitchenQuantity._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [KitchenQuantity] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static KitchenQuantity? fromJson(dynamic value) => KitchenQuantityTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [KitchenQuantity]
  /// that were successfully decoded from the passed [JSON][json].
  static List<KitchenQuantity> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenQuantity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenQuantity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KitchenQuantity] to String,
/// and [decode] dynamic data back to [KitchenQuantity].
class KitchenQuantityTypeTransformer {
  factory KitchenQuantityTypeTransformer() => _instance ??= const KitchenQuantityTypeTransformer._();

  const KitchenQuantityTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(KitchenQuantity data) => data._value;

  /// Returns the instance of [KitchenQuantity] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KitchenQuantity? decode(dynamic data, {bool allowNull = true}) {
    if (data is KitchenQuantity) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'a_little': return KitchenQuantity.aLittle;
        case r'some': return KitchenQuantity.some;
        case r'plenty': return KitchenQuantity.plenty;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static KitchenQuantityTypeTransformer? _instance;
}

