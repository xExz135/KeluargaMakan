//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// AI-08: `available`; `off` (the household has not turned AI features on, SET-09); `unavailable` (down, out of quota or too slow, so only library recipes and content-team options are used). Never affects a safety result. Clients treat an unknown value as `unavailable`.
enum AiAvailability {
  available._(r'available'),
  off._(r'off'),
  unavailable._(r'unavailable'),
  ;

  /// Instantiate a new enum with the provided value.
  const AiAvailability._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AiAvailability] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AiAvailability? fromJson(dynamic value) => AiAvailabilityTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AiAvailability]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AiAvailability> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AiAvailability>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AiAvailability.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AiAvailability] to String,
/// and [decode] dynamic data back to [AiAvailability].
class AiAvailabilityTypeTransformer {
  factory AiAvailabilityTypeTransformer() => _instance ??= const AiAvailabilityTypeTransformer._();

  const AiAvailabilityTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AiAvailability data) => data._value;

  /// Returns the instance of [AiAvailability] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AiAvailability? decode(dynamic data, {bool allowNull = true}) {
    if (data is AiAvailability) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'available': return AiAvailability.available;
        case r'off': return AiAvailability.off;
        case r'unavailable': return AiAvailability.unavailable;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AiAvailabilityTypeTransformer? _instance;
}

