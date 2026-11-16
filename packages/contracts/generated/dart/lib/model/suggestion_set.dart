//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SuggestionSet {
  /// Returns a new [SuggestionSet] instance.
  SuggestionSet({
    required this.id,
    required this.page,
    required this.inputs,
    this.memberIds = const {},
    this.items = const [],
    required this.poolExhausted,
    required this.noSafeRecipe,
    required this.aiAvailability,
    required this.libraryVersion,
    required this.expiresAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// Minimum value: 1
  final int page;

  final SuggestionRequest inputs;

  final Set<String> memberIds;

  final List<Suggestion> items;

  final bool poolExhausted;

  final NoSafeRecipe? noSafeRecipe;

  final AiAvailability aiAvailability;

  final String libraryVersion;

  /// Until when \"Show others\" works for this set.
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SuggestionSet &&
    other.id == id &&
    other.page == page &&
    other.inputs == inputs &&
    _deepEquality.equals(other.memberIds, memberIds) &&
    _deepEquality.equals(other.items, items) &&
    other.poolExhausted == poolExhausted &&
    other.noSafeRecipe == noSafeRecipe &&
    other.aiAvailability == aiAvailability &&
    other.libraryVersion == libraryVersion &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (page.hashCode) +
    (inputs.hashCode) +
    (memberIds.hashCode) +
    (items.hashCode) +
    (poolExhausted.hashCode) +
    (noSafeRecipe == null ? 0 : noSafeRecipe!.hashCode) +
    (aiAvailability.hashCode) +
    (libraryVersion.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'SuggestionSet[id=$id, page=$page, inputs=$inputs, memberIds=$memberIds, items=$items, poolExhausted=$poolExhausted, noSafeRecipe=$noSafeRecipe, aiAvailability=$aiAvailability, libraryVersion=$libraryVersion, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'page'] = this.page;
      json[r'inputs'] = this.inputs;
      json[r'memberIds'] = this.memberIds.toList(growable: false);
      json[r'items'] = this.items;
      json[r'poolExhausted'] = this.poolExhausted;
    if (this.noSafeRecipe != null) {
      json[r'noSafeRecipe'] = this.noSafeRecipe;
    } else {
      json[r'noSafeRecipe'] = null;
    }
      json[r'aiAvailability'] = this.aiAvailability;
      json[r'libraryVersion'] = this.libraryVersion;
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SuggestionSet] and returns a new one where some of the
  /// properties have changed.
  SuggestionSet copyWith({
    String? id,
    int? page,
    SuggestionRequest? inputs,
    Set<String>? memberIds,
    List<Suggestion>? items,
    bool? poolExhausted,
    NoSafeRecipe? noSafeRecipe,
    bool noSafeRecipeSetToNull = false,
    AiAvailability? aiAvailability,
    String? libraryVersion,
    DateTime? expiresAt,
  }) => SuggestionSet(
    id: id ?? this.id,
    page: page ?? this.page,
    inputs: inputs ?? this.inputs,
    memberIds: memberIds ?? this.memberIds,
    items: items ?? this.items,
    poolExhausted: poolExhausted ?? this.poolExhausted,
    noSafeRecipe: noSafeRecipeSetToNull ? null : noSafeRecipe ?? this.noSafeRecipe,
    aiAvailability: aiAvailability ?? this.aiAvailability,
    libraryVersion: libraryVersion ?? this.libraryVersion,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  /// Returns a new [SuggestionSet] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SuggestionSet? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "SuggestionSet[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "SuggestionSet[id]" has a null value in JSON.');
        assert(json.containsKey(r'page'), 'Required key "SuggestionSet[page]" is missing from JSON.');
        assert(json[r'page'] != null, 'Required key "SuggestionSet[page]" has a null value in JSON.');
        assert(json.containsKey(r'inputs'), 'Required key "SuggestionSet[inputs]" is missing from JSON.');
        assert(json[r'inputs'] != null, 'Required key "SuggestionSet[inputs]" has a null value in JSON.');
        assert(json.containsKey(r'memberIds'), 'Required key "SuggestionSet[memberIds]" is missing from JSON.');
        assert(json[r'memberIds'] != null, 'Required key "SuggestionSet[memberIds]" has a null value in JSON.');
        assert(json.containsKey(r'items'), 'Required key "SuggestionSet[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "SuggestionSet[items]" has a null value in JSON.');
        assert(json.containsKey(r'poolExhausted'), 'Required key "SuggestionSet[poolExhausted]" is missing from JSON.');
        assert(json[r'poolExhausted'] != null, 'Required key "SuggestionSet[poolExhausted]" has a null value in JSON.');
        assert(json.containsKey(r'noSafeRecipe'), 'Required key "SuggestionSet[noSafeRecipe]" is missing from JSON.');
        assert(json.containsKey(r'aiAvailability'), 'Required key "SuggestionSet[aiAvailability]" is missing from JSON.');
        assert(json[r'aiAvailability'] != null, 'Required key "SuggestionSet[aiAvailability]" has a null value in JSON.');
        assert(json.containsKey(r'libraryVersion'), 'Required key "SuggestionSet[libraryVersion]" is missing from JSON.');
        assert(json[r'libraryVersion'] != null, 'Required key "SuggestionSet[libraryVersion]" has a null value in JSON.');
        assert(json.containsKey(r'expiresAt'), 'Required key "SuggestionSet[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null, 'Required key "SuggestionSet[expiresAt]" has a null value in JSON.');
        return true;
      }());

      return SuggestionSet(
        id: mapValueOfType<String>(json, r'id')!,
        page: mapValueOfType<int>(json, r'page')!,
        inputs: SuggestionRequest.fromJson(json[r'inputs'])!,
        memberIds: json[r'memberIds'] is Iterable
            ? (json[r'memberIds'] as Iterable).cast<String>().toSet()
            : const {},
        items: Suggestion.listFromJson(json[r'items']),
        poolExhausted: mapValueOfType<bool>(json, r'poolExhausted')!,
        noSafeRecipe: NoSafeRecipe.fromJson(json[r'noSafeRecipe']),
        aiAvailability: AiAvailability.fromJson(json[r'aiAvailability'])!,
        libraryVersion: mapValueOfType<String>(json, r'libraryVersion')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
      );
    }
    return null;
  }

  static List<SuggestionSet> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SuggestionSet>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SuggestionSet.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SuggestionSet> mapFromJson(dynamic json) {
    final map = <String, SuggestionSet>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SuggestionSet.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SuggestionSet-objects as value to a dart map
  static Map<String, List<SuggestionSet>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SuggestionSet>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SuggestionSet.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'page',
    'inputs',
    'memberIds',
    'items',
    'poolExhausted',
    'noSafeRecipe',
    'aiAvailability',
    'libraryVersion',
    'expiresAt',
  };
}

