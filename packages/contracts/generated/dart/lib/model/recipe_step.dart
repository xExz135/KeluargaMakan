//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeStep {
  /// Returns a new [RecipeStep] instance.
  RecipeStep({
    required this.stepId,
    required this.text,
    required this.timerSeconds,
    this.ingredientLineIds = const {},
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String stepId;

  final LocalizedText text;

  /// Minimum value: 1
  final int? timerSeconds;

  final Set<String> ingredientLineIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeStep &&
    other.stepId == stepId &&
    other.text == text &&
    other.timerSeconds == timerSeconds &&
    _deepEquality.equals(other.ingredientLineIds, ingredientLineIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (stepId.hashCode) +
    (text.hashCode) +
    (timerSeconds == null ? 0 : timerSeconds!.hashCode) +
    (ingredientLineIds.hashCode);

  @override
  String toString() => 'RecipeStep[stepId=$stepId, text=$text, timerSeconds=$timerSeconds, ingredientLineIds=$ingredientLineIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'stepId'] = this.stepId;
      json[r'text'] = this.text;
    if (this.timerSeconds != null) {
      json[r'timerSeconds'] = this.timerSeconds;
    } else {
      json[r'timerSeconds'] = null;
    }
      json[r'ingredientLineIds'] = this.ingredientLineIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [RecipeStep] and returns a new one where some of the
  /// properties have changed.
  RecipeStep copyWith({
    String? stepId,
    LocalizedText? text,
    int? timerSeconds,
    bool timerSecondsSetToNull = false,
    Set<String>? ingredientLineIds,
  }) => RecipeStep(
    stepId: stepId ?? this.stepId,
    text: text ?? this.text,
    timerSeconds: timerSecondsSetToNull ? null : timerSeconds ?? this.timerSeconds,
    ingredientLineIds: ingredientLineIds ?? this.ingredientLineIds,
  );

  /// Returns a new [RecipeStep] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeStep? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'stepId'), 'Required key "RecipeStep[stepId]" is missing from JSON.');
        assert(json[r'stepId'] != null, 'Required key "RecipeStep[stepId]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "RecipeStep[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "RecipeStep[text]" has a null value in JSON.');
        assert(json.containsKey(r'timerSeconds'), 'Required key "RecipeStep[timerSeconds]" is missing from JSON.');
        assert(json.containsKey(r'ingredientLineIds'), 'Required key "RecipeStep[ingredientLineIds]" is missing from JSON.');
        assert(json[r'ingredientLineIds'] != null, 'Required key "RecipeStep[ingredientLineIds]" has a null value in JSON.');
        return true;
      }());

      return RecipeStep(
        stepId: mapValueOfType<String>(json, r'stepId')!,
        text: LocalizedText.fromJson(json[r'text'])!,
        timerSeconds: mapValueOfType<int>(json, r'timerSeconds'),
        ingredientLineIds: json[r'ingredientLineIds'] is Iterable
            ? (json[r'ingredientLineIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<RecipeStep> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeStep>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeStep.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeStep> mapFromJson(dynamic json) {
    final map = <String, RecipeStep>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeStep.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeStep-objects as value to a dart map
  static Map<String, List<RecipeStep>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeStep>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeStep.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'stepId',
    'text',
    'timerSeconds',
    'ingredientLineIds',
  };
}

