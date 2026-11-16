//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRecipeVersion {
  /// Returns a new [AdminRecipeVersion] instance.
  AdminRecipeVersion({
    required this.version,
    required this.publishedAt,
    required this.authorStaffId,
    required this.approvedByStaffId,
    required this.testRecord,
    required this.content,
    required this.nutritionPerServing,
  });

  /// Minimum value: 1
  final int version;

  final DateTime publishedAt;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String authorStaffId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String approvedByStaffId;

  final AdminRecipeTestRecord testRecord;

  final AdminRecipeContent content;

  final NutritionPerServing nutritionPerServing;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRecipeVersion &&
    other.version == version &&
    other.publishedAt == publishedAt &&
    other.authorStaffId == authorStaffId &&
    other.approvedByStaffId == approvedByStaffId &&
    other.testRecord == testRecord &&
    other.content == content &&
    other.nutritionPerServing == nutritionPerServing;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (version.hashCode) +
    (publishedAt.hashCode) +
    (authorStaffId.hashCode) +
    (approvedByStaffId.hashCode) +
    (testRecord.hashCode) +
    (content.hashCode) +
    (nutritionPerServing.hashCode);

  @override
  String toString() => 'AdminRecipeVersion[version=$version, publishedAt=$publishedAt, authorStaffId=$authorStaffId, approvedByStaffId=$approvedByStaffId, testRecord=$testRecord, content=$content, nutritionPerServing=$nutritionPerServing]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'version'] = this.version;
      json[r'publishedAt'] = this.publishedAt.toUtc().toIso8601String();
      json[r'authorStaffId'] = this.authorStaffId;
      json[r'approvedByStaffId'] = this.approvedByStaffId;
      json[r'testRecord'] = this.testRecord;
      json[r'content'] = this.content;
      json[r'nutritionPerServing'] = this.nutritionPerServing;
    return json;
  }

  /// Clones this instance of [AdminRecipeVersion] and returns a new one where some of the
  /// properties have changed.
  AdminRecipeVersion copyWith({
    int? version,
    DateTime? publishedAt,
    String? authorStaffId,
    String? approvedByStaffId,
    AdminRecipeTestRecord? testRecord,
    AdminRecipeContent? content,
    NutritionPerServing? nutritionPerServing,
  }) => AdminRecipeVersion(
    version: version ?? this.version,
    publishedAt: publishedAt ?? this.publishedAt,
    authorStaffId: authorStaffId ?? this.authorStaffId,
    approvedByStaffId: approvedByStaffId ?? this.approvedByStaffId,
    testRecord: testRecord ?? this.testRecord,
    content: content ?? this.content,
    nutritionPerServing: nutritionPerServing ?? this.nutritionPerServing,
  );

  /// Returns a new [AdminRecipeVersion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRecipeVersion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'version'), 'Required key "AdminRecipeVersion[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "AdminRecipeVersion[version]" has a null value in JSON.');
        assert(json.containsKey(r'publishedAt'), 'Required key "AdminRecipeVersion[publishedAt]" is missing from JSON.');
        assert(json[r'publishedAt'] != null, 'Required key "AdminRecipeVersion[publishedAt]" has a null value in JSON.');
        assert(json.containsKey(r'authorStaffId'), 'Required key "AdminRecipeVersion[authorStaffId]" is missing from JSON.');
        assert(json[r'authorStaffId'] != null, 'Required key "AdminRecipeVersion[authorStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'approvedByStaffId'), 'Required key "AdminRecipeVersion[approvedByStaffId]" is missing from JSON.');
        assert(json[r'approvedByStaffId'] != null, 'Required key "AdminRecipeVersion[approvedByStaffId]" has a null value in JSON.');
        assert(json.containsKey(r'testRecord'), 'Required key "AdminRecipeVersion[testRecord]" is missing from JSON.');
        assert(json[r'testRecord'] != null, 'Required key "AdminRecipeVersion[testRecord]" has a null value in JSON.');
        assert(json.containsKey(r'content'), 'Required key "AdminRecipeVersion[content]" is missing from JSON.');
        assert(json[r'content'] != null, 'Required key "AdminRecipeVersion[content]" has a null value in JSON.');
        assert(json.containsKey(r'nutritionPerServing'), 'Required key "AdminRecipeVersion[nutritionPerServing]" is missing from JSON.');
        assert(json[r'nutritionPerServing'] != null, 'Required key "AdminRecipeVersion[nutritionPerServing]" has a null value in JSON.');
        return true;
      }());

      return AdminRecipeVersion(
        version: mapValueOfType<int>(json, r'version')!,
        publishedAt: mapDateTime(json, r'publishedAt', r'')!,
        authorStaffId: mapValueOfType<String>(json, r'authorStaffId')!,
        approvedByStaffId: mapValueOfType<String>(json, r'approvedByStaffId')!,
        testRecord: AdminRecipeTestRecord.fromJson(json[r'testRecord'])!,
        content: AdminRecipeContent.fromJson(json[r'content'])!,
        nutritionPerServing: NutritionPerServing.fromJson(json[r'nutritionPerServing'])!,
      );
    }
    return null;
  }

  static List<AdminRecipeVersion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRecipeVersion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRecipeVersion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRecipeVersion> mapFromJson(dynamic json) {
    final map = <String, AdminRecipeVersion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRecipeVersion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRecipeVersion-objects as value to a dart map
  static Map<String, List<AdminRecipeVersion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRecipeVersion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRecipeVersion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'version',
    'publishedAt',
    'authorStaffId',
    'approvedByStaffId',
    'testRecord',
    'content',
    'nutritionPerServing',
  };
}

