//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class StandardAllergenList {
  /// Returns a new [StandardAllergenList] instance.
  StandardAllergenList({
    required this.ruleSetVersion,
    this.items = const [],
  });

  /// Cek Aman rule-set version the list comes from (DAT-06).
  final String ruleSetVersion;

  /// Display order (PRF-04).
  final List<StandardAllergen> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StandardAllergenList &&
    other.ruleSetVersion == ruleSetVersion &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ruleSetVersion.hashCode) +
    (items.hashCode);

  @override
  String toString() => 'StandardAllergenList[ruleSetVersion=$ruleSetVersion, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ruleSetVersion'] = this.ruleSetVersion;
      json[r'items'] = this.items;
    return json;
  }

  /// Clones this instance of [StandardAllergenList] and returns a new one where some of the
  /// properties have changed.
  StandardAllergenList copyWith({
    String? ruleSetVersion,
    List<StandardAllergen>? items,
  }) => StandardAllergenList(
    ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
    items: items ?? this.items,
  );

  /// Returns a new [StandardAllergenList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StandardAllergenList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ruleSetVersion'), 'Required key "StandardAllergenList[ruleSetVersion]" is missing from JSON.');
        assert(json[r'ruleSetVersion'] != null, 'Required key "StandardAllergenList[ruleSetVersion]" has a null value in JSON.');
        assert(json.containsKey(r'items'), 'Required key "StandardAllergenList[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "StandardAllergenList[items]" has a null value in JSON.');
        return true;
      }());

      return StandardAllergenList(
        ruleSetVersion: mapValueOfType<String>(json, r'ruleSetVersion')!,
        items: StandardAllergen.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<StandardAllergenList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StandardAllergenList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StandardAllergenList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StandardAllergenList> mapFromJson(dynamic json) {
    final map = <String, StandardAllergenList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StandardAllergenList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StandardAllergenList-objects as value to a dart map
  static Map<String, List<StandardAllergenList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StandardAllergenList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StandardAllergenList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ruleSetVersion',
    'items',
  };
}

