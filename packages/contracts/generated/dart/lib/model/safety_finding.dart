//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyFinding {
  /// Returns a new [SafetyFinding] instance.
  SafetyFinding({
    required this.kind,
    required this.code,
    required this.ingredient,
    this.componentPath = const [],
    required this.brand,
    required this.detail,
  });

  final SafetyReasonKind kind;

  final SafetyReasonCode code;

  final SafetyIngredientRef? ingredient;

  final List<SafetyComponentRef> componentPath;

  final SafetyBrandRef? brand;

  final String? detail;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyFinding &&
    other.kind == kind &&
    other.code == code &&
    other.ingredient == ingredient &&
    _deepEquality.equals(other.componentPath, componentPath) &&
    other.brand == brand &&
    other.detail == detail;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (code.hashCode) +
    (ingredient == null ? 0 : ingredient!.hashCode) +
    (componentPath.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (detail == null ? 0 : detail!.hashCode);

  @override
  String toString() => 'SafetyFinding[kind=$kind, code=$code, ingredient=$ingredient, componentPath=$componentPath, brand=$brand, detail=$detail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'code'] = this.code;
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

  /// Clones this instance of [SafetyFinding] and returns a new one where some of the
  /// properties have changed.
  SafetyFinding copyWith({
    SafetyReasonKind? kind,
    SafetyReasonCode? code,
    SafetyIngredientRef? ingredient,
    bool ingredientSetToNull = false,
    List<SafetyComponentRef>? componentPath,
    SafetyBrandRef? brand,
    bool brandSetToNull = false,
    String? detail,
    bool detailSetToNull = false,
  }) => SafetyFinding(
    kind: kind ?? this.kind,
    code: code ?? this.code,
    ingredient: ingredientSetToNull ? null : ingredient ?? this.ingredient,
    componentPath: componentPath ?? this.componentPath,
    brand: brandSetToNull ? null : brand ?? this.brand,
    detail: detailSetToNull ? null : detail ?? this.detail,
  );

  /// Returns a new [SafetyFinding] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyFinding? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "SafetyFinding[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "SafetyFinding[kind]" has a null value in JSON.');
        assert(json.containsKey(r'code'), 'Required key "SafetyFinding[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "SafetyFinding[code]" has a null value in JSON.');
        assert(json.containsKey(r'ingredient'), 'Required key "SafetyFinding[ingredient]" is missing from JSON.');
        assert(json.containsKey(r'componentPath'), 'Required key "SafetyFinding[componentPath]" is missing from JSON.');
        assert(json[r'componentPath'] != null, 'Required key "SafetyFinding[componentPath]" has a null value in JSON.');
        assert(json.containsKey(r'brand'), 'Required key "SafetyFinding[brand]" is missing from JSON.');
        assert(json.containsKey(r'detail'), 'Required key "SafetyFinding[detail]" is missing from JSON.');
        return true;
      }());

      return SafetyFinding(
        kind: SafetyReasonKind.fromJson(json[r'kind'])!,
        code: SafetyReasonCode.fromJson(json[r'code'])!,
        ingredient: SafetyIngredientRef.fromJson(json[r'ingredient']),
        componentPath: SafetyComponentRef.listFromJson(json[r'componentPath']),
        brand: SafetyBrandRef.fromJson(json[r'brand']),
        detail: mapValueOfType<String>(json, r'detail'),
      );
    }
    return null;
  }

  static List<SafetyFinding> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyFinding>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyFinding.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyFinding> mapFromJson(dynamic json) {
    final map = <String, SafetyFinding>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyFinding.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyFinding-objects as value to a dart map
  static Map<String, List<SafetyFinding>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyFinding>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyFinding.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'code',
    'ingredient',
    'componentPath',
    'brand',
    'detail',
  };
}

