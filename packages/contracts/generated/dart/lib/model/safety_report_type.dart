//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// What the user says is wrong (`report.type.*`).
enum SafetyReportType {
  markedSafeWrong._(r'marked_safe_wrong'),
  markedNotSafeWrong._(r'marked_not_safe_wrong'),
  checkLabelWrong._(r'check_label_wrong'),
  wrongIngredient._(r'wrong_ingredient'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const SafetyReportType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SafetyReportType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SafetyReportType? fromJson(dynamic value) => SafetyReportTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SafetyReportType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SafetyReportType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SafetyReportType] to String,
/// and [decode] dynamic data back to [SafetyReportType].
class SafetyReportTypeTypeTransformer {
  factory SafetyReportTypeTypeTransformer() => _instance ??= const SafetyReportTypeTypeTransformer._();

  const SafetyReportTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SafetyReportType data) => data._value;

  /// Returns the instance of [SafetyReportType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SafetyReportType? decode(dynamic data, {bool allowNull = true}) {
    if (data is SafetyReportType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'marked_safe_wrong': return SafetyReportType.markedSafeWrong;
        case r'marked_not_safe_wrong': return SafetyReportType.markedNotSafeWrong;
        case r'check_label_wrong': return SafetyReportType.checkLabelWrong;
        case r'wrong_ingredient': return SafetyReportType.wrongIngredient;
        case r'other': return SafetyReportType.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SafetyReportTypeTypeTransformer? _instance;
}

