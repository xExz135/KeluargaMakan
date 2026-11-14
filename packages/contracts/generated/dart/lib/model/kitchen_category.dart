//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// KIT-03 categories in display order: protein, vegetables, fruit, spices and aromatics, staples, sauces and condiments, dairy, frozen and leftovers. The app shows its own Bahasa Indonesia or English label for each code. Leftovers holds custom items in V1; saved leftovers (KIT-13) use the same code later.
enum KitchenCategory {
  protein._(r'protein'),
  vegetables._(r'vegetables'),
  fruit._(r'fruit'),
  spicesAromatics._(r'spices_aromatics'),
  staples._(r'staples'),
  saucesCondiments._(r'sauces_condiments'),
  dairy._(r'dairy'),
  frozen._(r'frozen'),
  leftovers._(r'leftovers'),
  ;

  /// Instantiate a new enum with the provided value.
  const KitchenCategory._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [KitchenCategory] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static KitchenCategory? fromJson(dynamic value) => KitchenCategoryTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [KitchenCategory]
  /// that were successfully decoded from the passed [JSON][json].
  static List<KitchenCategory> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenCategory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenCategory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KitchenCategory] to String,
/// and [decode] dynamic data back to [KitchenCategory].
class KitchenCategoryTypeTransformer {
  factory KitchenCategoryTypeTransformer() => _instance ??= const KitchenCategoryTypeTransformer._();

  const KitchenCategoryTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(KitchenCategory data) => data._value;

  /// Returns the instance of [KitchenCategory] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KitchenCategory? decode(dynamic data, {bool allowNull = true}) {
    if (data is KitchenCategory) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'protein': return KitchenCategory.protein;
        case r'vegetables': return KitchenCategory.vegetables;
        case r'fruit': return KitchenCategory.fruit;
        case r'spices_aromatics': return KitchenCategory.spicesAromatics;
        case r'staples': return KitchenCategory.staples;
        case r'sauces_condiments': return KitchenCategory.saucesCondiments;
        case r'dairy': return KitchenCategory.dairy;
        case r'frozen': return KitchenCategory.frozen;
        case r'leftovers': return KitchenCategory.leftovers;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static KitchenCategoryTypeTransformer? _instance;
}

