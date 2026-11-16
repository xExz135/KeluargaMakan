//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientQuantity {
  /// Returns a new [IngredientQuantity] instance.
  IngredientQuantity({
    required this.amount,
    required this.unitCode,
    required this.unitLabel,
  });

  /// Minimum value: 0
  final num? amount;

  final String? unitCode;

  final LocalizedText? unitLabel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientQuantity &&
    other.amount == amount &&
    other.unitCode == unitCode &&
    other.unitLabel == unitLabel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amount == null ? 0 : amount!.hashCode) +
    (unitCode == null ? 0 : unitCode!.hashCode) +
    (unitLabel == null ? 0 : unitLabel!.hashCode);

  @override
  String toString() => 'IngredientQuantity[amount=$amount, unitCode=$unitCode, unitLabel=$unitLabel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    if (this.unitCode != null) {
      json[r'unitCode'] = this.unitCode;
    } else {
      json[r'unitCode'] = null;
    }
    if (this.unitLabel != null) {
      json[r'unitLabel'] = this.unitLabel;
    } else {
      json[r'unitLabel'] = null;
    }
    return json;
  }

  /// Clones this instance of [IngredientQuantity] and returns a new one where some of the
  /// properties have changed.
  IngredientQuantity copyWith({
    num? amount,
    bool amountSetToNull = false,
    String? unitCode,
    bool unitCodeSetToNull = false,
    LocalizedText? unitLabel,
    bool unitLabelSetToNull = false,
  }) => IngredientQuantity(
    amount: amountSetToNull ? null : amount ?? this.amount,
    unitCode: unitCodeSetToNull ? null : unitCode ?? this.unitCode,
    unitLabel: unitLabelSetToNull ? null : unitLabel ?? this.unitLabel,
  );

  /// Returns a new [IngredientQuantity] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientQuantity? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'amount'), 'Required key "IngredientQuantity[amount]" is missing from JSON.');
        assert(json.containsKey(r'unitCode'), 'Required key "IngredientQuantity[unitCode]" is missing from JSON.');
        assert(json.containsKey(r'unitLabel'), 'Required key "IngredientQuantity[unitLabel]" is missing from JSON.');
        return true;
      }());

      return IngredientQuantity(
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
        unitCode: mapValueOfType<String>(json, r'unitCode'),
        unitLabel: LocalizedText.fromJson(json[r'unitLabel']),
      );
    }
    return null;
  }

  static List<IngredientQuantity> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientQuantity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientQuantity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientQuantity> mapFromJson(dynamic json) {
    final map = <String, IngredientQuantity>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientQuantity.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientQuantity-objects as value to a dart map
  static Map<String, List<IngredientQuantity>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientQuantity>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientQuantity.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'unitCode',
    'unitLabel',
  };
}

