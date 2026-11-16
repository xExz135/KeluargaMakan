//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenMatch {
  /// Returns a new [KitchenMatch] instance.
  KitchenMatch({
    required this.availableCount,
    required this.missingCount,
    this.missing = const [],
  });

  /// Minimum value: 0
  final int availableCount;

  /// Minimum value: 0
  final int missingCount;

  final List<MissingIngredient> missing;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenMatch &&
    other.availableCount == availableCount &&
    other.missingCount == missingCount &&
    _deepEquality.equals(other.missing, missing);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (availableCount.hashCode) +
    (missingCount.hashCode) +
    (missing.hashCode);

  @override
  String toString() => 'KitchenMatch[availableCount=$availableCount, missingCount=$missingCount, missing=$missing]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'availableCount'] = this.availableCount;
      json[r'missingCount'] = this.missingCount;
      json[r'missing'] = this.missing;
    return json;
  }

  /// Clones this instance of [KitchenMatch] and returns a new one where some of the
  /// properties have changed.
  KitchenMatch copyWith({
    int? availableCount,
    int? missingCount,
    List<MissingIngredient>? missing,
  }) => KitchenMatch(
    availableCount: availableCount ?? this.availableCount,
    missingCount: missingCount ?? this.missingCount,
    missing: missing ?? this.missing,
  );

  /// Returns a new [KitchenMatch] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenMatch? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'availableCount'), 'Required key "KitchenMatch[availableCount]" is missing from JSON.');
        assert(json[r'availableCount'] != null, 'Required key "KitchenMatch[availableCount]" has a null value in JSON.');
        assert(json.containsKey(r'missingCount'), 'Required key "KitchenMatch[missingCount]" is missing from JSON.');
        assert(json[r'missingCount'] != null, 'Required key "KitchenMatch[missingCount]" has a null value in JSON.');
        assert(json.containsKey(r'missing'), 'Required key "KitchenMatch[missing]" is missing from JSON.');
        assert(json[r'missing'] != null, 'Required key "KitchenMatch[missing]" has a null value in JSON.');
        return true;
      }());

      return KitchenMatch(
        availableCount: mapValueOfType<int>(json, r'availableCount')!,
        missingCount: mapValueOfType<int>(json, r'missingCount')!,
        missing: MissingIngredient.listFromJson(json[r'missing']),
      );
    }
    return null;
  }

  static List<KitchenMatch> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenMatch>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenMatch.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenMatch> mapFromJson(dynamic json) {
    final map = <String, KitchenMatch>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenMatch.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenMatch-objects as value to a dart map
  static Map<String, List<KitchenMatch>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenMatch>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenMatch.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'availableCount',
    'missingCount',
    'missing',
  };
}

