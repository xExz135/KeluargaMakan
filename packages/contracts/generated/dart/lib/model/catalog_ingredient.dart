//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class CatalogIngredient {
  /// Returns a new [CatalogIngredient] instance.
  CatalogIngredient({
    required this.ingredientId,
    required this.displayName,
    this.localNames = const [],
    required this.category,
    required this.brandVaries,
    this.brands = const [],
  });

  /// Identifier of a reference ingredient or library dish.
  final String ingredientId;

  final LocalizedText displayName;

  /// Local, regional and alternative names (KIT-04).
  final List<String> localNames;

  /// The kitchen category, or null when the reference data gives none; the app then asks for one when the ingredient is added.
  final KitchenCategory? category;

  /// SAF-07: what the ingredient contains can differ by brand, so the app offers to record a brand (KIT-09). This is not a safety result.
  final bool brandVaries;

  final List<CatalogBrand> brands;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CatalogIngredient &&
    other.ingredientId == ingredientId &&
    other.displayName == displayName &&
    _deepEquality.equals(other.localNames, localNames) &&
    other.category == category &&
    other.brandVaries == brandVaries &&
    _deepEquality.equals(other.brands, brands);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ingredientId.hashCode) +
    (displayName.hashCode) +
    (localNames.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (brandVaries.hashCode) +
    (brands.hashCode);

  @override
  String toString() => 'CatalogIngredient[ingredientId=$ingredientId, displayName=$displayName, localNames=$localNames, category=$category, brandVaries=$brandVaries, brands=$brands]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ingredientId'] = this.ingredientId;
      json[r'displayName'] = this.displayName;
      json[r'localNames'] = this.localNames;
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
      json[r'brandVaries'] = this.brandVaries;
      json[r'brands'] = this.brands;
    return json;
  }

  /// Clones this instance of [CatalogIngredient] and returns a new one where some of the
  /// properties have changed.
  CatalogIngredient copyWith({
    String? ingredientId,
    LocalizedText? displayName,
    List<String>? localNames,
    KitchenCategory? category,
    bool categorySetToNull = false,
    bool? brandVaries,
    List<CatalogBrand>? brands,
  }) => CatalogIngredient(
    ingredientId: ingredientId ?? this.ingredientId,
    displayName: displayName ?? this.displayName,
    localNames: localNames ?? this.localNames,
    category: categorySetToNull ? null : category ?? this.category,
    brandVaries: brandVaries ?? this.brandVaries,
    brands: brands ?? this.brands,
  );

  /// Returns a new [CatalogIngredient] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CatalogIngredient? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'ingredientId'), 'Required key "CatalogIngredient[ingredientId]" is missing from JSON.');
        assert(json[r'ingredientId'] != null, 'Required key "CatalogIngredient[ingredientId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "CatalogIngredient[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "CatalogIngredient[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'localNames'), 'Required key "CatalogIngredient[localNames]" is missing from JSON.');
        assert(json[r'localNames'] != null, 'Required key "CatalogIngredient[localNames]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "CatalogIngredient[category]" is missing from JSON.');
        assert(json.containsKey(r'brandVaries'), 'Required key "CatalogIngredient[brandVaries]" is missing from JSON.');
        assert(json[r'brandVaries'] != null, 'Required key "CatalogIngredient[brandVaries]" has a null value in JSON.');
        assert(json.containsKey(r'brands'), 'Required key "CatalogIngredient[brands]" is missing from JSON.');
        assert(json[r'brands'] != null, 'Required key "CatalogIngredient[brands]" has a null value in JSON.');
        return true;
      }());

      return CatalogIngredient(
        ingredientId: mapValueOfType<String>(json, r'ingredientId')!,
        displayName: LocalizedText.fromJson(json[r'displayName'])!,
        localNames: json[r'localNames'] is Iterable
            ? (json[r'localNames'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        category: KitchenCategory.fromJson(json[r'category']),
        brandVaries: mapValueOfType<bool>(json, r'brandVaries')!,
        brands: CatalogBrand.listFromJson(json[r'brands']),
      );
    }
    return null;
  }

  static List<CatalogIngredient> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CatalogIngredient>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CatalogIngredient.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CatalogIngredient> mapFromJson(dynamic json) {
    final map = <String, CatalogIngredient>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CatalogIngredient.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CatalogIngredient-objects as value to a dart map
  static Map<String, List<CatalogIngredient>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CatalogIngredient>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CatalogIngredient.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ingredientId',
    'displayName',
    'localNames',
    'category',
    'brandVaries',
    'brands',
  };
}

