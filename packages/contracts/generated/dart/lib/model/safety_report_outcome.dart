//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


enum SafetyReportOutcome {
  confirmed._(r'confirmed'),
  rejected._(r'rejected'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetyReportOutcome._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetyReportOutcome] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetyReportOutcome? fromJson(dynamic value) => SafetyReportOutcomeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetyReportOutcome]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetyReportOutcome> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportOutcome>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportOutcome.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetyReportOutcome] to String,
/// and [decode] dynamic data back to [SafetyReportOutcome].
class SafetyReportOutcomeTypeTransformer {
  factory SafetyReportOutcomeTypeTransformer() => _instance ??= const SafetyReportOutcomeTypeTransformer._();

  const SafetyReportOutcomeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetyReportOutcome data) => data._value;

  /// Returns the instance of [SafetyReportOutcome] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetyReportOutcome? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetyReportOutcome) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'confirmed': return SafetyReportOutcome.confirmed;
        case r'rejected': return SafetyReportOutcome.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetyReportOutcomeTypeTransformer? _instance;
}

