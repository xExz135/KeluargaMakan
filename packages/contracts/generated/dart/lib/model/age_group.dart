//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-01 age groups (DECISIONS 2026-11-10): infant 0–1, child 2–12, teen 13–17, adult 18–59, elderly 60+. Infant, child and teen are flagged as children (PRF-18).
enum AgeGroup {
  infant._(r'infant'),
  child._(r'child'),
  teen._(r'teen'),
  adult._(r'adult'),
  elderly._(r'elderly'),
  ;

  /// Instantiate a new enum with the provided value.
  const AgeGroup._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AgeGroup] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AgeGroup? fromJson(dynamic value) => AgeGroupTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AgeGroup]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AgeGroup> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AgeGroup>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AgeGroup.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AgeGroup] to String,
/// and [decode] dynamic data back to [AgeGroup].
class AgeGroupTypeTransformer {
  factory AgeGroupTypeTransformer() => _instance ??= const AgeGroupTypeTransformer._();

  const AgeGroupTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AgeGroup data) => data._value;

  /// Returns the instance of [AgeGroup] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AgeGroup? decode(dynamic data, {bool allowNull = true}) {
    if (data is AgeGroup) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'infant': return AgeGroup.infant;
        case r'child': return AgeGroup.child;
        case r'teen': return AgeGroup.teen;
        case r'adult': return AgeGroup.adult;
        case r'elderly': return AgeGroup.elderly;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AgeGroupTypeTransformer? _instance;
}

