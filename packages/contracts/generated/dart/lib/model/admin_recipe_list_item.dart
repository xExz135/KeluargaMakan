//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRecipeListItem {
  /// Returns a new [AdminRecipeListItem] instance.
  AdminRecipeListItem({
    required this.recipeId,
    required this.status,
    required this.currentVersion,
    required this.name,
    required this.updatedAt,
  });

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  final RecipeLifecycleStatus status;

  /// Minimum value: 1
  final int currentVersion;

  final LocalizedText name;

  final DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRecipeListItem &&
    other.recipeId == recipeId &&
    other.status == status &&
    other.currentVersion == currentVersion &&
    other.name == name &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipeId.hashCode) +
    (status.hashCode) +
    (currentVersion.hashCode) +
    (name.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'AdminRecipeListItem[recipeId=$recipeId, status=$status, currentVersion=$currentVersion, name=$name, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipeId'] = this.recipeId;
      json[r'status'] = this.status;
      json[r'currentVersion'] = this.currentVersion;
      json[r'name'] = this.name;
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [AdminRecipeListItem] and returns a new one where some of the
  /// properties have changed.
  AdminRecipeListItem copyWith({
    String? recipeId,
    RecipeLifecycleStatus? status,
    int? currentVersion,
    LocalizedText? name,
    DateTime? updatedAt,
  }) => AdminRecipeListItem(
    recipeId: recipeId ?? this.recipeId,
    status: status ?? this.status,
    currentVersion: currentVersion ?? this.currentVersion,
    name: name ?? this.name,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a new [AdminRecipeListItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRecipeListItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipeId'), 'Required key "AdminRecipeListItem[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "AdminRecipeListItem[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "AdminRecipeListItem[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "AdminRecipeListItem[status]" has a null value in JSON.');
        assert(json.containsKey(r'currentVersion'), 'Required key "AdminRecipeListItem[currentVersion]" is missing from JSON.');
        assert(json[r'currentVersion'] != null, 'Required key "AdminRecipeListItem[currentVersion]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "AdminRecipeListItem[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "AdminRecipeListItem[name]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "AdminRecipeListItem[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "AdminRecipeListItem[updatedAt]" has a null value in JSON.');
        return true;
      }());

      return AdminRecipeListItem(
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        status: RecipeLifecycleStatus.fromJson(json[r'status'])!,
        currentVersion: mapValueOfType<int>(json, r'currentVersion')!,
        name: LocalizedText.fromJson(json[r'name'])!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<AdminRecipeListItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRecipeListItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRecipeListItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRecipeListItem> mapFromJson(dynamic json) {
    final map = <String, AdminRecipeListItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRecipeListItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRecipeListItem-objects as value to a dart map
  static Map<String, List<AdminRecipeListItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRecipeListItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRecipeListItem.listFromJson(entry.value, growable: growable,);
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
    'updatedAt',
  };
}

