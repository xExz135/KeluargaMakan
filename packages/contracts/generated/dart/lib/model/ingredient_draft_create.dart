//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientDraftCreate {
  /// Returns a new [IngredientDraftCreate] instance.
  IngredientDraftCreate({
    required this.operation,
    required this.ingredientId,
    this.content = const Optional.present(const {}),
  });

  final DraftOperation operation;

  /// Identifier of a reference ingredient or library dish.
  final String ingredientId;

  /// One reference ingredient record exactly as `data/schema/ingredient.schema.json` defines it (components, allergens, halal, diet, brand variants). The server validates it against that schema; this contract does not repeat the schema, so the two cannot drift. Values are entered by the content team only.
  final Optional<Map<String, Object>?> content;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientDraftCreate &&
    other.operation == operation &&
    other.ingredientId == ingredientId &&
    _deepEquality.equals(other.content, content);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (operation.hashCode) +
    (ingredientId.hashCode) +
    (content.hashCode);

  @override
  String toString() => 'IngredientDraftCreate[operation=$operation, ingredientId=$ingredientId, content=$content]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'operation'] = this.operation;
      json[r'ingredientId'] = this.ingredientId;
    if (this.content.isPresent) {
      final value = this.content.value;
      json[r'content'] = value;
    }
    return json;
  }

  /// Clones this instance of [IngredientDraftCreate] and returns a new one where some of the
  /// properties have changed.
  IngredientDraftCreate copyWith({
    DraftOperation? operation,
    String? ingredientId,
    Optional<Map<String, Object>?>? content,
  }) => IngredientDraftCreate(
    operation: operation ?? this.operation,
    ingredientId: ingredientId ?? this.ingredientId,
    content: content ?? this.content,
  );

  /// Returns a new [IngredientDraftCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientDraftCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'operation'), 'Required key "IngredientDraftCreate[operation]" is missing from JSON.');
        assert(json[r'operation'] != null, 'Required key "IngredientDraftCreate[operation]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "IngredientDraftCreate[ingredientId]" is missing from JSON.');
        assert(json[r'ingredientId'] != null, 'Required key "IngredientDraftCreate[ingredientId]" has a null value in JSON.');
        return true;
      }());

      return IngredientDraftCreate(
        operation: DraftOperation.fromJson(json[r'operation'])!,
        ingredientId: mapValueOfType<String>(json, r'ingredientId')!,
        content: json.containsKey(r'content') ? Optional.present(mapCastOfType<String, Object>(json, r'content')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<IngredientDraftCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientDraftCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientDraftCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientDraftCreate> mapFromJson(dynamic json) {
    final map = <String, IngredientDraftCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientDraftCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientDraftCreate-objects as value to a dart map
  static Map<String, List<IngredientDraftCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientDraftCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientDraftCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'operation',
    'ingredientId',
  };
}

