//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Problem {
  /// Returns a new [Problem] instance.
  Problem({
    required this.type,
    required this.title,
    required this.status,
    required this.code,
    this.detail = const Optional.absent(),
    required this.requestId,
    this.retryAfterSeconds = const Optional.absent(),
    this.errors = const Optional.present(const []),
  });

  /// Problem type URI, `urn:keluargamakan:problem:<code>`.
  final String type;

  final String title;

  /// Minimum value: 400
  /// Maximum value: 599
  final int status;

  final ErrorCode code;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> detail;

  /// Correlation ID to quote in support requests.
  final String requestId;

  /// Present on 429 and on 503 when a retry time is known.
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> retryAfterSeconds;

  /// Field errors for `validation_failed`.
  final Optional<List<FieldError>?> errors;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Problem &&
    other.type == type &&
    other.title == title &&
    other.status == status &&
    other.code == code &&
    other.detail == detail &&
    other.requestId == requestId &&
    other.retryAfterSeconds == retryAfterSeconds &&
    _deepEquality.equals(other.errors, errors);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (title.hashCode) +
    (status.hashCode) +
    (code.hashCode) +
    (detail == null ? 0 : detail!.hashCode) +
    (requestId.hashCode) +
    (retryAfterSeconds == null ? 0 : retryAfterSeconds!.hashCode) +
    (errors.hashCode);

  @override
  String toString() => 'Problem[type=$type, title=$title, status=$status, code=$code, detail=$detail, requestId=$requestId, retryAfterSeconds=$retryAfterSeconds, errors=$errors]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
      json[r'title'] = this.title;
      json[r'status'] = this.status;
      json[r'code'] = this.code;
    if (this.detail.isPresent) {
      final value = this.detail.value;
      json[r'detail'] = value;
    }
      json[r'requestId'] = this.requestId;
    if (this.retryAfterSeconds.isPresent) {
      final value = this.retryAfterSeconds.value;
      json[r'retryAfterSeconds'] = value;
    }
    if (this.errors.isPresent) {
      final value = this.errors.value;
      json[r'errors'] = value;
    }
    return json;
  }

  /// Clones this instance of [Problem] and returns a new one where some of the
  /// properties have changed.
  Problem copyWith({
    String? type,
    String? title,
    int? status,
    ErrorCode? code,
    Optional<String?>? detail,
    String? requestId,
    Optional<int?>? retryAfterSeconds,
    Optional<List<FieldError>?>? errors,
  }) => Problem(
    type: type ?? this.type,
    title: title ?? this.title,
    status: status ?? this.status,
    code: code ?? this.code,
    detail: detail ?? this.detail,
    requestId: requestId ?? this.requestId,
    retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
    errors: errors ?? this.errors,
  );

  /// Returns a new [Problem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Problem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "Problem[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "Problem[type]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "Problem[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "Problem[title]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Problem[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Problem[status]" has a null value in JSON.');
        assert(json.containsKey(r'code'), 'Required key "Problem[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "Problem[code]" has a null value in JSON.');
        assert(json.containsKey(r'requestId'), 'Required key "Problem[requestId]" is missing from JSON.');
        assert(json[r'requestId'] != null, 'Required key "Problem[requestId]" has a null value in JSON.');
        return true;
      }());

      return Problem(
        type: mapValueOfType<String>(json, r'type')!,
        title: mapValueOfType<String>(json, r'title')!,
        status: mapValueOfType<int>(json, r'status')!,
        code: ErrorCode.fromJson(json[r'code'])!,
        detail: json.containsKey(r'detail') ? Optional.present(mapValueOfType<String>(json, r'detail')) : const Optional.absent(),
        requestId: mapValueOfType<String>(json, r'requestId')!,
        retryAfterSeconds: json.containsKey(r'retryAfterSeconds') ? Optional.present(json[r'retryAfterSeconds'] == null ? null : int.parse('${json[r'retryAfterSeconds']}')) : const Optional.absent(),
        errors: json.containsKey(r'errors') ? Optional.present(FieldError.listFromJson(json[r'errors'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<Problem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Problem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Problem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Problem> mapFromJson(dynamic json) {
    final map = <String, Problem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Problem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Problem-objects as value to a dart map
  static Map<String, List<Problem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Problem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Problem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'title',
    'status',
    'code',
    'requestId',
  };
}

