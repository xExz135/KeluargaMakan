//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SubstitutionOption {
  /// Returns a new [SubstitutionOption] instance.
  SubstitutionOption({
    required this.substitutionId,
    required this.lineId,
    required this.source_,
    this.replacements = const [],
    required this.effectNote,
    required this.safety,
    required this.recipeSafetyWith,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String substitutionId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String lineId;

  final SubstitutionSource source_;

  final List<RecipeIngredientLine> replacements;

  /// One line on how it changes the dish, from content, or from AI for `source: ai` after the server's safety-word filter; text that the filter blocks is replaced by content text or dropped.
  final LocalizedText? effectNote;

  final RecipeSafety safety;

  final RecipeSafety recipeSafetyWith;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubstitutionOption &&
    other.substitutionId == substitutionId &&
    other.lineId == lineId &&
    other.source_ == source_ &&
    _deepEquality.equals(other.replacements, replacements) &&
    other.effectNote == effectNote &&
    other.safety == safety &&
    other.recipeSafetyWith == recipeSafetyWith;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (substitutionId.hashCode) +
    (lineId.hashCode) +
    (source_.hashCode) +
    (replacements.hashCode) +
    (effectNote == null ? 0 : effectNote!.hashCode) +
    (safety.hashCode) +
    (recipeSafetyWith.hashCode);

  @override
  String toString() => 'SubstitutionOption[substitutionId=$substitutionId, lineId=$lineId, source_=$source_, replacements=$replacements, effectNote=$effectNote, safety=$safety, recipeSafetyWith=$recipeSafetyWith]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'substitutionId'] = this.substitutionId;
      json[r'lineId'] = this.lineId;
      json[r'source'] = this.source_;
      json[r'replacements'] = this.replacements;
    if (this.effectNote != null) {
      json[r'effectNote'] = this.effectNote;
    } else {
      json[r'effectNote'] = null;
    }
      json[r'safety'] = this.safety;
      json[r'recipeSafetyWith'] = this.recipeSafetyWith;
    return json;
  }

  /// Clones this instance of [SubstitutionOption] and returns a new one where some of the
  /// properties have changed.
  SubstitutionOption copyWith({
    String? substitutionId,
    String? lineId,
    SubstitutionSource? source_,
    List<RecipeIngredientLine>? replacements,
    LocalizedText? effectNote,
    bool effectNoteSetToNull = false,
    RecipeSafety? safety,
    RecipeSafety? recipeSafetyWith,
  }) => SubstitutionOption(
    substitutionId: substitutionId ?? this.substitutionId,
    lineId: lineId ?? this.lineId,
    source_: source_ ?? this.source_,
    replacements: replacements ?? this.replacements,
    effectNote: effectNoteSetToNull ? null : effectNote ?? this.effectNote,
    safety: safety ?? this.safety,
    recipeSafetyWith: recipeSafetyWith ?? this.recipeSafetyWith,
  );

  /// Returns a new [SubstitutionOption] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubstitutionOption? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'substitutionId'), 'Required key "SubstitutionOption[substitutionId]" is missing from JSON.');
        assert(json[r'substitutionId'] != null, 'Required key "SubstitutionOption[substitutionId]" has a null value in JSON.');
        assert(json.containsKey(r'lineId'), 'Required key "SubstitutionOption[lineId]" is missing from JSON.');
        assert(json[r'lineId'] != null, 'Required key "SubstitutionOption[lineId]" has a null value in JSON.');
        assert(json.containsKey(r'source'), 'Required key "SubstitutionOption[source]" is missing from JSON.');
        assert(json[r'source'] != null, 'Required key "SubstitutionOption[source]" has a null value in JSON.');
        assert(json.containsKey(r'replacements'), 'Required key "SubstitutionOption[replacements]" is missing from JSON.');
        assert(json[r'replacements'] != null, 'Required key "SubstitutionOption[replacements]" has a null value in JSON.');
        assert(json.containsKey(r'effectNote'), 'Required key "SubstitutionOption[effectNote]" is missing from JSON.');
        assert(json.containsKey(r'safety'), 'Required key "SubstitutionOption[safety]" is missing from JSON.');
        assert(json[r'safety'] != null, 'Required key "SubstitutionOption[safety]" has a null value in JSON.');
        assert(json.containsKey(r'recipeSafetyWith'), 'Required key "SubstitutionOption[recipeSafetyWith]" is missing from JSON.');
        assert(json[r'recipeSafetyWith'] != null, 'Required key "SubstitutionOption[recipeSafetyWith]" has a null value in JSON.');
        return true;
      }());

      return SubstitutionOption(
        substitutionId: mapValueOfType<String>(json, r'substitutionId')!,
        lineId: mapValueOfType<String>(json, r'lineId')!,
        source_: SubstitutionSource.fromJson(json[r'source'])!,
        replacements: RecipeIngredientLine.listFromJson(json[r'replacements']),
        effectNote: LocalizedText.fromJson(json[r'effectNote']),
        safety: RecipeSafety.fromJson(json[r'safety'])!,
        recipeSafetyWith: RecipeSafety.fromJson(json[r'recipeSafetyWith'])!,
      );
    }
    return null;
  }

  static List<SubstitutionOption> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubstitutionOption>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubstitutionOption.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubstitutionOption> mapFromJson(dynamic json) {
    final map = <String, SubstitutionOption>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubstitutionOption.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubstitutionOption-objects as value to a dart map
  static Map<String, List<SubstitutionOption>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubstitutionOption>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubstitutionOption.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'substitutionId',
    'lineId',
    'source',
    'replacements',
    'effectNote',
    'safety',
    'recipeSafetyWith',
  };
}

