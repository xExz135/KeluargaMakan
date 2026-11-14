//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// REC-02. `high` and `medium` items start ticked; `low` items are asked as a question with likely options and nothing preselected (REC-03). Clients treat an unknown value like `low`.
enum RecognitionConfidence {
  high._(r'high'),
  medium._(r'medium'),
  low._(r'low'),
  ;

  /// Instantiate a new enum with the provided value.
  const RecognitionConfidence._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RecognitionConfidence] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RecognitionConfidence? fromJson(dynamic value) => RecognitionConfidenceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RecognitionConfidence]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RecognitionConfidence> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecognitionConfidence>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecognitionConfidence.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RecognitionConfidence] to String,
/// and [decode] dynamic data back to [RecognitionConfidence].
class RecognitionConfidenceTypeTransformer {
  factory RecognitionConfidenceTypeTransformer() => _instance ??= const RecognitionConfidenceTypeTransformer._();

  const RecognitionConfidenceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RecognitionConfidence data) => data._value;

  /// Returns the instance of [RecognitionConfidence] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RecognitionConfidence? decode(dynamic data, {bool allowNull = true}) {
    if (data is RecognitionConfidence) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'high': return RecognitionConfidence.high;
        case r'medium': return RecognitionConfidence.medium;
        case r'low': return RecognitionConfidence.low;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RecognitionConfidenceTypeTransformer? _instance;
}

