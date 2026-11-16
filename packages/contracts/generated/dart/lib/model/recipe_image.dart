//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeImage {
  /// Returns a new [RecipeImage] instance.
  RecipeImage({
    required this.imageId,
    required this.width,
    required this.height,
    required this.alt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String imageId;

  /// Minimum value: 1
  final int width;

  /// Minimum value: 1
  final int height;

  final LocalizedText alt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeImage &&
    other.imageId == imageId &&
    other.width == width &&
    other.height == height &&
    other.alt == alt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (imageId.hashCode) +
    (width.hashCode) +
    (height.hashCode) +
    (alt.hashCode);

  @override
  String toString() => 'RecipeImage[imageId=$imageId, width=$width, height=$height, alt=$alt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'imageId'] = this.imageId;
      json[r'width'] = this.width;
      json[r'height'] = this.height;
      json[r'alt'] = this.alt;
    return json;
  }

  /// Clones this instance of [RecipeImage] and returns a new one where some of the
  /// properties have changed.
  RecipeImage copyWith({
    String? imageId,
    int? width,
    int? height,
    LocalizedText? alt,
  }) => RecipeImage(
    imageId: imageId ?? this.imageId,
    width: width ?? this.width,
    height: height ?? this.height,
    alt: alt ?? this.alt,
  );

  /// Returns a new [RecipeImage] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeImage? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'imageId'), 'Required key "RecipeImage[imageId]" is missing from JSON.');
        assert(json[r'imageId'] != null, 'Required key "RecipeImage[imageId]" has a null value in JSON.');
        assert(json.containsKey(r'width'), 'Required key "RecipeImage[width]" is missing from JSON.');
        assert(json[r'width'] != null, 'Required key "RecipeImage[width]" has a null value in JSON.');
        assert(json.containsKey(r'height'), 'Required key "RecipeImage[height]" is missing from JSON.');
        assert(json[r'height'] != null, 'Required key "RecipeImage[height]" has a null value in JSON.');
        assert(json.containsKey(r'alt'), 'Required key "RecipeImage[alt]" is missing from JSON.');
        assert(json[r'alt'] != null, 'Required key "RecipeImage[alt]" has a null value in JSON.');
        return true;
      }());

      return RecipeImage(
        imageId: mapValueOfType<String>(json, r'imageId')!,
        width: mapValueOfType<int>(json, r'width')!,
        height: mapValueOfType<int>(json, r'height')!,
        alt: LocalizedText.fromJson(json[r'alt'])!,
      );
    }
    return null;
  }

  static List<RecipeImage> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeImage>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeImage.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeImage> mapFromJson(dynamic json) {
    final map = <String, RecipeImage>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeImage.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeImage-objects as value to a dart map
  static Map<String, List<RecipeImage>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeImage>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeImage.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'imageId',
    'width',
    'height',
    'alt',
  };
}

