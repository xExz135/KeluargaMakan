//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Where the recipe text comes from. `library`: a published library recipe. `adapted_library`: a library recipe adapted for these eaters (LIB-06), labeled \"Diadaptasi\". `family` (Resep Keluarga) and `generated` (AI-02, labeled as generated) are not served in V1. Only `library` may be presented as a tested recipe (LIB-07); clients treat an unknown value like `generated`.
enum RecipeOrigin {
  library_._(r'library'),
  adaptedLibrary._(r'adapted_library'),
  family._(r'family'),
  generated._(r'generated'),
  ;

  /// Instantiate a new enum with the provided value.
  const RecipeOrigin._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RecipeOrigin] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RecipeOrigin? fromJson(dynamic value) => RecipeOriginTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RecipeOrigin]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RecipeOrigin> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeOrigin>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeOrigin.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RecipeOrigin] to String,
/// and [decode] dynamic data back to [RecipeOrigin].
class RecipeOriginTypeTransformer {
  factory RecipeOriginTypeTransformer() => _instance ??= const RecipeOriginTypeTransformer._();

  const RecipeOriginTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RecipeOrigin data) => data._value;

  /// Returns the instance of [RecipeOrigin] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RecipeOrigin? decode(dynamic data, {bool allowNull = true}) {
    if (data is RecipeOrigin) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'library': return RecipeOrigin.library_;
        case r'adapted_library': return RecipeOrigin.adaptedLibrary;
        case r'family': return RecipeOrigin.family;
        case r'generated': return RecipeOrigin.generated;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RecipeOriginTypeTransformer? _instance;
}

