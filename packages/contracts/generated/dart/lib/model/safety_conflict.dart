//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyConflict {
  /// Returns a new [SafetyConflict] instance.
  SafetyConflict({
    required this.memberId,
    required this.rule,
    required this.ingredient,
    this.componentPath = const [],
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String memberId;

  final SafetyRuleRef rule;

  final SafetyIngredientRef ingredient;

  final List<SafetyComponentRef> componentPath;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyConflict &&
    other.memberId == memberId &&
    other.rule == rule &&
    other.ingredient == ingredient &&
    _deepEquality.equals(other.componentPath, componentPath);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memberId.hashCode) +
    (rule.hashCode) +
    (ingredient.hashCode) +
    (componentPath.hashCode);

  @override
  String toString() => 'SafetyConflict[memberId=$memberId, rule=$rule, ingredient=$ingredient, componentPath=$componentPath]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'memberId'] = this.memberId;
      json[r'rule'] = this.rule;
      json[r'ingredient'] = this.ingredient;
      json[r'componentPath'] = this.componentPath;
    return json;
  }

  /// Clones this instance of [SafetyConflict] and returns a new one where some of the
  /// properties have changed.
  SafetyConflict copyWith({
    String? memberId,
    SafetyRuleRef? rule,
    SafetyIngredientRef? ingredient,
    List<SafetyComponentRef>? componentPath,
  }) => SafetyConflict(
    memberId: memberId ?? this.memberId,
    rule: rule ?? this.rule,
    ingredient: ingredient ?? this.ingredient,
    componentPath: componentPath ?? this.componentPath,
  );

  /// Returns a new [SafetyConflict] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyConflict? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'memberId'), 'Required key "SafetyConflict[memberId]" is missing from JSON.');
        assert(json[r'memberId'] != null, 'Required key "SafetyConflict[memberId]" has a null value in JSON.');
        assert(json.containsKey(r'rule'), 'Required key "SafetyConflict[rule]" is missing from JSON.');
        assert(json[r'rule'] != null, 'Required key "SafetyConflict[rule]" has a null value in JSON.');
        assert(json.containsKey(r'ingredient'), 'Required key "SafetyConflict[ingredient]" is missing from JSON.');
        assert(json[r'ingredient'] != null, 'Required key "SafetyConflict[ingredient]" has a null value in JSON.');
        assert(json.containsKey(r'componentPath'), 'Required key "SafetyConflict[componentPath]" is missing from JSON.');
        assert(json[r'componentPath'] != null, 'Required key "SafetyConflict[componentPath]" has a null value in JSON.');
        return true;
      }());

      return SafetyConflict(
        memberId: mapValueOfType<String>(json, r'memberId')!,
        rule: SafetyRuleRef.fromJson(json[r'rule'])!,
        ingredient: SafetyIngredientRef.fromJson(json[r'ingredient'])!,
        componentPath: SafetyComponentRef.listFromJson(json[r'componentPath']),
      );
    }
    return null;
  }

  static List<SafetyConflict> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyConflict>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyConflict.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyConflict> mapFromJson(dynamic json) {
    final map = <String, SafetyConflict>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyConflict.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyConflict-objects as value to a dart map
  static Map<String, List<SafetyConflict>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyConflict>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyConflict.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'memberId',
    'rule',
    'ingredient',
    'componentPath',
  };
}

