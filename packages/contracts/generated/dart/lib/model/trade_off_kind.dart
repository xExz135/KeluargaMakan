//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-12 trade-off templates (`suggest.tradeoff.*`). A hard rule is never a trade-off. Clients show no line for an unknown value.
enum TradeOffKind {
  spiceSeparate._(r'spice_separate'),
  lessSantan._(r'less_santan'),
  notFried._(r'not_fried'),
  lessSalt._(r'less_salt'),
  lessSugar._(r'less_sugar'),
  dislikeSkipped._(r'dislike_skipped'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const TradeOffKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TradeOffKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TradeOffKind? fromJson(dynamic value) => TradeOffKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TradeOffKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TradeOffKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TradeOffKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TradeOffKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TradeOffKind] to String,
/// and [decode] dynamic data back to [TradeOffKind].
class TradeOffKindTypeTransformer {
  factory TradeOffKindTypeTransformer() => _instance ??= const TradeOffKindTypeTransformer._();

  const TradeOffKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(TradeOffKind data) => data._value;

  /// Returns the instance of [TradeOffKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TradeOffKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is TradeOffKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'spice_separate': return TradeOffKind.spiceSeparate;
        case r'less_santan': return TradeOffKind.lessSantan;
        case r'not_fried': return TradeOffKind.notFried;
        case r'less_salt': return TradeOffKind.lessSalt;
        case r'less_sugar': return TradeOffKind.lessSugar;
        case r'dislike_skipped': return TradeOffKind.dislikeSkipped;
        case r'other': return TradeOffKind.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TradeOffKindTypeTransformer? _instance;
}

