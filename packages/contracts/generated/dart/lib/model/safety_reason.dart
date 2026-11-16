//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyReason {
  /// Returns a new [SafetyReason] instance.
  SafetyReason({
    required this.kind,
    required this.code,
    required this.rule,
    required this.ingredient,
    this.componentPath = const [],
    required this.brand,
    required this.detail,
  });

  final SafetyReasonKind kind;

  final SafetyReasonCode code;

  final SafetyRuleRef rule;

  final SafetyIngredientRef? ingredient;

  final List<SafetyComponentRef> componentPath;

  final SafetyBrandRef? brand;

  final String? detail;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyReason &&
    other.kind == kind &&
    other.code == code &&
    other.rule == rule &&
    other.ingredient == ingredient &&
    _deepEquality.equals(other.componentPath, componentPath) &&
    other.brand == brand &&
    other.detail == detail;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (code.hashCode) +
    (rule.hashCode) +
    (ingredient == null ? 0 : ingredient!.hashCode) +
    (componentPath.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (detail == null ? 0 : detail!.hashCode);

  @override
  String toString() => 'SafetyReason[kind=$kind, code=$code, rule=$rule, ingredient=$ingredient, componentPath=$componentPath, brand=$brand, detail=$detail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'code'] = this.code;
      json[r'rule'] = this.rule;
    if (this.ingredient != null) {
      json[r'ingredient'] = this.ingredient;
    } else {
      json[r'ingredient'] = null;
    }
      json[r'componentPath'] = this.componentPath;
    if (this.brand != null) {
      json[r'brand'] = this.brand;
    } else {
      json[r'brand'] = null;
    }
    if (this.detail != null) {
      json[r'detail'] = this.detail;
    } else {
      json[r'detail'] = null;
    }
    return json;
  }

  /// Clones this instance of [SafetyReason] and returns a new one where some of the
  /// properties have changed.
  SafetyReason copyWith({
    SafetyReasonKind? kind,
    SafetyReasonCode? code,
    SafetyRuleRef? rule,
    SafetyIngredientRef? ingredient,
    bool ingredientSetToNull = false,
    List<SafetyComponentRef>? componentPath,
    SafetyBrandRef? brand,
    bool brandSetToNull = false,
    String? detail,
    bool detailSetToNull = false,
  }) => SafetyReason(
    kind: kind ?? this.kind,
    code: code ?? this.code,
    rule: rule ?? this.rule,
    ingredient: ingredientSetToNull ? null : ingredient ?? this.ingredient,
    componentPath: componentPath ?? this.componentPath,
    brand: brandSetToNull ? null : brand ?? this.brand,
    detail: detailSetToNull ? null : detail ?? this.detail,
  );

  /// Returns a new [SafetyReason] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyReason? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "SafetyReason[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "SafetyReason[kind]" has a null value in JSON.');
        assert(json.containsKey(r'code'), 'Required key "SafetyReason[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "SafetyReason[code]" has a null value in JSON.');
        assert(json.containsKey(r'rule'), 'Required key "SafetyReason[rule]" is missing from JSON.');
        assert(json[r'rule'] != null, 'Required key "SafetyReason[rule]" has a null value in JSON.');
        assert(json.containsKey(r'ingredient'), 'Required key "SafetyReason[ingredient]" is missing from JSON.');
        assert(json.containsKey(r'componentPath'), 'Required key "SafetyReason[componentPath]" is missing from JSON.');
        assert(json[r'componentPath'] != null, 'Required key "SafetyReason[componentPath]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "SafetyReason[brand]" is missing from JSON.');
        assert(json.containsKey(r'detail'), 'Required key "SafetyReason[detail]" is missing from JSON.');
        return true;
      }());

      return SafetyReason(
        kind: SafetyReasonKind.fromJson(json[r'kind'])!,
        code: SafetyReasonCode.fromJson(json[r'code'])!,
        rule: SafetyRuleRef.fromJson(json[r'rule'])!,
        ingredient: SafetyIngredientRef.fromJson(json[r'ingredient']),
        componentPath: SafetyComponentRef.listFromJson(json[r'componentPath']),
        brand: SafetyBrandRef.fromJson(json[r'brand']),
        detail: mapValueOfType<String>(json, r'detail'),
      );
    }
    return null;
  }

  static List<SafetyReason> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyReason> mapFromJson(dynamic json) {
    final map = <String, SafetyReason>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyReason.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyReason-objects as value to a dart map
  static Map<String, List<SafetyReason>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyReason>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyReason.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'code',
    'rule',
    'ingredient',
    'componentPath',
    'brand',
    'detail',
  };
}

