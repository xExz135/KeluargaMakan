//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ManagerProfileCreate {
  /// Returns a new [ManagerProfileCreate] instance.
  ManagerProfileCreate({
    required this.name,
    this.avatar = const Optional.absent(),
  });

  /// Nickname such as \"Ayah\" or \"Kakak\" (PRF-01).
  final String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<Avatar?> avatar;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ManagerProfileCreate &&
    other.name == name &&
    other.avatar == avatar;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (avatar == null ? 0 : avatar!.hashCode);

  @override
  String toString() => 'ManagerProfileCreate[name=$name, avatar=$avatar]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.avatar.isPresent) {
      final value = this.avatar.value;
      json[r'avatar'] = value;
    }
    return json;
  }

  /// Clones this instance of [ManagerProfileCreate] and returns a new one where some of the
  /// properties have changed.
  ManagerProfileCreate copyWith({
    String? name,
    Optional<Avatar?>? avatar,
  }) => ManagerProfileCreate(
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
  );

  /// Returns a new [ManagerProfileCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ManagerProfileCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "ManagerProfileCreate[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "ManagerProfileCreate[name]" has a null value in JSON.');
        return true;
      }());

      return ManagerProfileCreate(
        name: mapValueOfType<String>(json, r'name')!,
        avatar: json.containsKey(r'avatar') ? Optional.present(Avatar.fromJson(json[r'avatar'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<ManagerProfileCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ManagerProfileCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ManagerProfileCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ManagerProfileCreate> mapFromJson(dynamic json) {
    final map = <String, ManagerProfileCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ManagerProfileCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ManagerProfileCreate-objects as value to a dart map
  static Map<String, List<ManagerProfileCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ManagerProfileCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ManagerProfileCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

