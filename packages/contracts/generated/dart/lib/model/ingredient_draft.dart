//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientDraft {
  /// Returns a new [IngredientDraft] instance.
  IngredientDraft({
    required this.id,
    required this.operation,
    required this.ingredientId,
    required this.status,
    required this.revision,
    required this.content,
    required this.baseReferenceVersion,
    this.validationErrors = const [],
    required this.authorStaffId,
    required this.createdAt,
    required this.updatedAt,
    required this.submittedAt,
    required this.review,
    required this.publishedReferenceVersion,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final DraftOperation operation;

  /// Identifier of a reference ingredient or library dish.
  final String ingredientId;

  final DraftStatus status;

  /// Minimum value: 1
  final int revision;

  /// One reference ingredient record exactly as `data/schema/ingredient.schema.json` defines it (components, allergens, halal, diet, brand variants). The server validates it against that schema; this contract does not repeat the schema, so the two cannot drift. Values are entered by the content team only.
  final Map<String, Object>? content;

  /// The reference data version the draft was started from.
  final String baseReferenceVersion;

  final List<FieldError> validationErrors;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String authorStaffId;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? submittedAt;

  final DraftReview? review;

  /// The release that published the change, once published.
  final String? publishedReferenceVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientDraft &&
    other.id == id &&
    other.operation == operation &&
    other.ingredientId == ingredientId &&
    other.status == status &&
    other.revision == revision &&
    _deepEquality.equals(other.content, content) &&
    other.baseReferenceVersion == baseReferenceVersion &&
    _deepEquality.equals(other.validationErrors, validationErrors) &&
    other.authorStaffId == authorStaffId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.submittedAt == submittedAt &&
    other.review == review &&
    other.publishedReferenceVersion == publishedReferenceVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (operation.hashCode) +
    (ingredientId.hashCode) +
    (status.hashCode) +
    (revision.hashCode) +
    (content == null ? 0 : content!.hashCode) +
    (baseReferenceVersion.hashCode) +
    (validationErrors.hashCode) +
    (authorStaffId.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode) +
    (review == null ? 0 : review!.hashCode) +
    (publishedReferenceVersion == null ? 0 : publishedReferenceVersion!.hashCode);

  @override
  String toString() => 'IngredientDraft[id=$id, operation=$operation, ingredientId=$ingredientId, status=$status, revision=$revision, content=$content, baseReferenceVersion=$baseReferenceVersion, validationErrors=$validationErrors, authorStaffId=$authorStaffId, createdAt=$createdAt, updatedAt=$updatedAt, submittedAt=$submittedAt, review=$review, publishedReferenceVersion=$publishedReferenceVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'operation'] = this.operation;
      json[r'ingredientId'] = this.ingredientId;
      json[r'status'] = this.status;
      json[r'revision'] = this.revision;
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
      json[r'baseReferenceVersion'] = this.baseReferenceVersion;
      json[r'validationErrors'] = this.validationErrors;
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
    if (this.publishedReferenceVersion != null) {
      json[r'publishedReferenceVersion'] = this.publishedReferenceVersion;
    } else {
      json[r'publishedReferenceVersion'] = null;
    }
    return json;
  }

  /// Clones this instance of [IngredientDraft] and returns a new one where some of the
  /// properties have changed.
  IngredientDraft copyWith({
    String? id,
    DraftOperation? operation,
    String? ingredientId,
    DraftStatus? status,
    int? revision,
    Map<String, Object>? content,
    bool contentSetToNull = false,
    String? baseReferenceVersion,
    List<FieldError>? validationErrors,
    String? authorStaffId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    bool submittedAtSetToNull = false,
    DraftReview? review,
    bool reviewSetToNull = false,
    String? publishedReferenceVersion,
    bool publishedReferenceVersionSetToNull = false,
  }) => IngredientDraft(
    id: id ?? this.id,
    operation: operation ?? this.operation,
    ingredientId: ingredientId ?? this.ingredientId,
    status: status ?? this.status,
    revision: revision ?? this.revision,
    content: contentSetToNull ? null : content ?? this.content,
    baseReferenceVersion: baseReferenceVersion ?? this.baseReferenceVersion,
    validationErrors: validationErrors ?? this.validationErrors,
    authorStaffId: authorStaffId ?? this.authorStaffId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    submittedAt: submittedAtSetToNull ? null : submittedAt ?? this.submittedAt,
    review: reviewSetToNull ? null : review ?? this.review,
    publishedReferenceVersion: publishedReferenceVersionSetToNull ? null : publishedReferenceVersion ?? this.publishedReferenceVersion,
  );

  /// Returns a new [IngredientDraft] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientDraft? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "IngredientDraft[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "IngredientDraft[id]" has a null value in JSON.');
        assert(json.containsKey(r'operation'), 'Required key "IngredientDraft[operation]" is missing from JSON.');
        assert(json[r'operation'] != null, 'Required key "IngredientDraft[operation]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "IngredientDraft[ingredientId]" is missing from JSON.');
        assert(json[r'ingredientId'] != null, 'Required key "IngredientDraft[ingredientId]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "IngredientDraft[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "IngredientDraft[status]" has a null value in JSON.');
        assert(json.containsKey(r'revision'), 'Required key "IngredientDraft[revision]" is missing from JSON.');
        assert(json[r'revision'] != null, 'Required key "IngredientDraft[revision]" has a null value in JSON.');
        assert(json.containsKey(r'content'), 'Required key "IngredientDraft[content]" is missing from JSON.');
        assert(json.containsKey(r'baseReferenceVersion'), 'Required key "IngredientDraft[baseReferenceVersion]" is missing from JSON.');
        assert(json[r'baseReferenceVersion'] != null, 'Required key "IngredientDraft[baseReferenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'validationErrors'), 'Required key "IngredientDraft[validationErrors]" is missing from JSON.');
        assert(json[r'validationErrors'] != null, 'Required key "IngredientDraft[validationErrors]" has a null value in JSON.');
        assert(json.containsKey(r'authorStaffId'), 'Required key "IngredientDraft[authorStaffId]" is missing from JSON.');
        assert(json[r'authorStaffId'] != null, 'Required key "IngredientDraft[authorStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "IngredientDraft[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "IngredientDraft[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "IngredientDraft[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "IngredientDraft[updatedAt]" has a null value in JSON.');
        assert(json.containsKey(r'submittedAt'), 'Required key "IngredientDraft[submittedAt]" is missing from JSON.');
        assert(json.containsKey(r'review'), 'Required key "IngredientDraft[review]" is missing from JSON.');
        assert(json.containsKey(r'publishedReferenceVersion'), 'Required key "IngredientDraft[publishedReferenceVersion]" is missing from JSON.');
        return true;
      }());

      return IngredientDraft(
        id: mapValueOfType<String>(json, r'id')!,
        operation: DraftOperation.fromJson(json[r'operation'])!,
        ingredientId: mapValueOfType<String>(json, r'ingredientId')!,
        status: DraftStatus.fromJson(json[r'status'])!,
        revision: mapValueOfType<int>(json, r'revision')!,
        content: mapCastOfType<String, Object>(json, r'content'),
        baseReferenceVersion: mapValueOfType<String>(json, r'baseReferenceVersion')!,
        validationErrors: FieldError.listFromJson(json[r'validationErrors']),
        authorStaffId: mapValueOfType<String>(json, r'authorStaffId')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
        submittedAt: mapDateTime(json, r'submittedAt', r''),
        review: DraftReview.fromJson(json[r'review']),
        publishedReferenceVersion: mapValueOfType<String>(json, r'publishedReferenceVersion'),
      );
    }
    return null;
  }

  static List<IngredientDraft> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientDraft>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientDraft.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientDraft> mapFromJson(dynamic json) {
    final map = <String, IngredientDraft>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientDraft.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientDraft-objects as value to a dart map
  static Map<String, List<IngredientDraft>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientDraft>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientDraft.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'operation',
    'ingredientId',
    'status',
    'revision',
    'content',
    'baseReferenceVersion',
    'validationErrors',
    'authorStaffId',
    'createdAt',
    'updatedAt',
    'submittedAt',
    'review',
    'publishedReferenceVersion',
  };
}

