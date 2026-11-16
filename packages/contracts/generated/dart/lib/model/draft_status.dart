//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// `draft` (being edited) → `in_review` (sent for the second person) → `approved` (reference data waiting for a release) or `published` (live) · `rejected` (back to the author) · `discarded`. The admin tool treats an unknown value as not editable and not approvable.
enum DraftStatus {
  draft._(r'draft'),
  inReview._(r'in_review'),
  approved._(r'approved'),
  rejected._(r'rejected'),
  published._(r'published'),
  discarded._(r'discarded'),
  ;

  /// Instantiate a new enum with the provided value.
  const DraftStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DraftStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DraftStatus? fromJson(dynamic value) => DraftStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DraftStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DraftStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DraftStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DraftStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DraftStatus] to String,
/// and [decode] dynamic data back to [DraftStatus].
class DraftStatusTypeTransformer {
  factory DraftStatusTypeTransformer() => _instance ??= const DraftStatusTypeTransformer._();

  const DraftStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(DraftStatus data) => data._value;

  /// Returns the instance of [DraftStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DraftStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is DraftStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'draft': return DraftStatus.draft;
        case r'in_review': return DraftStatus.inReview;
        case r'approved': return DraftStatus.approved;
        case r'rejected': return DraftStatus.rejected;
        case r'published': return DraftStatus.published;
        case r'discarded': return DraftStatus.discarded;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DraftStatusTypeTransformer? _instance;
}

