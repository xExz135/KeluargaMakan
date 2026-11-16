//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyRuleRef {
  /// Returns a new [SafetyRuleRef] instance.
  SafetyRuleRef({
    required this.ruleId,
    required this.type,
    required this.allergen,
    required this.freeText,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String ruleId;

  final HardRuleType type;

  final StandardAllergen? allergen;

  final String? freeText;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyRuleRef &&
    other.ruleId == ruleId &&
    other.type == type &&
    other.allergen == allergen &&
    other.freeText == freeText;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ruleId.hashCode) +
    (type.hashCode) +
    (allergen == null ? 0 : allergen!.hashCode) +
    (freeText == null ? 0 : freeText!.hashCode);

  @override
  String toString() => 'SafetyRuleRef[ruleId=$ruleId, type=$type, allergen=$allergen, freeText=$freeText]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ruleId'] = this.ruleId;
      json[r'type'] = this.type;
    if (this.allergen != null) {
      json[r'allergen'] = this.allergen;
    } else {
      json[r'allergen'] = null;
    }
    if (this.freeText != null) {
      json[r'freeText'] = this.freeText;
    } else {
      json[r'freeText'] = null;
    }
    return json;
  }

  /// Clones this instance of [SafetyRuleRef] and returns a new one where some of the
  /// properties have changed.
  SafetyRuleRef copyWith({
    String? ruleId,
    HardRuleType? type,
    StandardAllergen? allergen,
    bool allergenSetToNull = false,
    String? freeText,
    bool freeTextSetToNull = false,
  }) => SafetyRuleRef(
    ruleId: ruleId ?? this.ruleId,
    type: type ?? this.type,
    allergen: allergenSetToNull ? null : allergen ?? this.allergen,
    freeText: freeTextSetToNull ? null : freeText ?? this.freeText,
  );

  /// Returns a new [SafetyRuleRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyRuleRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ruleId'), 'Required key "SafetyRuleRef[ruleId]" is missing from JSON.');
        assert(json[r'ruleId'] != null, 'Required key "SafetyRuleRef[ruleId]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "SafetyRuleRef[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "SafetyRuleRef[type]" has a null value in JSON.');
        assert(json.containsKey(r'allergen'), 'Required key "SafetyRuleRef[allergen]" is missing from JSON.');
        assert(json.containsKey(r'freeText'), 'Required key "SafetyRuleRef[freeText]" is missing from JSON.');
        return true;
      }());

      return SafetyRuleRef(
        ruleId: mapValueOfType<String>(json, r'ruleId')!,
        type: HardRuleType.fromJson(json[r'type'])!,
        allergen: StandardAllergen.fromJson(json[r'allergen']),
        freeText: mapValueOfType<String>(json, r'freeText'),
      );
    }
    return null;
  }

  static List<SafetyRuleRef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyRuleRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyRuleRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyRuleRef> mapFromJson(dynamic json) {
    final map = <String, SafetyRuleRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyRuleRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyRuleRef-objects as value to a dart map
  static Map<String, List<SafetyRuleRef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyRuleRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyRuleRef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ruleId',
    'type',
    'allergen',
    'freeText',
  };
}

