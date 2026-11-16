//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// CKM-01: whether the household's saved kitchen has the ingredient (\"Ada\" or \"Belum ada\"). Clients treat an unknown value as `missing`.
enum KitchenAvailability {
  available._(r'available'),
  missing._(r'missing'),
  ;

  /// Instantiate a new enum with the provided value.
  const KitchenAvailability._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [KitchenAvailability] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static KitchenAvailability? fromJson(dynamic value) => KitchenAvailabilityTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [KitchenAvailability]
  /// that were successfully decoded from the passed [JSON][json].
  static List<KitchenAvailability> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenAvailability>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenAvailability.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KitchenAvailability] to String,
/// and [decode] dynamic data back to [KitchenAvailability].
class KitchenAvailabilityTypeTransformer {
  factory KitchenAvailabilityTypeTransformer() => _instance ??= const KitchenAvailabilityTypeTransformer._();

  const KitchenAvailabilityTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(KitchenAvailability data) => data._value;

  /// Returns the instance of [KitchenAvailability] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KitchenAvailability? decode(dynamic data, {bool allowNull = true}) {
    if (data is KitchenAvailability) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'available': return KitchenAvailability.available;
        case r'missing': return KitchenAvailability.missing;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static KitchenAvailabilityTypeTransformer? _instance;
}

