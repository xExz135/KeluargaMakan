//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeDraftCreate {
  /// Returns a new [RecipeDraftCreate] instance.
  RecipeDraftCreate({
    this.recipeId = const Optional.absent(),
    required this.content,
  });

  /// Identifier of a reference ingredient or library dish.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> recipeId;

  final AdminRecipeContent content;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeDraftCreate &&
    other.recipeId == recipeId &&
    other.content == content;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipeId == null ? 0 : recipeId!.hashCode) +
    (content.hashCode);

  @override
  String toString() => 'RecipeDraftCreate[recipeId=$recipeId, content=$content]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.recipeId.isPresent) {
      final value = this.recipeId.value;
      json[r'recipeId'] = value;
    }
      json[r'content'] = this.content;
    return json;
  }

  /// Clones this instance of [RecipeDraftCreate] and returns a new one where some of the
  /// properties have changed.
  RecipeDraftCreate copyWith({
    Optional<String?>? recipeId,
    AdminRecipeContent? content,
  }) => RecipeDraftCreate(
    recipeId: recipeId ?? this.recipeId,
    content: content ?? this.content,
  );

  /// Returns a new [RecipeDraftCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeDraftCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'content'), 'Required key "RecipeDraftCreate[content]" is missing from JSON.');
        assert(json[r'content'] != null, 'Required key "RecipeDraftCreate[content]" has a null value in JSON.');
        return true;
      }());

      return RecipeDraftCreate(
        recipeId: json.containsKey(r'recipeId') ? Optional.present(mapValueOfType<String>(json, r'recipeId')) : const Optional.absent(),
        content: AdminRecipeContent.fromJson(json[r'content'])!,
      );
    }
    return null;
  }

  static List<RecipeDraftCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDraftCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDraftCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeDraftCreate> mapFromJson(dynamic json) {
    final map = <String, RecipeDraftCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeDraftCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeDraftCreate-objects as value to a dart map
  static Map<String, List<RecipeDraftCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeDraftCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeDraftCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'content',
  };
}

