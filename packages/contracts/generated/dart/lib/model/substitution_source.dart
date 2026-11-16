//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `content_team`: defined and reviewed by the content team (QUESTIONS #21). `ai`: proposed by the AI service and then checked by Cek Aman like any other option (AI-01); never a safety verdict.
enum SubstitutionSource {
  contentTeam._(r'content_team'),
  ai._(r'ai'),
  ;

  /// Instantiate a new enum with the provided value.
  const SubstitutionSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SubstitutionSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SubstitutionSource? fromJson(dynamic value) => SubstitutionSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SubstitutionSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SubstitutionSource> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubstitutionSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubstitutionSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SubstitutionSource] to String,
/// and [decode] dynamic data back to [SubstitutionSource].
class SubstitutionSourceTypeTransformer {
  factory SubstitutionSourceTypeTransformer() => _instance ??= const SubstitutionSourceTypeTransformer._();

  const SubstitutionSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SubstitutionSource data) => data._value;

  /// Returns the instance of [SubstitutionSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SubstitutionSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is SubstitutionSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'content_team': return SubstitutionSource.contentTeam;
        case r'ai': return SubstitutionSource.ai;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SubstitutionSourceTypeTransformer? _instance;
}

