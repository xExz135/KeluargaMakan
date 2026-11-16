//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeDraft {
  /// Returns a new [RecipeDraft] instance.
  RecipeDraft({
    required this.id,
    required this.recipeId,
    required this.baseVersion,
    required this.status,
    required this.revision,
    required this.content,
    this.validationErrors = const [],
    required this.testRecord,
    required this.authorStaffId,
    required this.createdAt,
    required this.updatedAt,
    required this.submittedAt,
    required this.review,
    required this.publishedVersion,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// The recipe this draft becomes or changes.
  final String recipeId;

  /// The published version a new version starts from; null for a new recipe.
  ///
  /// Minimum value: 1
  final int? baseVersion;

  final DraftStatus status;

  /// Minimum value: 1
  final int revision;

  final AdminRecipeContent content;

  final List<FieldError> validationErrors;

  /// Null until recorded, and cleared when the content changes.
  final AdminRecipeTestRecord? testRecord;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String authorStaffId;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? submittedAt;

  final DraftReview? review;

  /// Minimum value: 1
  final int? publishedVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeDraft &&
    other.id == id &&
    other.recipeId == recipeId &&
    other.baseVersion == baseVersion &&
    other.status == status &&
    other.revision == revision &&
    other.content == content &&
    _deepEquality.equals(other.validationErrors, validationErrors) &&
    other.testRecord == testRecord &&
    other.authorStaffId == authorStaffId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.submittedAt == submittedAt &&
    other.review == review &&
    other.publishedVersion == publishedVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (recipeId.hashCode) +
    (baseVersion == null ? 0 : baseVersion!.hashCode) +
    (status.hashCode) +
    (revision.hashCode) +
    (content.hashCode) +
    (validationErrors.hashCode) +
    (testRecord == null ? 0 : testRecord!.hashCode) +
    (authorStaffId.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode) +
    (review == null ? 0 : review!.hashCode) +
    (publishedVersion == null ? 0 : publishedVersion!.hashCode);

  @override
  String toString() => 'RecipeDraft[id=$id, recipeId=$recipeId, baseVersion=$baseVersion, status=$status, revision=$revision, content=$content, validationErrors=$validationErrors, testRecord=$testRecord, authorStaffId=$authorStaffId, createdAt=$createdAt, updatedAt=$updatedAt, submittedAt=$submittedAt, review=$review, publishedVersion=$publishedVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'recipeId'] = this.recipeId;
    if (this.baseVersion != null) {
      json[r'baseVersion'] = this.baseVersion;
    } else {
      json[r'baseVersion'] = null;
    }
      json[r'status'] = this.status;
      json[r'revision'] = this.revision;
      json[r'content'] = this.content;
      json[r'validationErrors'] = this.validationErrors;
    if (this.testRecord != null) {
      json[r'testRecord'] = this.testRecord;
    } else {
      json[r'testRecord'] = null;
    }
      json[r'authorStaffId'] = this.authorStaffId;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    if (this.submittedAt != null) {
      json[r'submittedAt'] = this.submittedAt!.toUtc().toIso8601String();
    } else {
      json[r'submittedAt'] = null;
    }
    if (this.review != null) {
      json[r'review'] = this.review;
    } else {
      json[r'review'] = null;
    }
    if (this.publishedVersion != null) {
      json[r'publishedVersion'] = this.publishedVersion;
    } else {
      json[r'publishedVersion'] = null;
    }
    return json;
  }

  /// Clones this instance of [RecipeDraft] and returns a new one where some of the
  /// properties have changed.
  RecipeDraft copyWith({
    String? id,
    String? recipeId,
    int? baseVersion,
    bool baseVersionSetToNull = false,
    DraftStatus? status,
    int? revision,
    AdminRecipeContent? content,
    List<FieldError>? validationErrors,
    AdminRecipeTestRecord? testRecord,
    bool testRecordSetToNull = false,
    String? authorStaffId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    bool submittedAtSetToNull = false,
    DraftReview? review,
    bool reviewSetToNull = false,
    int? publishedVersion,
    bool publishedVersionSetToNull = false,
  }) => RecipeDraft(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    baseVersion: baseVersionSetToNull ? null : baseVersion ?? this.baseVersion,
    status: status ?? this.status,
    revision: revision ?? this.revision,
    content: content ?? this.content,
    validationErrors: validationErrors ?? this.validationErrors,
    testRecord: testRecordSetToNull ? null : testRecord ?? this.testRecord,
    authorStaffId: authorStaffId ?? this.authorStaffId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    submittedAt: submittedAtSetToNull ? null : submittedAt ?? this.submittedAt,
    review: reviewSetToNull ? null : review ?? this.review,
    publishedVersion: publishedVersionSetToNull ? null : publishedVersion ?? this.publishedVersion,
  );

  /// Returns a new [RecipeDraft] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeDraft? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "RecipeDraft[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "RecipeDraft[id]" has a null value in JSON.');
        assert(json.containsKey(r'recipeId'), 'Required key "RecipeDraft[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "RecipeDraft[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'baseVersion'), 'Required key "RecipeDraft[baseVersion]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "RecipeDraft[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "RecipeDraft[status]" has a null value in JSON.');
        assert(json.containsKey(r'revision'), 'Required key "RecipeDraft[revision]" is missing from JSON.');
        assert(json[r'revision'] != null, 'Required key "RecipeDraft[revision]" has a null value in JSON.');
        assert(json.containsKey(r'content'), 'Required key "RecipeDraft[content]" is missing from JSON.');
        assert(json[r'content'] != null, 'Required key "RecipeDraft[content]" has a null value in JSON.');
        assert(json.containsKey(r'validationErrors'), 'Required key "RecipeDraft[validationErrors]" is missing from JSON.');
        assert(json[r'validationErrors'] != null, 'Required key "RecipeDraft[validationErrors]" has a null value in JSON.');
        assert(json.containsKey(r'testRecord'), 'Required key "RecipeDraft[testRecord]" is missing from JSON.');
        assert(json.containsKey(r'authorStaffId'), 'Required key "RecipeDraft[authorStaffId]" is missing from JSON.');
        assert(json[r'authorStaffId'] != null, 'Required key "RecipeDraft[authorStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "RecipeDraft[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "RecipeDraft[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "RecipeDraft[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "RecipeDraft[updatedAt]" has a null value in JSON.');
        assert(json.containsKey(r'submittedAt'), 'Required key "RecipeDraft[submittedAt]" is missing from JSON.');
        assert(json.containsKey(r'review'), 'Required key "RecipeDraft[review]" is missing from JSON.');
        assert(json.containsKey(r'publishedVersion'), 'Required key "RecipeDraft[publishedVersion]" is missing from JSON.');
        return true;
      }());

      return RecipeDraft(
        id: mapValueOfType<String>(json, r'id')!,
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        baseVersion: mapValueOfType<int>(json, r'baseVersion'),
        status: DraftStatus.fromJson(json[r'status'])!,
        revision: mapValueOfType<int>(json, r'revision')!,
        content: AdminRecipeContent.fromJson(json[r'content'])!,
        validationErrors: FieldError.listFromJson(json[r'validationErrors']),
        testRecord: AdminRecipeTestRecord.fromJson(json[r'testRecord']),
        authorStaffId: mapValueOfType<String>(json, r'authorStaffId')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
        submittedAt: mapDateTime(json, r'submittedAt', r''),
        review: DraftReview.fromJson(json[r'review']),
        publishedVersion: mapValueOfType<int>(json, r'publishedVersion'),
      );
    }
    return null;
  }

  static List<RecipeDraft> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDraft>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDraft.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeDraft> mapFromJson(dynamic json) {
    final map = <String, RecipeDraft>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeDraft.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeDraft-objects as value to a dart map
  static Map<String, List<RecipeDraft>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeDraft>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeDraft.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'recipeId',
    'baseVersion',
    'status',
    'revision',
    'content',
    'validationErrors',
    'testRecord',
    'authorStaffId',
    'createdAt',
    'updatedAt',
    'submittedAt',
    'review',
    'publishedVersion',
  };
}

