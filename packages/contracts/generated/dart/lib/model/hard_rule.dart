//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HardRule {
  /// Returns a new [HardRule] instance.
  HardRule({
    required this.id,
    required this.type,
    required this.allergen,
    required this.freeText,
    required this.mapping,
    required this.createdAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final HardRuleType type;

  final StandardAllergen? allergen;

  final String? freeText;

  final HardRuleMapping? mapping;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HardRule &&
    other.id == id &&
    other.type == type &&
    other.allergen == allergen &&
    other.freeText == freeText &&
    other.mapping == mapping &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (allergen == null ? 0 : allergen!.hashCode) +
    (freeText == null ? 0 : freeText!.hashCode) +
    (mapping == null ? 0 : mapping!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'HardRule[id=$id, type=$type, allergen=$allergen, freeText=$freeText, mapping=$mapping, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
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
    if (this.mapping != null) {
      json[r'mapping'] = this.mapping;
    } else {
      json[r'mapping'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [HardRule] and returns a new one where some of the
  /// properties have changed.
  HardRule copyWith({
    String? id,
    HardRuleType? type,
    StandardAllergen? allergen,
    bool allergenSetToNull = false,
    String? freeText,
    bool freeTextSetToNull = false,
    HardRuleMapping? mapping,
    bool mappingSetToNull = false,
    DateTime? createdAt,
  }) => HardRule(
    id: id ?? this.id,
    type: type ?? this.type,
    allergen: allergenSetToNull ? null : allergen ?? this.allergen,
    freeText: freeTextSetToNull ? null : freeText ?? this.freeText,
    mapping: mappingSetToNull ? null : mapping ?? this.mapping,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [HardRule] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HardRule? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "HardRule[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "HardRule[id]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "HardRule[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "HardRule[type]" has a null value in JSON.');
        assert(json.containsKey(r'allergen'), 'Required key "HardRule[allergen]" is missing from JSON.');
        assert(json.containsKey(r'freeText'), 'Required key "HardRule[freeText]" is missing from JSON.');
        assert(json.containsKey(r'mapping'), 'Required key "HardRule[mapping]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "HardRule[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "HardRule[createdAt]" has a null value in JSON.');
        return true;
      }());

      return HardRule(
        id: mapValueOfType<String>(json, r'id')!,
        type: HardRuleType.fromJson(json[r'type'])!,
        allergen: StandardAllergen.fromJson(json[r'allergen']),
        freeText: mapValueOfType<String>(json, r'freeText'),
        mapping: HardRuleMapping.fromJson(json[r'mapping']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<HardRule> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HardRule>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HardRule.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HardRule> mapFromJson(dynamic json) {
    final map = <String, HardRule>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HardRule.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HardRule-objects as value to a dart map
  static Map<String, List<HardRule>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HardRule>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HardRule.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'type',
    'allergen',
    'freeText',
    'mapping',
    'createdAt',
  };
}

