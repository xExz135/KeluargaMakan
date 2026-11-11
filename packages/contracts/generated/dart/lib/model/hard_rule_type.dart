//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-03 hard rule types, matching the Cek Aman vocabulary.
enum HardRuleType {
  allergy._(r'allergy'),
  halal._(r'halal'),
  vegetarian._(r'vegetarian'),
  vegan._(r'vegan'),
  medicalExclusion._(r'medical_exclusion'),
  freeText._(r'free_text'),
  ;

  /// Instantiate a new enum with the provided value.
  const HardRuleType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HardRuleType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HardRuleType? fromJson(dynamic value) => HardRuleTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HardRuleType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HardRuleType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HardRuleType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HardRuleType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HardRuleType] to String,
/// and [decode] dynamic data back to [HardRuleType].
class HardRuleTypeTypeTransformer {
  factory HardRuleTypeTypeTransformer() => _instance ??= const HardRuleTypeTypeTransformer._();

  const HardRuleTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(HardRuleType data) => data._value;

  /// Returns the instance of [HardRuleType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HardRuleType? decode(dynamic data, {bool allowNull = true}) {
    if (data is HardRuleType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'allergy': return HardRuleType.allergy;
        case r'halal': return HardRuleType.halal;
        case r'vegetarian': return HardRuleType.vegetarian;
        case r'vegan': return HardRuleType.vegan;
        case r'medical_exclusion': return HardRuleType.medicalExclusion;
        case r'free_text': return HardRuleType.freeText;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HardRuleTypeTypeTransformer? _instance;
}

