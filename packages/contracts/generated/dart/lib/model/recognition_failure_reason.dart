//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `ai_not_enabled`: the household has not turned on AI features (SET-09); `ai_unavailable`: the recognizer is down, out of quota or too slow (INT-06 fallback: manual entry); `photos_unreadable`: the photos could not be read; `processing_failed`: any other failure.
enum RecognitionFailureReason {
  aiNotEnabled._(r'ai_not_enabled'),
  aiUnavailable._(r'ai_unavailable'),
  photosUnreadable._(r'photos_unreadable'),
  processingFailed._(r'processing_failed'),
  ;

  /// Instantiate a new enum with the provided value.
  const RecognitionFailureReason._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RecognitionFailureReason] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RecognitionFailureReason? fromJson(dynamic value) => RecognitionFailureReasonTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RecognitionFailureReason]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RecognitionFailureReason> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecognitionFailureReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecognitionFailureReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RecognitionFailureReason] to String,
/// and [decode] dynamic data back to [RecognitionFailureReason].
class RecognitionFailureReasonTypeTransformer {
  factory RecognitionFailureReasonTypeTransformer() => _instance ??= const RecognitionFailureReasonTypeTransformer._();

  const RecognitionFailureReasonTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RecognitionFailureReason data) => data._value;

  /// Returns the instance of [RecognitionFailureReason] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RecognitionFailureReason? decode(dynamic data, {bool allowNull = true}) {
    if (data is RecognitionFailureReason) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ai_not_enabled': return RecognitionFailureReason.aiNotEnabled;
        case r'ai_unavailable': return RecognitionFailureReason.aiUnavailable;
        case r'photos_unreadable': return RecognitionFailureReason.photosUnreadable;
        case r'processing_failed': return RecognitionFailureReason.processingFailed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RecognitionFailureReasonTypeTransformer? _instance;
}

