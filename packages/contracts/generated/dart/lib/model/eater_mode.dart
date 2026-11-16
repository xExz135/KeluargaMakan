//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-09: `only_me` is the manager's own profile, `whole_family` every profile in the household, `selected` the profiles in `memberIds`.
enum EaterMode {
  onlyMe._(r'only_me'),
  wholeFamily._(r'whole_family'),
  selected._(r'selected'),
  ;

  /// Instantiate a new enum with the provided value.
  const EaterMode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [EaterMode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static EaterMode? fromJson(dynamic value) => EaterModeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [EaterMode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<EaterMode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EaterMode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EaterMode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [EaterMode] to String,
/// and [decode] dynamic data back to [EaterMode].
class EaterModeTypeTransformer {
  factory EaterModeTypeTransformer() => _instance ??= const EaterModeTypeTransformer._();

  const EaterModeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(EaterMode data) => data._value;

  /// Returns the instance of [EaterMode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  EaterMode? decode(dynamic data, {bool allowNull = true}) {
    if (data is EaterMode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'only_me': return EaterMode.onlyMe;
        case r'whole_family': return EaterMode.wholeFamily;
        case r'selected': return EaterMode.selected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static EaterModeTypeTransformer? _instance;
}

