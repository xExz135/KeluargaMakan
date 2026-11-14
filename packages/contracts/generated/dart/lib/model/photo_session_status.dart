//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Confirm-and-Save session (REC-01 to REC-04). `collecting`: photos are being added; `processing`: they are being read; `ready`: a result waits for confirmation; `failed`: see `failureReason`; `confirmed` and `discarded`: closed by the user; `expired`: the result was not confirmed in time and was dropped. Clients treat an unknown status like `failed` and offer manual entry.
enum PhotoSessionStatus {
  collecting._(r'collecting'),
  processing._(r'processing'),
  ready._(r'ready'),
  failed._(r'failed'),
  confirmed._(r'confirmed'),
  discarded._(r'discarded'),
  expired._(r'expired'),
  ;

  /// Instantiate a new enum with the provided value.
  const PhotoSessionStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PhotoSessionStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PhotoSessionStatus? fromJson(dynamic value) => PhotoSessionStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PhotoSessionStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PhotoSessionStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PhotoSessionStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PhotoSessionStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PhotoSessionStatus] to String,
/// and [decode] dynamic data back to [PhotoSessionStatus].
class PhotoSessionStatusTypeTransformer {
  factory PhotoSessionStatusTypeTransformer() => _instance ??= const PhotoSessionStatusTypeTransformer._();

  const PhotoSessionStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(PhotoSessionStatus data) => data._value;

  /// Returns the instance of [PhotoSessionStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PhotoSessionStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is PhotoSessionStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'collecting': return PhotoSessionStatus.collecting;
        case r'processing': return PhotoSessionStatus.processing;
        case r'ready': return PhotoSessionStatus.ready;
        case r'failed': return PhotoSessionStatus.failed;
        case r'confirmed': return PhotoSessionStatus.confirmed;
        case r'discarded': return PhotoSessionStatus.discarded;
        case r'expired': return PhotoSessionStatus.expired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PhotoSessionStatusTypeTransformer? _instance;
}

