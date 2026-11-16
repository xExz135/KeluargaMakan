//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LibraryImage {
  /// Returns a new [LibraryImage] instance.
  LibraryImage({
    required this.imageId,
    required this.width,
    required this.height,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String imageId;

  /// Minimum value: 1
  final int width;

  /// Minimum value: 1
  final int height;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LibraryImage &&
    other.imageId == imageId &&
    other.width == width &&
    other.height == height;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (imageId.hashCode) +
    (width.hashCode) +
    (height.hashCode);

  @override
  String toString() => 'LibraryImage[imageId=$imageId, width=$width, height=$height]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'imageId'] = this.imageId;
      json[r'width'] = this.width;
      json[r'height'] = this.height;
    return json;
  }

  /// Clones this instance of [LibraryImage] and returns a new one where some of the
  /// properties have changed.
  LibraryImage copyWith({
    String? imageId,
    int? width,
    int? height,
  }) => LibraryImage(
    imageId: imageId ?? this.imageId,
    width: width ?? this.width,
    height: height ?? this.height,
  );

  /// Returns a new [LibraryImage] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LibraryImage? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'imageId'), 'Required key "LibraryImage[imageId]" is missing from JSON.');
        assert(json[r'imageId'] != null, 'Required key "LibraryImage[imageId]" has a null value in JSON.');
        assert(json.containsKey(r'width'), 'Required key "LibraryImage[width]" is missing from JSON.');
        assert(json[r'width'] != null, 'Required key "LibraryImage[width]" has a null value in JSON.');
        assert(json.containsKey(r'height'), 'Required key "LibraryImage[height]" is missing from JSON.');
        assert(json[r'height'] != null, 'Required key "LibraryImage[height]" has a null value in JSON.');
        return true;
      }());

      return LibraryImage(
        imageId: mapValueOfType<String>(json, r'imageId')!,
        width: mapValueOfType<int>(json, r'width')!,
        height: mapValueOfType<int>(json, r'height')!,
      );
    }
    return null;
  }

  static List<LibraryImage> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LibraryImage>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibraryImage.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LibraryImage> mapFromJson(dynamic json) {
    final map = <String, LibraryImage>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LibraryImage.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LibraryImage-objects as value to a dart map
  static Map<String, List<LibraryImage>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LibraryImage>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LibraryImage.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'imageId',
    'width',
    'height',
  };
}

