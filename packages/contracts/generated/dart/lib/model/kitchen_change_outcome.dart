//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `applied`: the change is the latest for its ingredient (also for a repeat of an applied change). `superseded`: a later change to the ingredient was already stored; the stored item is in `items`. `rejected`: the change cannot be applied (see `errorCode`); nothing changed.
enum KitchenChangeOutcome {
  applied._(r'applied'),
  superseded._(r'superseded'),
  rejected._(r'rejected'),
  ;

  /// Instantiate a new enum with the provided value.
  const KitchenChangeOutcome._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [KitchenChangeOutcome] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static KitchenChangeOutcome? fromJson(dynamic value) => KitchenChangeOutcomeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [KitchenChangeOutcome]
  /// that were successfully decoded from the passed [JSON][json].
  static List<KitchenChangeOutcome> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenChangeOutcome>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenChangeOutcome.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KitchenChangeOutcome] to String,
/// and [decode] dynamic data back to [KitchenChangeOutcome].
class KitchenChangeOutcomeTypeTransformer {
  factory KitchenChangeOutcomeTypeTransformer() => _instance ??= const KitchenChangeOutcomeTypeTransformer._();

  const KitchenChangeOutcomeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(KitchenChangeOutcome data) => data._value;

  /// Returns the instance of [KitchenChangeOutcome] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KitchenChangeOutcome? decode(dynamic data, {bool allowNull = true}) {
    if (data is KitchenChangeOutcome) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'applied': return KitchenChangeOutcome.applied;
        case r'superseded': return KitchenChangeOutcome.superseded;
        case r'rejected': return KitchenChangeOutcome.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static KitchenChangeOutcomeTypeTransformer? _instance;
}

