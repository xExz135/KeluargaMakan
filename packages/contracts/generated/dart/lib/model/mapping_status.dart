//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-08 mapping state. Only `mapped` is evaluated as a mapping; `proposed` and `unmapped` make Cek Aman return \"Check the label\" for related recipes (SAF-09).
enum MappingStatus {
  mapped._(r'mapped'),
  proposed._(r'proposed'),
  unmapped._(r'unmapped'),
  ;

  /// Instantiate a new enum with the provided value.
  const MappingStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MappingStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MappingStatus? fromJson(dynamic value) => MappingStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MappingStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MappingStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MappingStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MappingStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MappingStatus] to String,
/// and [decode] dynamic data back to [MappingStatus].
class MappingStatusTypeTransformer {
  factory MappingStatusTypeTransformer() => _instance ??= const MappingStatusTypeTransformer._();

  const MappingStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MappingStatus data) => data._value;

  /// Returns the instance of [MappingStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MappingStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is MappingStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'mapped': return MappingStatus.mapped;
        case r'proposed': return MappingStatus.proposed;
        case r'unmapped': return MappingStatus.unmapped;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MappingStatusTypeTransformer? _instance;
}

