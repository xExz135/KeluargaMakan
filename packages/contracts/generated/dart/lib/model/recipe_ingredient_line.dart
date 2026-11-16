//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeIngredientLine {
  /// Returns a new [RecipeIngredientLine] instance.
  RecipeIngredientLine({
    required this.lineId,
    required this.ingredientId,
    required this.displayName,
    required this.rawName,
    required this.quantity,
    required this.isOptional,
    required this.groupLabel,
    required this.inKitchen,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String lineId;

  /// Identifier of a reference ingredient or library dish.
  final String? ingredientId;

  final LocalizedText? displayName;

  /// The name as written in the recipe.
  final String rawName;

  final IngredientQuantity quantity;

  final bool isOptional;

  /// A group heading such as \"Bumbu halus\", or null.
  final LocalizedText? groupLabel;

  final KitchenAvailability inKitchen;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeIngredientLine &&
    other.lineId == lineId &&
    other.ingredientId == ingredientId &&
    other.displayName == displayName &&
    other.rawName == rawName &&
    other.quantity == quantity &&
    other.isOptional == isOptional &&
    other.groupLabel == groupLabel &&
    other.inKitchen == inKitchen;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lineId.hashCode) +
    (ingredientId == null ? 0 : ingredientId!.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (rawName.hashCode) +
    (quantity.hashCode) +
    (isOptional.hashCode) +
    (groupLabel == null ? 0 : groupLabel!.hashCode) +
    (inKitchen.hashCode);

  @override
  String toString() => 'RecipeIngredientLine[lineId=$lineId, ingredientId=$ingredientId, displayName=$displayName, rawName=$rawName, quantity=$quantity, isOptional=$isOptional, groupLabel=$groupLabel, inKitchen=$inKitchen]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lineId'] = this.lineId;
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
      json[r'quantity'] = this.quantity;
      json[r'isOptional'] = this.isOptional;
    if (this.groupLabel != null) {
      json[r'groupLabel'] = this.groupLabel;
    } else {
      json[r'groupLabel'] = null;
    }
      json[r'inKitchen'] = this.inKitchen;
    return json;
  }

  /// Clones this instance of [RecipeIngredientLine] and returns a new one where some of the
  /// properties have changed.
  RecipeIngredientLine copyWith({
    String? lineId,
    String? ingredientId,
    bool ingredientIdSetToNull = false,
    LocalizedText? displayName,
    bool displayNameSetToNull = false,
    String? rawName,
    IngredientQuantity? quantity,
    bool? isOptional,
    LocalizedText? groupLabel,
    bool groupLabelSetToNull = false,
    KitchenAvailability? inKitchen,
  }) => RecipeIngredientLine(
    lineId: lineId ?? this.lineId,
    ingredientId: ingredientIdSetToNull ? null : ingredientId ?? this.ingredientId,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    rawName: rawName ?? this.rawName,
    quantity: quantity ?? this.quantity,
    isOptional: isOptional ?? this.isOptional,
    groupLabel: groupLabelSetToNull ? null : groupLabel ?? this.groupLabel,
    inKitchen: inKitchen ?? this.inKitchen,
  );

  /// Returns a new [RecipeIngredientLine] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeIngredientLine? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'lineId'), 'Required key "RecipeIngredientLine[lineId]" is missing from JSON.');
        assert(json[r'lineId'] != null, 'Required key "RecipeIngredientLine[lineId]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "RecipeIngredientLine[ingredientId]" is missing from JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "RecipeIngredientLine[displayName]" is missing from JSON.');
        assert(json.containsKey(r'rawName'), 'Required key "RecipeIngredientLine[rawName]" is missing from JSON.');
        assert(json[r'rawName'] != null, 'Required key "RecipeIngredientLine[rawName]" has a null value in JSON.');
        assert(json.containsKey(r'quantity'), 'Required key "RecipeIngredientLine[quantity]" is missing from JSON.');
        assert(json[r'quantity'] != null, 'Required key "RecipeIngredientLine[quantity]" has a null value in JSON.');
        assert(json.containsKey(r'isOptional'), 'Required key "RecipeIngredientLine[isOptional]" is missing from JSON.');
        assert(json[r'isOptional'] != null, 'Required key "RecipeIngredientLine[isOptional]" has a null value in JSON.');
        assert(json.containsKey(r'groupLabel'), 'Required key "RecipeIngredientLine[groupLabel]" is missing from JSON.');
        assert(json.containsKey(r'inKitchen'), 'Required key "RecipeIngredientLine[inKitchen]" is missing from JSON.');
        assert(json[r'inKitchen'] != null, 'Required key "RecipeIngredientLine[inKitchen]" has a null value in JSON.');
        return true;
      }());

      return RecipeIngredientLine(
        lineId: mapValueOfType<String>(json, r'lineId')!,
        ingredientId: mapValueOfType<String>(json, r'ingredientId'),
        displayName: LocalizedText.fromJson(json[r'displayName']),
        rawName: mapValueOfType<String>(json, r'rawName')!,
        quantity: IngredientQuantity.fromJson(json[r'quantity'])!,
        isOptional: mapValueOfType<bool>(json, r'isOptional')!,
        groupLabel: LocalizedText.fromJson(json[r'groupLabel']),
        inKitchen: KitchenAvailability.fromJson(json[r'inKitchen'])!,
      );
    }
    return null;
  }

  static List<RecipeIngredientLine> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeIngredientLine>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeIngredientLine.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeIngredientLine> mapFromJson(dynamic json) {
    final map = <String, RecipeIngredientLine>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeIngredientLine.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeIngredientLine-objects as value to a dart map
  static Map<String, List<RecipeIngredientLine>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeIngredientLine>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeIngredientLine.listFromJson(entry.value, growable: growable,);
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
    'quantity',
    'isOptional',
    'groupLabel',
    'inKitchen',
  };
}

