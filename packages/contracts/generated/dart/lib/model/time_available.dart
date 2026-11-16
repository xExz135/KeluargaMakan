//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// SUG-02 time available, in minutes. `over_60` has no upper limit.
enum TimeAvailable {
  upTo15._(r'up_to_15'),
  upTo30._(r'up_to_30'),
  upTo60._(r'up_to_60'),
  over60._(r'over_60'),
  ;

  /// Instantiate a new enum with the provided value.
  const TimeAvailable._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TimeAvailable] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TimeAvailable? fromJson(dynamic value) => TimeAvailableTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TimeAvailable]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TimeAvailable> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TimeAvailable>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TimeAvailable.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TimeAvailable] to String,
/// and [decode] dynamic data back to [TimeAvailable].
class TimeAvailableTypeTransformer {
  factory TimeAvailableTypeTransformer() => _instance ??= const TimeAvailableTypeTransformer._();

  const TimeAvailableTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(TimeAvailable data) => data._value;

  /// Returns the instance of [TimeAvailable] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TimeAvailable? decode(dynamic data, {bool allowNull = true}) {
    if (data is TimeAvailable) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'up_to_15': return TimeAvailable.upTo15;
        case r'up_to_30': return TimeAvailable.upTo30;
        case r'up_to_60': return TimeAvailable.upTo60;
        case r'over_60': return TimeAvailable.over60;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TimeAvailableTypeTransformer? _instance;
}

