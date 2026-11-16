//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class CookedMealInput {
  /// Returns a new [CookedMealInput] instance.
  CookedMealInput({
    required this.recipeId,
    required this.recipeVersion,
    required this.adaptationId,
    required this.variantId,
    this.substitutionIds = const {},
    required this.cookedOn,
    required this.mealType,
    this.eaterMemberIds = const {},
    required this.servings,
    required this.feedback,
  });

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  /// Minimum value: 1
  final int recipeVersion;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? adaptationId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? variantId;

  final Set<String> substitutionIds;

  final DateTime cookedOn;

  final MealType mealType;

  final Set<String> eaterMemberIds;

  /// Minimum value: 1
  /// Maximum value: 100
  final int servings;

  final MealFeedbackInput? feedback;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CookedMealInput &&
    other.recipeId == recipeId &&
    other.recipeVersion == recipeVersion &&
    other.adaptationId == adaptationId &&
    other.variantId == variantId &&
    _deepEquality.equals(other.substitutionIds, substitutionIds) &&
    other.cookedOn == cookedOn &&
    other.mealType == mealType &&
    _deepEquality.equals(other.eaterMemberIds, eaterMemberIds) &&
    other.servings == servings &&
    other.feedback == feedback;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (recipeId.hashCode) +
    (recipeVersion.hashCode) +
    (adaptationId == null ? 0 : adaptationId!.hashCode) +
    (variantId == null ? 0 : variantId!.hashCode) +
    (substitutionIds.hashCode) +
    (cookedOn.hashCode) +
    (mealType.hashCode) +
    (eaterMemberIds.hashCode) +
    (servings.hashCode) +
    (feedback == null ? 0 : feedback!.hashCode);

  @override
  String toString() => 'CookedMealInput[recipeId=$recipeId, recipeVersion=$recipeVersion, adaptationId=$adaptationId, variantId=$variantId, substitutionIds=$substitutionIds, cookedOn=$cookedOn, mealType=$mealType, eaterMemberIds=$eaterMemberIds, servings=$servings, feedback=$feedback]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'recipeId'] = this.recipeId;
      json[r'recipeVersion'] = this.recipeVersion;
    if (this.adaptationId != null) {
      json[r'adaptationId'] = this.adaptationId;
    } else {
      json[r'adaptationId'] = null;
    }
    if (this.variantId != null) {
      json[r'variantId'] = this.variantId;
    } else {
      json[r'variantId'] = null;
    }
      json[r'substitutionIds'] = this.substitutionIds.toList(growable: false);
      json[r'cookedOn'] = _dateFormatter.format(this.cookedOn);
      json[r'mealType'] = this.mealType;
      json[r'eaterMemberIds'] = this.eaterMemberIds.toList(growable: false);
      json[r'servings'] = this.servings;
    if (this.feedback != null) {
      json[r'feedback'] = this.feedback;
    } else {
      json[r'feedback'] = null;
    }
    return json;
  }

  /// Clones this instance of [CookedMealInput] and returns a new one where some of the
  /// properties have changed.
  CookedMealInput copyWith({
    String? recipeId,
    int? recipeVersion,
    String? adaptationId,
    bool adaptationIdSetToNull = false,
    String? variantId,
    bool variantIdSetToNull = false,
    Set<String>? substitutionIds,
    DateTime? cookedOn,
    MealType? mealType,
    Set<String>? eaterMemberIds,
    int? servings,
    MealFeedbackInput? feedback,
    bool feedbackSetToNull = false,
  }) => CookedMealInput(
    recipeId: recipeId ?? this.recipeId,
    recipeVersion: recipeVersion ?? this.recipeVersion,
    adaptationId: adaptationIdSetToNull ? null : adaptationId ?? this.adaptationId,
    variantId: variantIdSetToNull ? null : variantId ?? this.variantId,
    substitutionIds: substitutionIds ?? this.substitutionIds,
    cookedOn: cookedOn ?? this.cookedOn,
    mealType: mealType ?? this.mealType,
    eaterMemberIds: eaterMemberIds ?? this.eaterMemberIds,
    servings: servings ?? this.servings,
    feedback: feedbackSetToNull ? null : feedback ?? this.feedback,
  );

  /// Returns a new [CookedMealInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CookedMealInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'recipeId'), 'Required key "CookedMealInput[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "CookedMealInput[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'recipeVersion'), 'Required key "CookedMealInput[recipeVersion]" is missing from JSON.');
        assert(json[r'recipeVersion'] != null, 'Required key "CookedMealInput[recipeVersion]" has a null value in JSON.');
        assert(json.containsKey(r'adaptationId'), 'Required key "CookedMealInput[adaptationId]" is missing from JSON.');
        assert(json.containsKey(r'variantId'), 'Required key "CookedMealInput[variantId]" is missing from JSON.');
        assert(json.containsKey(r'substitutionIds'), 'Required key "CookedMealInput[substitutionIds]" is missing from JSON.');
        assert(json[r'substitutionIds'] != null, 'Required key "CookedMealInput[substitutionIds]" has a null value in JSON.');
        assert(json.containsKey(r'cookedOn'), 'Required key "CookedMealInput[cookedOn]" is missing from JSON.');
        assert(json[r'cookedOn'] != null, 'Required key "CookedMealInput[cookedOn]" has a null value in JSON.');
        assert(json.containsKey(r'mealType'), 'Required key "CookedMealInput[mealType]" is missing from JSON.');
        assert(json[r'mealType'] != null, 'Required key "CookedMealInput[mealType]" has a null value in JSON.');
        assert(json.containsKey(r'eaterMemberIds'), 'Required key "CookedMealInput[eaterMemberIds]" is missing from JSON.');
        assert(json[r'eaterMemberIds'] != null, 'Required key "CookedMealInput[eaterMemberIds]" has a null value in JSON.');
        assert(json.containsKey(r'servings'), 'Required key "CookedMealInput[servings]" is missing from JSON.');
        assert(json[r'servings'] != null, 'Required key "CookedMealInput[servings]" has a null value in JSON.');
        assert(json.containsKey(r'feedback'), 'Required key "CookedMealInput[feedback]" is missing from JSON.');
        return true;
      }());

      return CookedMealInput(
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        recipeVersion: mapValueOfType<int>(json, r'recipeVersion')!,
        adaptationId: mapValueOfType<String>(json, r'adaptationId'),
        variantId: mapValueOfType<String>(json, r'variantId'),
        substitutionIds: json[r'substitutionIds'] is Iterable
            ? (json[r'substitutionIds'] as Iterable).cast<String>().toSet()
            : const {},
        cookedOn: mapDateTime(json, r'cookedOn', r'')!,
        mealType: MealType.fromJson(json[r'mealType'])!,
        eaterMemberIds: json[r'eaterMemberIds'] is Iterable
            ? (json[r'eaterMemberIds'] as Iterable).cast<String>().toSet()
            : const {},
        servings: mapValueOfType<int>(json, r'servings')!,
        feedback: MealFeedbackInput.fromJson(json[r'feedback']),
      );
    }
    return null;
  }

  static List<CookedMealInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CookedMealInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CookedMealInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CookedMealInput> mapFromJson(dynamic json) {
    final map = <String, CookedMealInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CookedMealInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CookedMealInput-objects as value to a dart map
  static Map<String, List<CookedMealInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CookedMealInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CookedMealInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'recipeId',
    'recipeVersion',
    'adaptationId',
    'variantId',
    'substitutionIds',
    'cookedOn',
    'mealType',
    'eaterMemberIds',
    'servings',
    'feedback',
  };
}

