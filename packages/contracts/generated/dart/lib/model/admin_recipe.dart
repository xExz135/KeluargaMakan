//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRecipe {
  /// Returns a new [AdminRecipe] instance.
  AdminRecipe({
    required this.recipeId,
    required this.status,
    required this.currentVersion,
    required this.name,
    this.versions = const [],
    required this.retiredAt,
    required this.retiredByStaffId,
  });

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  final RecipeLifecycleStatus status;

  /// Minimum value: 1
  final int currentVersion;

  final LocalizedText name;

  /// Newest first.
  final List<AdminRecipeVersion> versions;

  final DateTime? retiredAt;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? retiredByStaffId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRecipe &&
    other.recipeId == recipeId &&
    other.status == status &&
    other.currentVersion == currentVersion &&
    other.name == name &&
    _deepEquality.equals(other.versions, versions) &&
    other.retiredAt == retiredAt &&
    other.retiredByStaffId == retiredByStaffId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipeId.hashCode) +
    (status.hashCode) +
    (currentVersion.hashCode) +
    (name.hashCode) +
    (versions.hashCode) +
    (retiredAt == null ? 0 : retiredAt!.hashCode) +
    (retiredByStaffId == null ? 0 : retiredByStaffId!.hashCode);

  @override
  String toString() => 'AdminRecipe[recipeId=$recipeId, status=$status, currentVersion=$currentVersion, name=$name, versions=$versions, retiredAt=$retiredAt, retiredByStaffId=$retiredByStaffId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipeId'] = this.recipeId;
      json[r'status'] = this.status;
      json[r'currentVersion'] = this.currentVersion;
      json[r'name'] = this.name;
      json[r'versions'] = this.versions;
    if (this.retiredAt != null) {
      json[r'retiredAt'] = this.retiredAt!.toUtc().toIso8601String();
    } else {
      json[r'retiredAt'] = null;
    }
    if (this.retiredByStaffId != null) {
      json[r'retiredByStaffId'] = this.retiredByStaffId;
    } else {
      json[r'retiredByStaffId'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdminRecipe] and returns a new one where some of the
  /// properties have changed.
  AdminRecipe copyWith({
    String? recipeId,
    RecipeLifecycleStatus? status,
    int? currentVersion,
    LocalizedText? name,
    List<AdminRecipeVersion>? versions,
    DateTime? retiredAt,
    bool retiredAtSetToNull = false,
    String? retiredByStaffId,
    bool retiredByStaffIdSetToNull = false,
  }) => AdminRecipe(
    recipeId: recipeId ?? this.recipeId,
    status: status ?? this.status,
    currentVersion: currentVersion ?? this.currentVersion,
    name: name ?? this.name,
    versions: versions ?? this.versions,
    retiredAt: retiredAtSetToNull ? null : retiredAt ?? this.retiredAt,
    retiredByStaffId: retiredByStaffIdSetToNull ? null : retiredByStaffId ?? this.retiredByStaffId,
  );

  /// Returns a new [AdminRecipe] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRecipe? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipeId'), 'Required key "AdminRecipe[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "AdminRecipe[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "AdminRecipe[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "AdminRecipe[status]" has a null value in JSON.');
        assert(json.containsKey(r'currentVersion'), 'Required key "AdminRecipe[currentVersion]" is missing from JSON.');
        assert(json[r'currentVersion'] != null, 'Required key "AdminRecipe[currentVersion]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "AdminRecipe[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "AdminRecipe[name]" has a null value in JSON.');
        assert(json.containsKey(r'versions'), 'Required key "AdminRecipe[versions]" is missing from JSON.');
        assert(json[r'versions'] != null, 'Required key "AdminRecipe[versions]" has a null value in JSON.');
        assert(json.containsKey(r'retiredAt'), 'Required key "AdminRecipe[retiredAt]" is missing from JSON.');
        assert(json.containsKey(r'retiredByStaffId'), 'Required key "AdminRecipe[retiredByStaffId]" is missing from JSON.');
        return true;
      }());

      return AdminRecipe(
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        status: RecipeLifecycleStatus.fromJson(json[r'status'])!,
        currentVersion: mapValueOfType<int>(json, r'currentVersion')!,
        name: LocalizedText.fromJson(json[r'name'])!,
        versions: AdminRecipeVersion.listFromJson(json[r'versions']),
        retiredAt: mapDateTime(json, r'retiredAt', r''),
        retiredByStaffId: mapValueOfType<String>(json, r'retiredByStaffId'),
      );
    }
    return null;
  }

  static List<AdminRecipe> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRecipe>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRecipe.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRecipe> mapFromJson(dynamic json) {
    final map = <String, AdminRecipe>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRecipe.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRecipe-objects as value to a dart map
  static Map<String, List<AdminRecipe>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRecipe>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRecipe.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recipeId',
    'status',
    'currentVersion',
    'name',
    'versions',
    'retiredAt',
    'retiredByStaffId',
  };
}

