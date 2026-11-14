//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class PhotoSession {
  /// Returns a new [PhotoSession] instance.
  PhotoSession({
    required this.id,
    required this.status,
    required this.photoCount,
    required this.maxPhotos,
    required this.failureReason,
    required this.result,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final PhotoSessionStatus status;

  /// Minimum value: 0
  final int photoCount;

  /// Photos allowed per session, from configuration (REC-01, 5 target).
  ///
  /// Minimum value: 1
  final int maxPhotos;

  final RecognitionFailureReason? failureReason;

  /// Set when `status` is `ready`.
  final RecognitionResult? result;

  final DateTime createdAt;

  /// When an unconfirmed result is dropped (configuration, QUESTIONS
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PhotoSession &&
    other.id == id &&
    other.status == status &&
    other.photoCount == photoCount &&
    other.maxPhotos == maxPhotos &&
    other.failureReason == failureReason &&
    other.result == result &&
    other.createdAt == createdAt &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (photoCount.hashCode) +
    (maxPhotos.hashCode) +
    (failureReason == null ? 0 : failureReason!.hashCode) +
    (result == null ? 0 : result!.hashCode) +
    (createdAt.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'PhotoSession[id=$id, status=$status, photoCount=$photoCount, maxPhotos=$maxPhotos, failureReason=$failureReason, result=$result, createdAt=$createdAt, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
      json[r'photoCount'] = this.photoCount;
      json[r'maxPhotos'] = this.maxPhotos;
    if (this.failureReason != null) {
      json[r'failureReason'] = this.failureReason;
    } else {
      json[r'failureReason'] = null;
    }
    if (this.result != null) {
      json[r'result'] = this.result;
    } else {
      json[r'result'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [PhotoSession] and returns a new one where some of the
  /// properties have changed.
  PhotoSession copyWith({
    String? id,
    PhotoSessionStatus? status,
    int? photoCount,
    int? maxPhotos,
    RecognitionFailureReason? failureReason,
    bool failureReasonSetToNull = false,
    RecognitionResult? result,
    bool resultSetToNull = false,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) => PhotoSession(
    id: id ?? this.id,
    status: status ?? this.status,
    photoCount: photoCount ?? this.photoCount,
    maxPhotos: maxPhotos ?? this.maxPhotos,
    failureReason: failureReasonSetToNull ? null : failureReason ?? this.failureReason,
    result: resultSetToNull ? null : result ?? this.result,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  /// Returns a new [PhotoSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PhotoSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "PhotoSession[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "PhotoSession[id]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "PhotoSession[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "PhotoSession[status]" has a null value in JSON.');
        assert(json.containsKey(r'photoCount'), 'Required key "PhotoSession[photoCount]" is missing from JSON.');
        assert(json[r'photoCount'] != null, 'Required key "PhotoSession[photoCount]" has a null value in JSON.');
        assert(json.containsKey(r'maxPhotos'), 'Required key "PhotoSession[maxPhotos]" is missing from JSON.');
        assert(json[r'maxPhotos'] != null, 'Required key "PhotoSession[maxPhotos]" has a null value in JSON.');
        assert(json.containsKey(r'failureReason'), 'Required key "PhotoSession[failureReason]" is missing from JSON.');
        assert(json.containsKey(r'result'), 'Required key "PhotoSession[result]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "PhotoSession[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "PhotoSession[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'expiresAt'), 'Required key "PhotoSession[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null, 'Required key "PhotoSession[expiresAt]" has a null value in JSON.');
        return true;
      }());

      return PhotoSession(
        id: mapValueOfType<String>(json, r'id')!,
        status: PhotoSessionStatus.fromJson(json[r'status'])!,
        photoCount: mapValueOfType<int>(json, r'photoCount')!,
        maxPhotos: mapValueOfType<int>(json, r'maxPhotos')!,
        failureReason: RecognitionFailureReason.fromJson(json[r'failureReason']),
        result: RecognitionResult.fromJson(json[r'result']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
      );
    }
    return null;
  }

  static List<PhotoSession> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PhotoSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PhotoSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PhotoSession> mapFromJson(dynamic json) {
    final map = <String, PhotoSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PhotoSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PhotoSession-objects as value to a dart map
  static Map<String, List<PhotoSession>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PhotoSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PhotoSession.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'photoCount',
    'maxPhotos',
    'failureReason',
    'result',
    'createdAt',
    'expiresAt',
  };
}

