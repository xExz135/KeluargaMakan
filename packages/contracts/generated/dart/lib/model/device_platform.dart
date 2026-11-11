//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Android only (owner decision 2026-11-10).
enum DevicePlatform {
  android._(r'android'),
  ;

  /// Instantiate a new enum with the provided value.
  const DevicePlatform._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DevicePlatform] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DevicePlatform? fromJson(dynamic value) => DevicePlatformTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DevicePlatform]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DevicePlatform> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DevicePlatform>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DevicePlatform.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DevicePlatform] to String,
/// and [decode] dynamic data back to [DevicePlatform].
class DevicePlatformTypeTransformer {
  factory DevicePlatformTypeTransformer() => _instance ??= const DevicePlatformTypeTransformer._();

  const DevicePlatformTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(DevicePlatform data) => data._value;

  /// Returns the instance of [DevicePlatform] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DevicePlatform? decode(dynamic data, {bool allowNull = true}) {
    if (data is DevicePlatform) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'android': return DevicePlatform.android;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DevicePlatformTypeTransformer? _instance;
}

