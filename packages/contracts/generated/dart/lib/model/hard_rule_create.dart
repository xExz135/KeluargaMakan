//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HardRuleCreate {
  /// Returns a new [HardRuleCreate] instance.
  HardRuleCreate({
    required this.type,
    this.allergen = const Optional.absent(),
    this.freeText = const Optional.absent(),
    this.mappedIngredientIds = const Optional.absent(),
  });

  final HardRuleType type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<StandardAllergen?> allergen;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> freeText;

  /// Absent or null for an unmapped rule. When present, at least one reference ingredient ID; an empty list is rejected.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<Set<String>?> mappedIngredientIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HardRuleCreate &&
    other.type == type &&
    other.allergen == allergen &&
    other.freeText == freeText &&
    _deepEquality.equals(other.mappedIngredientIds, mappedIngredientIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (allergen == null ? 0 : allergen!.hashCode) +
    (freeText == null ? 0 : freeText!.hashCode) +
    (mappedIngredientIds == null ? 0 : mappedIngredientIds!.hashCode);

  @override
  String toString() => 'HardRuleCreate[type=$type, allergen=$allergen, freeText=$freeText, mappedIngredientIds=$mappedIngredientIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
    if (this.allergen.isPresent) {
      final value = this.allergen.value;
      json[r'allergen'] = value;
    }
    if (this.freeText.isPresent) {
      final value = this.freeText.value;
      json[r'freeText'] = value;
    }
    if (this.mappedIngredientIds.isPresent) {
      final value = this.mappedIngredientIds.value;
      json[r'mappedIngredientIds'] = value == null ? null : value.toList(growable: false);
    }
    return json;
  }

  /// Clones this instance of [HardRuleCreate] and returns a new one where some of the
  /// properties have changed.
  HardRuleCreate copyWith({
    HardRuleType? type,
    Optional<StandardAllergen?>? allergen,
    Optional<String?>? freeText,
    Optional<Set<String>?>? mappedIngredientIds,
  }) => HardRuleCreate(
    type: type ?? this.type,
    allergen: allergen ?? this.allergen,
    freeText: freeText ?? this.freeText,
    mappedIngredientIds: mappedIngredientIds ?? this.mappedIngredientIds,
  );

  /// Returns a new [HardRuleCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HardRuleCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "HardRuleCreate[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "HardRuleCreate[type]" has a null value in JSON.');
        return true;
      }());

      return HardRuleCreate(
        type: HardRuleType.fromJson(json[r'type'])!,
        allergen: json.containsKey(r'allergen') ? Optional.present(StandardAllergen.fromJson(json[r'allergen'])) : const Optional.absent(),
        freeText: json.containsKey(r'freeText') ? Optional.present(mapValueOfType<String>(json, r'freeText')) : const Optional.absent(),
        mappedIngredientIds: json.containsKey(r'mappedIngredientIds') ? Optional.present(json[r'mappedIngredientIds'] is Iterable
            ? (json[r'mappedIngredientIds'] as Iterable).cast<String>().toSet()
            : null) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<HardRuleCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HardRuleCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HardRuleCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HardRuleCreate> mapFromJson(dynamic json) {
    final map = <String, HardRuleCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HardRuleCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HardRuleCreate-objects as value to a dart map
  static Map<String, List<HardRuleCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HardRuleCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HardRuleCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
  };
}

