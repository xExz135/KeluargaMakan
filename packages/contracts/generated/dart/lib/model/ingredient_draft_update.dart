//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientDraftUpdate {
  /// Returns a new [IngredientDraftUpdate] instance.
  IngredientDraftUpdate({
    required this.expectedRevision,
    this.content = const {},
  });

  /// Minimum value: 1
  final int expectedRevision;

  /// One reference ingredient record exactly as `data/schema/ingredient.schema.json` defines it (components, allergens, halal, diet, brand variants). The server validates it against that schema; this contract does not repeat the schema, so the two cannot drift. Values are entered by the content team only.
  final Map<String, Object> content;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientDraftUpdate &&
    other.expectedRevision == expectedRevision &&
    _deepEquality.equals(other.content, content);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (expectedRevision.hashCode) +
    (content.hashCode);

  @override
  String toString() => 'IngredientDraftUpdate[expectedRevision=$expectedRevision, content=$content]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'expectedRevision'] = this.expectedRevision;
      json[r'content'] = this.content;
    return json;
  }

  /// Clones this instance of [IngredientDraftUpdate] and returns a new one where some of the
  /// properties have changed.
  IngredientDraftUpdate copyWith({
    int? expectedRevision,
    Map<String, Object>? content,
  }) => IngredientDraftUpdate(
    expectedRevision: expectedRevision ?? this.expectedRevision,
    content: content ?? this.content,
  );

  /// Returns a new [IngredientDraftUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientDraftUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expectedRevision'), 'Required key "IngredientDraftUpdate[expectedRevision]" is missing from JSON.');
        assert(json[r'expectedRevision'] != null, 'Required key "IngredientDraftUpdate[expectedRevision]" has a null value in JSON.');
        assert(json.containsKey(r'content'), 'Required key "IngredientDraftUpdate[content]" is missing from JSON.');
        assert(json[r'content'] != null, 'Required key "IngredientDraftUpdate[content]" has a null value in JSON.');
        return true;
      }());

      return IngredientDraftUpdate(
        expectedRevision: mapValueOfType<int>(json, r'expectedRevision')!,
        content: mapCastOfType<String, Object>(json, r'content')!,
      );
    }
    return null;
  }

  static List<IngredientDraftUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientDraftUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientDraftUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientDraftUpdate> mapFromJson(dynamic json) {
    final map = <String, IngredientDraftUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientDraftUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientDraftUpdate-objects as value to a dart map
  static Map<String, List<IngredientDraftUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientDraftUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientDraftUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expectedRevision',
    'content',
  };
}

