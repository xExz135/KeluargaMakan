//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// LIB-05 recipe halal status, derived by Cek Aman from its ingredient data, never from AI: `not_halal` when an ingredient or component is alcohol, pork or a non-halal animal; `check_label` when any item is uncertain or unverified (SAF-08). Not a per-member result. An unknown value hides the row; it is never shown as halal.
enum HalalStatus {
  halal._(r'halal'),
  notHalal._(r'not_halal'),
  checkLabel._(r'check_label'),
  ;

  /// Instantiate a new enum with the provided value.
  const HalalStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HalalStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HalalStatus? fromJson(dynamic value) => HalalStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HalalStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HalalStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HalalStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HalalStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HalalStatus] to String,
/// and [decode] dynamic data back to [HalalStatus].
class HalalStatusTypeTransformer {
  factory HalalStatusTypeTransformer() => _instance ??= const HalalStatusTypeTransformer._();

  const HalalStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(HalalStatus data) => data._value;

  /// Returns the instance of [HalalStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HalalStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is HalalStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'halal': return HalalStatus.halal;
        case r'not_halal': return HalalStatus.notHalal;
        case r'check_label': return HalalStatus.checkLabel;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HalalStatusTypeTransformer? _instance;
}

