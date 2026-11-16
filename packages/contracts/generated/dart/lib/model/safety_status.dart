//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// SAF-04 per-member result from Cek Aman, the only component that assigns one (SAF-01). Clients render it and never compute, upgrade or default it. An unknown value means no result: the item is hidden, never shown as safe.
enum SafetyStatus {
  safe._(r'safe'),
  notSafe._(r'not_safe'),
  checkLabel._(r'check_label'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetyStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetyStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetyStatus? fromJson(dynamic value) => SafetyStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetyStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetyStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetyStatus] to String,
/// and [decode] dynamic data back to [SafetyStatus].
class SafetyStatusTypeTransformer {
  factory SafetyStatusTypeTransformer() => _instance ??= const SafetyStatusTypeTransformer._();

  const SafetyStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetyStatus data) => data._value;

  /// Returns the instance of [SafetyStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetyStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetyStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'safe': return SafetyStatus.safe;
        case r'not_safe': return SafetyStatus.notSafe;
        case r'check_label': return SafetyStatus.checkLabel;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetyStatusTypeTransformer? _instance;
}

