//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// PRF-04 standard allergen codes, matching the Cek Aman vocabulary. Shellfish and shrimp, and wheat and gluten, are separate codes.
enum StandardAllergen {
  peanut._(r'peanut'),
  treeNut._(r'tree_nut'),
  shellfish._(r'shellfish'),
  shrimp._(r'shrimp'),
  fish._(r'fish'),
  egg._(r'egg'),
  milk._(r'milk'),
  soy._(r'soy'),
  wheat._(r'wheat'),
  gluten._(r'gluten'),
  sesame._(r'sesame'),
  ;

  /// Instantiate a new enum with the provided value.
  const StandardAllergen._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [StandardAllergen] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static StandardAllergen? fromJson(dynamic value) => StandardAllergenTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [StandardAllergen]
  /// that were successfully decoded from the passed [JSON][json].
  static List<StandardAllergen> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StandardAllergen>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StandardAllergen.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [StandardAllergen] to String,
/// and [decode] dynamic data back to [StandardAllergen].
class StandardAllergenTypeTransformer {
  factory StandardAllergenTypeTransformer() => _instance ??= const StandardAllergenTypeTransformer._();

  const StandardAllergenTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(StandardAllergen data) => data._value;

  /// Returns the instance of [StandardAllergen] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  StandardAllergen? decode(dynamic data, {bool allowNull = true}) {
    if (data is StandardAllergen) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'peanut': return StandardAllergen.peanut;
        case r'tree_nut': return StandardAllergen.treeNut;
        case r'shellfish': return StandardAllergen.shellfish;
        case r'shrimp': return StandardAllergen.shrimp;
        case r'fish': return StandardAllergen.fish;
        case r'egg': return StandardAllergen.egg;
        case r'milk': return StandardAllergen.milk;
        case r'soy': return StandardAllergen.soy;
        case r'wheat': return StandardAllergen.wheat;
        case r'gluten': return StandardAllergen.gluten;
        case r'sesame': return StandardAllergen.sesame;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static StandardAllergenTypeTransformer? _instance;
}

