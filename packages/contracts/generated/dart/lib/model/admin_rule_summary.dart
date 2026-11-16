//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRuleSummary {
  /// Returns a new [AdminRuleSummary] instance.
  AdminRuleSummary({
    required this.type,
    required this.allergen,
  });

  final HardRuleType type;

  final StandardAllergen? allergen;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRuleSummary &&
    other.type == type &&
    other.allergen == allergen;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (allergen == null ? 0 : allergen!.hashCode);

  @override
  String toString() => 'AdminRuleSummary[type=$type, allergen=$allergen]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
    if (this.allergen != null) {
      json[r'allergen'] = this.allergen;
    } else {
      json[r'allergen'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdminRuleSummary] and returns a new one where some of the
  /// properties have changed.
  AdminRuleSummary copyWith({
    HardRuleType? type,
    StandardAllergen? allergen,
    bool allergenSetToNull = false,
  }) => AdminRuleSummary(
    type: type ?? this.type,
    allergen: allergenSetToNull ? null : allergen ?? this.allergen,
  );

  /// Returns a new [AdminRuleSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRuleSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "AdminRuleSummary[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "AdminRuleSummary[type]" has a null value in JSON.');
        assert(json.containsKey(r'allergen'), 'Required key "AdminRuleSummary[allergen]" is missing from JSON.');
        return true;
      }());

      return AdminRuleSummary(
        type: HardRuleType.fromJson(json[r'type'])!,
        allergen: StandardAllergen.fromJson(json[r'allergen']),
      );
    }
    return null;
  }

  static List<AdminRuleSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRuleSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRuleSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRuleSummary> mapFromJson(dynamic json) {
    final map = <String, AdminRuleSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRuleSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRuleSummary-objects as value to a dart map
  static Map<String, List<AdminRuleSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRuleSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRuleSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'allergen',
  };
}

