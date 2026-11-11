//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Health-data consent state for the member's hard rules (QUESTIONS #36). Only `given` allows rules; for every other state there are no rules and clients show \"rules not saved\", never \"Safe\".
enum RulesConsentStatus {
  none._(r'none'),
  given._(r'given'),
  declined._(r'declined'),
  withdrawn._(r'withdrawn'),
  ;

  /// Instantiate a new enum with the provided value.
  const RulesConsentStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RulesConsentStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RulesConsentStatus? fromJson(dynamic value) => RulesConsentStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RulesConsentStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RulesConsentStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RulesConsentStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RulesConsentStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RulesConsentStatus] to String,
/// and [decode] dynamic data back to [RulesConsentStatus].
class RulesConsentStatusTypeTransformer {
  factory RulesConsentStatusTypeTransformer() => _instance ??= const RulesConsentStatusTypeTransformer._();

  const RulesConsentStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RulesConsentStatus data) => data._value;

  /// Returns the instance of [RulesConsentStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RulesConsentStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is RulesConsentStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'none': return RulesConsentStatus.none;
        case r'given': return RulesConsentStatus.given;
        case r'declined': return RulesConsentStatus.declined;
        case r'withdrawn': return RulesConsentStatus.withdrawn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RulesConsentStatusTypeTransformer? _instance;
}

