//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ProfileRules {
  /// Returns a new [ProfileRules] instance.
  ProfileRules({
    required this.consent,
    this.items = const [],
  });

  final RulesConsentState consent;

  /// Empty unless `consent.status` is `given`.
  final List<HardRule> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProfileRules &&
    other.consent == consent &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (consent.hashCode) +
    (items.hashCode);

  @override
  String toString() => 'ProfileRules[consent=$consent, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'consent'] = this.consent;
      json[r'items'] = this.items;
    return json;
  }

  /// Clones this instance of [ProfileRules] and returns a new one where some of the
  /// properties have changed.
  ProfileRules copyWith({
    RulesConsentState? consent,
    List<HardRule>? items,
  }) => ProfileRules(
    consent: consent ?? this.consent,
    items: items ?? this.items,
  );

  /// Returns a new [ProfileRules] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProfileRules? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consent'), 'Required key "ProfileRules[consent]" is missing from JSON.');
        assert(json[r'consent'] != null, 'Required key "ProfileRules[consent]" has a null value in JSON.');
        assert(json.containsKey(r'items'), 'Required key "ProfileRules[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "ProfileRules[items]" has a null value in JSON.');
        return true;
      }());

      return ProfileRules(
        consent: RulesConsentState.fromJson(json[r'consent'])!,
        items: HardRule.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<ProfileRules> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProfileRules>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProfileRules.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProfileRules> mapFromJson(dynamic json) {
    final map = <String, ProfileRules>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProfileRules.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProfileRules-objects as value to a dart map
  static Map<String, List<ProfileRules>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProfileRules>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProfileRules.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consent',
    'items',
  };
}

