//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class NutrientRange {
  /// Returns a new [NutrientRange] instance.
  NutrientRange({
    required this.nutrient,
    required this.low,
    required this.high,
    required this.unit,
  });

  final NutrientCode nutrient;

  /// Minimum value: 0
  final num low;

  /// Minimum value: 0
  final num high;

  final NutrientUnit unit;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NutrientRange &&
    other.nutrient == nutrient &&
    other.low == low &&
    other.high == high &&
    other.unit == unit;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (nutrient.hashCode) +
    (low.hashCode) +
    (high.hashCode) +
    (unit.hashCode);

  @override
  String toString() => 'NutrientRange[nutrient=$nutrient, low=$low, high=$high, unit=$unit]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'nutrient'] = this.nutrient;
      json[r'low'] = this.low;
      json[r'high'] = this.high;
      json[r'unit'] = this.unit;
    return json;
  }

  /// Clones this instance of [NutrientRange] and returns a new one where some of the
  /// properties have changed.
  NutrientRange copyWith({
    NutrientCode? nutrient,
    num? low,
    num? high,
    NutrientUnit? unit,
  }) => NutrientRange(
    nutrient: nutrient ?? this.nutrient,
    low: low ?? this.low,
    high: high ?? this.high,
    unit: unit ?? this.unit,
  );

  /// Returns a new [NutrientRange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NutrientRange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'nutrient'), 'Required key "NutrientRange[nutrient]" is missing from JSON.');
        assert(json[r'nutrient'] != null, 'Required key "NutrientRange[nutrient]" has a null value in JSON.');
        assert(json.containsKey(r'low'), 'Required key "NutrientRange[low]" is missing from JSON.');
        assert(json[r'low'] != null, 'Required key "NutrientRange[low]" has a null value in JSON.');
        assert(json.containsKey(r'high'), 'Required key "NutrientRange[high]" is missing from JSON.');
        assert(json[r'high'] != null, 'Required key "NutrientRange[high]" has a null value in JSON.');
        assert(json.containsKey(r'unit'), 'Required key "NutrientRange[unit]" is missing from JSON.');
        assert(json[r'unit'] != null, 'Required key "NutrientRange[unit]" has a null value in JSON.');
        return true;
      }());

      return NutrientRange(
        nutrient: NutrientCode.fromJson(json[r'nutrient'])!,
        low: num.parse('${json[r'low']}'),
        high: num.parse('${json[r'high']}'),
        unit: NutrientUnit.fromJson(json[r'unit'])!,
      );
    }
    return null;
  }

  static List<NutrientRange> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NutrientRange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NutrientRange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NutrientRange> mapFromJson(dynamic json) {
    final map = <String, NutrientRange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NutrientRange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NutrientRange-objects as value to a dart map
  static Map<String, List<NutrientRange>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NutrientRange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NutrientRange.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'nutrient',
    'low',
    'high',
    'unit',
  };
}

