//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientSearchResult {
  /// Returns a new [IngredientSearchResult] instance.
  IngredientSearchResult({
    required this.referenceVersion,
    this.items = const [],
  });

  final String referenceVersion;

  /// Best match first. Empty only when nothing matched.
  final List<IngredientSearchHit> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IngredientSearchResult &&
    other.referenceVersion == referenceVersion &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (referenceVersion.hashCode) +
    (items.hashCode);

  @override
  String toString() => 'IngredientSearchResult[referenceVersion=$referenceVersion, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'referenceVersion'] = this.referenceVersion;
      json[r'items'] = this.items;
    return json;
  }

  /// Clones this instance of [IngredientSearchResult] and returns a new one where some of the
  /// properties have changed.
  IngredientSearchResult copyWith({
    String? referenceVersion,
    List<IngredientSearchHit>? items,
  }) => IngredientSearchResult(
    referenceVersion: referenceVersion ?? this.referenceVersion,
    items: items ?? this.items,
  );

  /// Returns a new [IngredientSearchResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientSearchResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'referenceVersion'), 'Required key "IngredientSearchResult[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "IngredientSearchResult[referenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'items'), 'Required key "IngredientSearchResult[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "IngredientSearchResult[items]" has a null value in JSON.');
        return true;
      }());

      return IngredientSearchResult(
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
        items: IngredientSearchHit.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<IngredientSearchResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientSearchResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientSearchResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientSearchResult> mapFromJson(dynamic json) {
    final map = <String, IngredientSearchResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientSearchResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientSearchResult-objects as value to a dart map
  static Map<String, List<IngredientSearchResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientSearchResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientSearchResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'referenceVersion',
    'items',
  };
}

