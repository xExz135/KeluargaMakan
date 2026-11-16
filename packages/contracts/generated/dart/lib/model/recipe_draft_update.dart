//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeDraftUpdate {
  /// Returns a new [RecipeDraftUpdate] instance.
  RecipeDraftUpdate({
    required this.expectedRevision,
    required this.content,
  });

  /// Minimum value: 1
  final int expectedRevision;

  final AdminRecipeContent content;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeDraftUpdate &&
    other.expectedRevision == expectedRevision &&
    other.content == content;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (expectedRevision.hashCode) +
    (content.hashCode);

  @override
  String toString() => 'RecipeDraftUpdate[expectedRevision=$expectedRevision, content=$content]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'expectedRevision'] = this.expectedRevision;
      json[r'content'] = this.content;
    return json;
  }

  /// Clones this instance of [RecipeDraftUpdate] and returns a new one where some of the
  /// properties have changed.
  RecipeDraftUpdate copyWith({
    int? expectedRevision,
    AdminRecipeContent? content,
  }) => RecipeDraftUpdate(
    expectedRevision: expectedRevision ?? this.expectedRevision,
    content: content ?? this.content,
  );

  /// Returns a new [RecipeDraftUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeDraftUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expectedRevision'), 'Required key "RecipeDraftUpdate[expectedRevision]" is missing from JSON.');
        assert(json[r'expectedRevision'] != null, 'Required key "RecipeDraftUpdate[expectedRevision]" has a null value in JSON.');
        assert(json.containsKey(r'content'), 'Required key "RecipeDraftUpdate[content]" is missing from JSON.');
        assert(json[r'content'] != null, 'Required key "RecipeDraftUpdate[content]" has a null value in JSON.');
        return true;
      }());

      return RecipeDraftUpdate(
        expectedRevision: mapValueOfType<int>(json, r'expectedRevision')!,
        content: AdminRecipeContent.fromJson(json[r'content'])!,
      );
    }
    return null;
  }

  static List<RecipeDraftUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDraftUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDraftUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeDraftUpdate> mapFromJson(dynamic json) {
    final map = <String, RecipeDraftUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeDraftUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeDraftUpdate-objects as value to a dart map
  static Map<String, List<RecipeDraftUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeDraftUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeDraftUpdate.listFromJson(entry.value, growable: growable,);
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

