//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ReferenceIngredientCatalog {
  /// Returns a new [ReferenceIngredientCatalog] instance.
  ReferenceIngredientCatalog({
    required this.referenceVersion,
    this.items = const [],
  });

  /// DAT-06 version and content hash of the verified dataset.
  final String referenceVersion;

  /// Sorted by Indonesian display name.
  final List<CatalogIngredient> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReferenceIngredientCatalog &&
    other.referenceVersion == referenceVersion &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (referenceVersion.hashCode) +
    (items.hashCode);

  @override
  String toString() => 'ReferenceIngredientCatalog[referenceVersion=$referenceVersion, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'referenceVersion'] = this.referenceVersion;
      json[r'items'] = this.items;
    return json;
  }

  /// Clones this instance of [ReferenceIngredientCatalog] and returns a new one where some of the
  /// properties have changed.
  ReferenceIngredientCatalog copyWith({
    String? referenceVersion,
    List<CatalogIngredient>? items,
  }) => ReferenceIngredientCatalog(
    referenceVersion: referenceVersion ?? this.referenceVersion,
    items: items ?? this.items,
  );

  /// Returns a new [ReferenceIngredientCatalog] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReferenceIngredientCatalog? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'referenceVersion'), 'Required key "ReferenceIngredientCatalog[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "ReferenceIngredientCatalog[referenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'items'), 'Required key "ReferenceIngredientCatalog[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "ReferenceIngredientCatalog[items]" has a null value in JSON.');
        return true;
      }());

      return ReferenceIngredientCatalog(
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
        items: CatalogIngredient.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<ReferenceIngredientCatalog> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReferenceIngredientCatalog>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReferenceIngredientCatalog.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReferenceIngredientCatalog> mapFromJson(dynamic json) {
    final map = <String, ReferenceIngredientCatalog>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReferenceIngredientCatalog.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReferenceIngredientCatalog-objects as value to a dart map
  static Map<String, List<ReferenceIngredientCatalog>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReferenceIngredientCatalog>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReferenceIngredientCatalog.listFromJson(entry.value, growable: growable,);
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

