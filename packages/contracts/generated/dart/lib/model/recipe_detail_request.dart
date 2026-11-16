//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeDetailRequest {
  /// Returns a new [RecipeDetailRequest] instance.
  RecipeDetailRequest({
    required this.eaters,
    this.adaptationId = const Optional.absent(),
    this.substitutionIds = const Optional.present(const {}),
    this.variantId = const Optional.absent(),
  });

  final EaterSelection eaters;

  /// The `adaptation.adaptationId` a suggestion returned (LIB-06). Household-bound (see Conventions).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> adaptationId;

  /// Checked substitutions to use (SAF-11, CKM-09), from `listRecipeSubstitutions`. Household-bound (see Conventions).
  final Optional<Set<String>?> substitutionIds;

  /// A checked content-team variant (SAF-11), offered for this recipe.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> variantId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeDetailRequest &&
    other.eaters == eaters &&
    other.adaptationId == adaptationId &&
    _deepEquality.equals(other.substitutionIds, substitutionIds) &&
    other.variantId == variantId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (eaters.hashCode) +
    (adaptationId == null ? 0 : adaptationId!.hashCode) +
    (substitutionIds.hashCode) +
    (variantId == null ? 0 : variantId!.hashCode);

  @override
  String toString() => 'RecipeDetailRequest[eaters=$eaters, adaptationId=$adaptationId, substitutionIds=$substitutionIds, variantId=$variantId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'eaters'] = this.eaters;
    if (this.adaptationId.isPresent) {
      final value = this.adaptationId.value;
      json[r'adaptationId'] = value;
    }
    if (this.substitutionIds.isPresent) {
      final value = this.substitutionIds.value;
      json[r'substitutionIds'] = value == null ? null : value.toList(growable: false);
    }
    if (this.variantId.isPresent) {
      final value = this.variantId.value;
      json[r'variantId'] = value;
    }
    return json;
  }

  /// Clones this instance of [RecipeDetailRequest] and returns a new one where some of the
  /// properties have changed.
  RecipeDetailRequest copyWith({
    EaterSelection? eaters,
    Optional<String?>? adaptationId,
    Optional<Set<String>?>? substitutionIds,
    Optional<String?>? variantId,
  }) => RecipeDetailRequest(
    eaters: eaters ?? this.eaters,
    adaptationId: adaptationId ?? this.adaptationId,
    substitutionIds: substitutionIds ?? this.substitutionIds,
    variantId: variantId ?? this.variantId,
  );

  /// Returns a new [RecipeDetailRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeDetailRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'eaters'), 'Required key "RecipeDetailRequest[eaters]" is missing from JSON.');
        assert(json[r'eaters'] != null, 'Required key "RecipeDetailRequest[eaters]" has a null value in JSON.');
        return true;
      }());

      return RecipeDetailRequest(
        eaters: EaterSelection.fromJson(json[r'eaters'])!,
        adaptationId: json.containsKey(r'adaptationId') ? Optional.present(mapValueOfType<String>(json, r'adaptationId')) : const Optional.absent(),
        substitutionIds: json.containsKey(r'substitutionIds') ? Optional.present(json[r'substitutionIds'] is Iterable
            ? (json[r'substitutionIds'] as Iterable).cast<String>().toSet()
            : const {}) : const Optional.absent(),
        variantId: json.containsKey(r'variantId') ? Optional.present(mapValueOfType<String>(json, r'variantId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<RecipeDetailRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDetailRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDetailRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeDetailRequest> mapFromJson(dynamic json) {
    final map = <String, RecipeDetailRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeDetailRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeDetailRequest-objects as value to a dart map
  static Map<String, List<RecipeDetailRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeDetailRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeDetailRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'eaters',
  };
}

