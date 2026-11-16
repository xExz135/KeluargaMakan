//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `estimate`: ranges from the reviewed calculation, always labeled \"perkiraan\" (estimate). `unavailable`: no reviewed values, shown as \"nutrition unavailable\" or not at all. V1 always sends `unavailable` and the app shows no nutrition (QUESTIONS #15). Clients treat an unknown value as `unavailable`.
enum NutritionStatus {
  estimate._(r'estimate'),
  unavailable._(r'unavailable'),
  ;

  /// Instantiate a new enum with the provided value.
  const NutritionStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NutritionStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NutritionStatus? fromJson(dynamic value) => NutritionStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NutritionStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NutritionStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NutritionStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NutritionStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NutritionStatus] to String,
/// and [decode] dynamic data back to [NutritionStatus].
class NutritionStatusTypeTransformer {
  factory NutritionStatusTypeTransformer() => _instance ??= const NutritionStatusTypeTransformer._();

  const NutritionStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NutritionStatus data) => data._value;

  /// Returns the instance of [NutritionStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NutritionStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is NutritionStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'estimate': return NutritionStatus.estimate;
        case r'unavailable': return NutritionStatus.unavailable;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NutritionStatusTypeTransformer? _instance;
}

