//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class NutritionPerServing {
  /// Returns a new [NutritionPerServing] instance.
  NutritionPerServing({
    required this.status,
    this.ranges = const [],
  });

  final NutritionStatus status;

  final List<NutrientRange> ranges;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NutritionPerServing &&
    other.status == status &&
    _deepEquality.equals(other.ranges, ranges);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (ranges.hashCode);

  @override
  String toString() => 'NutritionPerServing[status=$status, ranges=$ranges]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
      json[r'ranges'] = this.ranges;
    return json;
  }

  /// Clones this instance of [NutritionPerServing] and returns a new one where some of the
  /// properties have changed.
  NutritionPerServing copyWith({
    NutritionStatus? status,
    List<NutrientRange>? ranges,
  }) => NutritionPerServing(
    status: status ?? this.status,
    ranges: ranges ?? this.ranges,
  );

  /// Returns a new [NutritionPerServing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NutritionPerServing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'), 'Required key "NutritionPerServing[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "NutritionPerServing[status]" has a null value in JSON.');
        assert(json.containsKey(r'ranges'), 'Required key "NutritionPerServing[ranges]" is missing from JSON.');
        assert(json[r'ranges'] != null, 'Required key "NutritionPerServing[ranges]" has a null value in JSON.');
        return true;
      }());

      return NutritionPerServing(
        status: NutritionStatus.fromJson(json[r'status'])!,
        ranges: NutrientRange.listFromJson(json[r'ranges']),
      );
    }
    return null;
  }

  static List<NutritionPerServing> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NutritionPerServing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NutritionPerServing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NutritionPerServing> mapFromJson(dynamic json) {
    final map = <String, NutritionPerServing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NutritionPerServing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NutritionPerServing-objects as value to a dart map
  static Map<String, List<NutritionPerServing>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NutritionPerServing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NutritionPerServing.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'ranges',
  };
}

