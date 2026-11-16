//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyIngredientRef {
  /// Returns a new [SafetyIngredientRef] instance.
  SafetyIngredientRef({
    required this.lineId,
    required this.ingredientId,
    required this.displayName,
    required this.rawName,
    required this.isCustom,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String? lineId;

  /// Identifier of a reference ingredient or library dish.
  final String? ingredientId;

  final LocalizedText? displayName;

  final String rawName;

  /// A custom ingredient from Dapur Saya (KIT-05); shown with the custom-ingredient reason.
  final bool isCustom;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyIngredientRef &&
    other.lineId == lineId &&
    other.ingredientId == ingredientId &&
    other.displayName == displayName &&
    other.rawName == rawName &&
    other.isCustom == isCustom;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lineId == null ? 0 : lineId!.hashCode) +
    (ingredientId == null ? 0 : ingredientId!.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (rawName.hashCode) +
    (isCustom.hashCode);

  @override
  String toString() => 'SafetyIngredientRef[lineId=$lineId, ingredientId=$ingredientId, displayName=$displayName, rawName=$rawName, isCustom=$isCustom]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.lineId != null) {
      json[r'lineId'] = this.lineId;
    } else {
      json[r'lineId'] = null;
    }
    if (this.ingredientId != null) {
      json[r'ingredientId'] = this.ingredientId;
    } else {
      json[r'ingredientId'] = null;
    }
    if (this.displayName != null) {
      json[r'displayName'] = this.displayName;
    } else {
      json[r'displayName'] = null;
    }
      json[r'rawName'] = this.rawName;
      json[r'isCustom'] = this.isCustom;
    return json;
  }

  /// Clones this instance of [SafetyIngredientRef] and returns a new one where some of the
  /// properties have changed.
  SafetyIngredientRef copyWith({
    String? lineId,
    bool lineIdSetToNull = false,
    String? ingredientId,
    bool ingredientIdSetToNull = false,
    LocalizedText? displayName,
    bool displayNameSetToNull = false,
    String? rawName,
    bool? isCustom,
  }) => SafetyIngredientRef(
    lineId: lineIdSetToNull ? null : lineId ?? this.lineId,
    ingredientId: ingredientIdSetToNull ? null : ingredientId ?? this.ingredientId,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    rawName: rawName ?? this.rawName,
    isCustom: isCustom ?? this.isCustom,
  );

  /// Returns a new [SafetyIngredientRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyIngredientRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'lineId'), 'Required key "SafetyIngredientRef[lineId]" is missing from JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "SafetyIngredientRef[ingredientId]" is missing from JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "SafetyIngredientRef[displayName]" is missing from JSON.');
        assert(json.containsKey(r'rawName'), 'Required key "SafetyIngredientRef[rawName]" is missing from JSON.');
        assert(json[r'rawName'] != null, 'Required key "SafetyIngredientRef[rawName]" has a null value in JSON.');
        assert(json.containsKey(r'isCustom'), 'Required key "SafetyIngredientRef[isCustom]" is missing from JSON.');
        assert(json[r'isCustom'] != null, 'Required key "SafetyIngredientRef[isCustom]" has a null value in JSON.');
        return true;
      }());

      return SafetyIngredientRef(
        lineId: mapValueOfType<String>(json, r'lineId'),
        ingredientId: mapValueOfType<String>(json, r'ingredientId'),
        displayName: LocalizedText.fromJson(json[r'displayName']),
        rawName: mapValueOfType<String>(json, r'rawName')!,
        isCustom: mapValueOfType<bool>(json, r'isCustom')!,
      );
    }
    return null;
  }

  static List<SafetyIngredientRef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyIngredientRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyIngredientRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyIngredientRef> mapFromJson(dynamic json) {
    final map = <String, SafetyIngredientRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyIngredientRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyIngredientRef-objects as value to a dart map
  static Map<String, List<SafetyIngredientRef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyIngredientRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyIngredientRef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lineId',
    'ingredientId',
    'displayName',
    'rawName',
    'isCustom',
  };
}

