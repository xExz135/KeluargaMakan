//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


enum MappingConfirmer {
  contentTeam._(r'content_team'),
  manager._(r'manager'),
  ;

  /// Instantiate a new enum with the provided value.
  const MappingConfirmer._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MappingConfirmer] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MappingConfirmer? fromJson(dynamic value) => MappingConfirmerTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MappingConfirmer]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MappingConfirmer> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MappingConfirmer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MappingConfirmer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MappingConfirmer] to String,
/// and [decode] dynamic data back to [MappingConfirmer].
class MappingConfirmerTypeTransformer {
  factory MappingConfirmerTypeTransformer() => _instance ??= const MappingConfirmerTypeTransformer._();

  const MappingConfirmerTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MappingConfirmer data) => data._value;

  /// Returns the instance of [MappingConfirmer] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MappingConfirmer? decode(dynamic data, {bool allowNull = true}) {
    if (data is MappingConfirmer) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'content_team': return MappingConfirmer.contentTeam;
        case r'manager': return MappingConfirmer.manager;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MappingConfirmerTypeTransformer? _instance;
}

