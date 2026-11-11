//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Avatar {
  /// Returns a new [Avatar] instance.
  Avatar({
    required this.style,
    this.colorToken = const Optional.absent(),
    this.illustrationId = const Optional.absent(),
  });

  final AvatarStyle style;

  /// Design-system avatar colour token, for `initials`.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> colorToken;

  /// Preset illustration ID, for `illustration`.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> illustrationId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Avatar &&
    other.style == style &&
    other.colorToken == colorToken &&
    other.illustrationId == illustrationId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (style.hashCode) +
    (colorToken == null ? 0 : colorToken!.hashCode) +
    (illustrationId == null ? 0 : illustrationId!.hashCode);

  @override
  String toString() => 'Avatar[style=$style, colorToken=$colorToken, illustrationId=$illustrationId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'style'] = this.style;
    if (this.colorToken.isPresent) {
      final value = this.colorToken.value;
      json[r'colorToken'] = value;
    }
    if (this.illustrationId.isPresent) {
      final value = this.illustrationId.value;
      json[r'illustrationId'] = value;
    }
    return json;
  }

  /// Clones this instance of [Avatar] and returns a new one where some of the
  /// properties have changed.
  Avatar copyWith({
    AvatarStyle? style,
    Optional<String?>? colorToken,
    Optional<String?>? illustrationId,
  }) => Avatar(
    style: style ?? this.style,
    colorToken: colorToken ?? this.colorToken,
    illustrationId: illustrationId ?? this.illustrationId,
  );

  /// Returns a new [Avatar] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Avatar? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'style'), 'Required key "Avatar[style]" is missing from JSON.');
        assert(json[r'style'] != null, 'Required key "Avatar[style]" has a null value in JSON.');
        return true;
      }());

      return Avatar(
        style: AvatarStyle.fromJson(json[r'style'])!,
        colorToken: json.containsKey(r'colorToken') ? Optional.present(mapValueOfType<String>(json, r'colorToken')) : const Optional.absent(),
        illustrationId: json.containsKey(r'illustrationId') ? Optional.present(mapValueOfType<String>(json, r'illustrationId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<Avatar> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Avatar>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Avatar.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Avatar> mapFromJson(dynamic json) {
    final map = <String, Avatar>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Avatar.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Avatar-objects as value to a dart map
  static Map<String, List<Avatar>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Avatar>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Avatar.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'style',
  };
}

