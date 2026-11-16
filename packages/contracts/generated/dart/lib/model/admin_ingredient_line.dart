//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminIngredientLine {
  /// Returns a new [AdminIngredientLine] instance.
  AdminIngredientLine({
    required this.lineId,
    required this.ingredientId,
    required this.rawName,
    required this.quantity,
    required this.isOptional,
    required this.groupLabel,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String lineId;

  /// Identifier of a reference ingredient or library dish.
  final String? ingredientId;

  final String rawName;

  final IngredientQuantity quantity;

  final bool isOptional;

  final LocalizedText? groupLabel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminIngredientLine &&
    other.lineId == lineId &&
    other.ingredientId == ingredientId &&
    other.rawName == rawName &&
    other.quantity == quantity &&
    other.isOptional == isOptional &&
    other.groupLabel == groupLabel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lineId.hashCode) +
    (ingredientId == null ? 0 : ingredientId!.hashCode) +
    (rawName.hashCode) +
    (quantity.hashCode) +
    (isOptional.hashCode) +
    (groupLabel == null ? 0 : groupLabel!.hashCode);

  @override
  String toString() => 'AdminIngredientLine[lineId=$lineId, ingredientId=$ingredientId, rawName=$rawName, quantity=$quantity, isOptional=$isOptional, groupLabel=$groupLabel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lineId'] = this.lineId;
    if (this.ingredientId != null) {
      json[r'ingredientId'] = this.ingredientId;
    } else {
      json[r'ingredientId'] = null;
    }
      json[r'rawName'] = this.rawName;
      json[r'quantity'] = this.quantity;
      json[r'isOptional'] = this.isOptional;
    if (this.groupLabel != null) {
      json[r'groupLabel'] = this.groupLabel;
    } else {
      json[r'groupLabel'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdminIngredientLine] and returns a new one where some of the
  /// properties have changed.
  AdminIngredientLine copyWith({
    String? lineId,
    String? ingredientId,
    bool ingredientIdSetToNull = false,
    String? rawName,
    IngredientQuantity? quantity,
    bool? isOptional,
    LocalizedText? groupLabel,
    bool groupLabelSetToNull = false,
  }) => AdminIngredientLine(
    lineId: lineId ?? this.lineId,
    ingredientId: ingredientIdSetToNull ? null : ingredientId ?? this.ingredientId,
    rawName: rawName ?? this.rawName,
    quantity: quantity ?? this.quantity,
    isOptional: isOptional ?? this.isOptional,
    groupLabel: groupLabelSetToNull ? null : groupLabel ?? this.groupLabel,
  );

  /// Returns a new [AdminIngredientLine] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminIngredientLine? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'lineId'), 'Required key "AdminIngredientLine[lineId]" is missing from JSON.');
        assert(json[r'lineId'] != null, 'Required key "AdminIngredientLine[lineId]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "AdminIngredientLine[ingredientId]" is missing from JSON.');
        assert(json.containsKey(r'rawName'), 'Required key "AdminIngredientLine[rawName]" is missing from JSON.');
        assert(json[r'rawName'] != null, 'Required key "AdminIngredientLine[rawName]" has a null value in JSON.');
        assert(json.containsKey(r'quantity'), 'Required key "AdminIngredientLine[quantity]" is missing from JSON.');
        assert(json[r'quantity'] != null, 'Required key "AdminIngredientLine[quantity]" has a null value in JSON.');
        assert(json.containsKey(r'isOptional'), 'Required key "AdminIngredientLine[isOptional]" is missing from JSON.');
        assert(json[r'isOptional'] != null, 'Required key "AdminIngredientLine[isOptional]" has a null value in JSON.');
        assert(json.containsKey(r'groupLabel'), 'Required key "AdminIngredientLine[groupLabel]" is missing from JSON.');
        return true;
      }());

      return AdminIngredientLine(
        lineId: mapValueOfType<String>(json, r'lineId')!,
        ingredientId: mapValueOfType<String>(json, r'ingredientId'),
        rawName: mapValueOfType<String>(json, r'rawName')!,
        quantity: IngredientQuantity.fromJson(json[r'quantity'])!,
        isOptional: mapValueOfType<bool>(json, r'isOptional')!,
        groupLabel: LocalizedText.fromJson(json[r'groupLabel']),
      );
    }
    return null;
  }

  static List<AdminIngredientLine> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminIngredientLine>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminIngredientLine.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminIngredientLine> mapFromJson(dynamic json) {
    final map = <String, AdminIngredientLine>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminIngredientLine.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminIngredientLine-objects as value to a dart map
  static Map<String, List<AdminIngredientLine>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminIngredientLine>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminIngredientLine.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lineId',
    'ingredientId',
    'rawName',
    'quantity',
    'isOptional',
    'groupLabel',
  };
}

