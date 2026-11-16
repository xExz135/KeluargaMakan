//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `contains` and `component` come with `not_safe`; the other kinds with `check_label`. The member's `status` always decides the badge.
enum SafetyReasonKind {
  contains._(r'contains'),
  component._(r'component'),
  unknown._(r'unknown'),
  brandUncertain._(r'brand_uncertain'),
  unmappedRule._(r'unmapped_rule'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetyReasonKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetyReasonKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetyReasonKind? fromJson(dynamic value) => SafetyReasonKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetyReasonKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetyReasonKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReasonKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReasonKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetyReasonKind] to String,
/// and [decode] dynamic data back to [SafetyReasonKind].
class SafetyReasonKindTypeTransformer {
  factory SafetyReasonKindTypeTransformer() => _instance ??= const SafetyReasonKindTypeTransformer._();

  const SafetyReasonKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetyReasonKind data) => data._value;

  /// Returns the instance of [SafetyReasonKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetyReasonKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetyReasonKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'contains': return SafetyReasonKind.contains;
        case r'component': return SafetyReasonKind.component;
        case r'unknown': return SafetyReasonKind.unknown;
        case r'brand_uncertain': return SafetyReasonKind.brandUncertain;
        case r'unmapped_rule': return SafetyReasonKind.unmappedRule;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetyReasonKindTypeTransformer? _instance;
}

