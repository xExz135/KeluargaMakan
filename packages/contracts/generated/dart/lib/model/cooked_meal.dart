//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class CookedMeal {
  /// Returns a new [CookedMeal] instance.
  CookedMeal({
    required this.id,
    required this.recipeId,
    required this.recipeVersion,
    required this.adaptationId,
    required this.variantId,
    this.substitutionIds = const [],
    required this.cookedOn,
    required this.mealType,
    this.eaterMemberIds = const [],
    required this.servings,
    required this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// Identifier of a reference ingredient or library dish.
  final String recipeId;

  /// Minimum value: 1
  final int recipeVersion;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? adaptationId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? variantId;

  final List<String> substitutionIds;

  final DateTime cookedOn;

  final MealType mealType;

  final List<String> eaterMemberIds;

  /// Minimum value: 1
  final int servings;

  final MealFeedbackInput? feedback;

  final DateTime createdAt;

  final DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CookedMeal &&
    other.id == id &&
    other.recipeId == recipeId &&
    other.recipeVersion == recipeVersion &&
    other.adaptationId == adaptationId &&
    other.variantId == variantId &&
    _deepEquality.equals(other.substitutionIds, substitutionIds) &&
    other.cookedOn == cookedOn &&
    other.mealType == mealType &&
    _deepEquality.equals(other.eaterMemberIds, eaterMemberIds) &&
    other.servings == servings &&
    other.feedback == feedback &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (recipeId.hashCode) +
    (recipeVersion.hashCode) +
    (adaptationId == null ? 0 : adaptationId!.hashCode) +
    (variantId == null ? 0 : variantId!.hashCode) +
    (substitutionIds.hashCode) +
    (cookedOn.hashCode) +
    (mealType.hashCode) +
    (eaterMemberIds.hashCode) +
    (servings.hashCode) +
    (feedback == null ? 0 : feedback!.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'CookedMeal[id=$id, recipeId=$recipeId, recipeVersion=$recipeVersion, adaptationId=$adaptationId, variantId=$variantId, substitutionIds=$substitutionIds, cookedOn=$cookedOn, mealType=$mealType, eaterMemberIds=$eaterMemberIds, servings=$servings, feedback=$feedback, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
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
      json[r'substitutionIds'] = this.substitutionIds;
      json[r'cookedOn'] = _dateFormatter.format(this.cookedOn);
      json[r'mealType'] = this.mealType;
      json[r'eaterMemberIds'] = this.eaterMemberIds;
      json[r'servings'] = this.servings;
    if (this.feedback != null) {
      json[r'feedback'] = this.feedback;
    } else {
      json[r'feedback'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [CookedMeal] and returns a new one where some of the
  /// properties have changed.
  CookedMeal copyWith({
    String? id,
    String? recipeId,
    int? recipeVersion,
    String? adaptationId,
    bool adaptationIdSetToNull = false,
    String? variantId,
    bool variantIdSetToNull = false,
    List<String>? substitutionIds,
    DateTime? cookedOn,
    MealType? mealType,
    List<String>? eaterMemberIds,
    int? servings,
    MealFeedbackInput? feedback,
    bool feedbackSetToNull = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CookedMeal(
    id: id ?? this.id,
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
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a new [CookedMeal] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CookedMeal? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "CookedMeal[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "CookedMeal[id]" has a null value in JSON.');
        assert(json.containsKey(r'recipeId'), 'Required key "CookedMeal[recipeId]" is missing from JSON.');
        assert(json[r'recipeId'] != null, 'Required key "CookedMeal[recipeId]" has a null value in JSON.');
        assert(json.containsKey(r'recipeVersion'), 'Required key "CookedMeal[recipeVersion]" is missing from JSON.');
        assert(json[r'recipeVersion'] != null, 'Required key "CookedMeal[recipeVersion]" has a null value in JSON.');
        assert(json.containsKey(r'adaptationId'), 'Required key "CookedMeal[adaptationId]" is missing from JSON.');
        assert(json.containsKey(r'variantId'), 'Required key "CookedMeal[variantId]" is missing from JSON.');
        assert(json.containsKey(r'substitutionIds'), 'Required key "CookedMeal[substitutionIds]" is missing from JSON.');
        assert(json[r'substitutionIds'] != null, 'Required key "CookedMeal[substitutionIds]" has a null value in JSON.');
        assert(json.containsKey(r'cookedOn'), 'Required key "CookedMeal[cookedOn]" is missing from JSON.');
        assert(json[r'cookedOn'] != null, 'Required key "CookedMeal[cookedOn]" has a null value in JSON.');
        assert(json.containsKey(r'mealType'), 'Required key "CookedMeal[mealType]" is missing from JSON.');
        assert(json[r'mealType'] != null, 'Required key "CookedMeal[mealType]" has a null value in JSON.');
        assert(json.containsKey(r'eaterMemberIds'), 'Required key "CookedMeal[eaterMemberIds]" is missing from JSON.');
        assert(json[r'eaterMemberIds'] != null, 'Required key "CookedMeal[eaterMemberIds]" has a null value in JSON.');
        assert(json.containsKey(r'servings'), 'Required key "CookedMeal[servings]" is missing from JSON.');
        assert(json[r'servings'] != null, 'Required key "CookedMeal[servings]" has a null value in JSON.');
        assert(json.containsKey(r'feedback'), 'Required key "CookedMeal[feedback]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "CookedMeal[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "CookedMeal[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "CookedMeal[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "CookedMeal[updatedAt]" has a null value in JSON.');
        return true;
      }());

      return CookedMeal(
        id: mapValueOfType<String>(json, r'id')!,
        recipeId: mapValueOfType<String>(json, r'recipeId')!,
        recipeVersion: mapValueOfType<int>(json, r'recipeVersion')!,
        adaptationId: mapValueOfType<String>(json, r'adaptationId'),
        variantId: mapValueOfType<String>(json, r'variantId'),
        substitutionIds: json[r'substitutionIds'] is Iterable
            ? (json[r'substitutionIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        cookedOn: mapDateTime(json, r'cookedOn', r'')!,
        mealType: MealType.fromJson(json[r'mealType'])!,
        eaterMemberIds: json[r'eaterMemberIds'] is Iterable
            ? (json[r'eaterMemberIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        servings: mapValueOfType<int>(json, r'servings')!,
        feedback: MealFeedbackInput.fromJson(json[r'feedback']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<CookedMeal> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CookedMeal>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CookedMeal.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CookedMeal> mapFromJson(dynamic json) {
    final map = <String, CookedMeal>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CookedMeal.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CookedMeal-objects as value to a dart map
  static Map<String, List<CookedMeal>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CookedMeal>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CookedMeal.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
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
    'createdAt',
    'updatedAt',
  };
}

