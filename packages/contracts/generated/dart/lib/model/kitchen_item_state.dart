//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// KIT-02: available (\"Ada\") or out (\"Habis\"). Clients show an unknown state as out, never as available.
enum KitchenItemState {
  available._(r'available'),
  out_._(r'out'),
  ;

  /// Instantiate a new enum with the provided value.
  const KitchenItemState._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [KitchenItemState] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static KitchenItemState? fromJson(dynamic value) => KitchenItemStateTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [KitchenItemState]
  /// that were successfully decoded from the passed [JSON][json].
  static List<KitchenItemState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenItemState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenItemState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KitchenItemState] to String,
/// and [decode] dynamic data back to [KitchenItemState].
class KitchenItemStateTypeTransformer {
  factory KitchenItemStateTypeTransformer() => _instance ??= const KitchenItemStateTypeTransformer._();

  const KitchenItemStateTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(KitchenItemState data) => data._value;

  /// Returns the instance of [KitchenItemState] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KitchenItemState? decode(dynamic data, {bool allowNull = true}) {
    if (data is KitchenItemState) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'available': return KitchenItemState.available;
        case r'out': return KitchenItemState.out_;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static KitchenItemStateTypeTransformer? _instance;
}

