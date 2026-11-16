//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `separate_portion`: the member's portion is set aside before a step and some ingredient lines never go into it (SAF-11). A client that does not know the value shows Check the label for the member, never a bare Safe.
enum SafetyConditionKind {
  separatePortion._(r'separate_portion'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetyConditionKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetyConditionKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetyConditionKind? fromJson(dynamic value) => SafetyConditionKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetyConditionKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetyConditionKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyConditionKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyConditionKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetyConditionKind] to String,
/// and [decode] dynamic data back to [SafetyConditionKind].
class SafetyConditionKindTypeTransformer {
  factory SafetyConditionKindTypeTransformer() => _instance ??= const SafetyConditionKindTypeTransformer._();

  const SafetyConditionKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetyConditionKind data) => data._value;

  /// Returns the instance of [SafetyConditionKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetyConditionKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetyConditionKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'separate_portion': return SafetyConditionKind.separatePortion;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetyConditionKindTypeTransformer? _instance;
}

