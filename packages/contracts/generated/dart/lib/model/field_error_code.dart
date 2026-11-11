//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


enum FieldErrorCode {
  required_._(r'required'),
  invalidType._(r'invalid_type'),
  invalidFormat._(r'invalid_format'),
  invalidValue._(r'invalid_value'),
  tooShort._(r'too_short'),
  tooLong._(r'too_long'),
  tooManyItems._(r'too_many_items'),
  duplicate._(r'duplicate'),
  notAllowed._(r'not_allowed'),
  ;

  /// Instantiate a new enum with the provided value.
  const FieldErrorCode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [FieldErrorCode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static FieldErrorCode? fromJson(dynamic value) => FieldErrorCodeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [FieldErrorCode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<FieldErrorCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FieldErrorCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FieldErrorCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FieldErrorCode] to String,
/// and [decode] dynamic data back to [FieldErrorCode].
class FieldErrorCodeTypeTransformer {
  factory FieldErrorCodeTypeTransformer() => _instance ??= const FieldErrorCodeTypeTransformer._();

  const FieldErrorCodeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(FieldErrorCode data) => data._value;

  /// Returns the instance of [FieldErrorCode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FieldErrorCode? decode(dynamic data, {bool allowNull = true}) {
    if (data is FieldErrorCode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'required': return FieldErrorCode.required_;
        case r'invalid_type': return FieldErrorCode.invalidType;
        case r'invalid_format': return FieldErrorCode.invalidFormat;
        case r'invalid_value': return FieldErrorCode.invalidValue;
        case r'too_short': return FieldErrorCode.tooShort;
        case r'too_long': return FieldErrorCode.tooLong;
        case r'too_many_items': return FieldErrorCode.tooManyItems;
        case r'duplicate': return FieldErrorCode.duplicate;
        case r'not_allowed': return FieldErrorCode.notAllowed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static FieldErrorCodeTypeTransformer? _instance;
}

