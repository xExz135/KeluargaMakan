//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ProfileCreate {
  /// Returns a new [ProfileCreate] instance.
  ProfileCreate({
    required this.name,
    required this.ageGroup,
    this.avatar = const Optional.absent(),
    this.guardianConfirmation = const Optional.absent(),
  });

  /// Nickname such as \"Ayah\" or \"Kakak\" (PRF-01).
  final String name;

  final AgeGroup ageGroup;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<Avatar?> avatar;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<GuardianConfirmationInput?> guardianConfirmation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProfileCreate &&
    other.name == name &&
    other.ageGroup == ageGroup &&
    other.avatar == avatar &&
    other.guardianConfirmation == guardianConfirmation;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (ageGroup.hashCode) +
    (avatar == null ? 0 : avatar!.hashCode) +
    (guardianConfirmation == null ? 0 : guardianConfirmation!.hashCode);

  @override
  String toString() => 'ProfileCreate[name=$name, ageGroup=$ageGroup, avatar=$avatar, guardianConfirmation=$guardianConfirmation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'ageGroup'] = this.ageGroup;
    if (this.avatar.isPresent) {
      final value = this.avatar.value;
      json[r'avatar'] = value;
    }
    if (this.guardianConfirmation.isPresent) {
      final value = this.guardianConfirmation.value;
      json[r'guardianConfirmation'] = value;
    }
    return json;
  }

  /// Clones this instance of [ProfileCreate] and returns a new one where some of the
  /// properties have changed.
  ProfileCreate copyWith({
    String? name,
    AgeGroup? ageGroup,
    Optional<Avatar?>? avatar,
    Optional<GuardianConfirmationInput?>? guardianConfirmation,
  }) => ProfileCreate(
    name: name ?? this.name,
    ageGroup: ageGroup ?? this.ageGroup,
    avatar: avatar ?? this.avatar,
    guardianConfirmation: guardianConfirmation ?? this.guardianConfirmation,
  );

  /// Returns a new [ProfileCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProfileCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "ProfileCreate[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "ProfileCreate[name]" has a null value in JSON.');
        assert(json.containsKey(r'ageGroup'), 'Required key "ProfileCreate[ageGroup]" is missing from JSON.');
        assert(json[r'ageGroup'] != null, 'Required key "ProfileCreate[ageGroup]" has a null value in JSON.');
        return true;
      }());

      return ProfileCreate(
        name: mapValueOfType<String>(json, r'name')!,
        ageGroup: AgeGroup.fromJson(json[r'ageGroup'])!,
        avatar: json.containsKey(r'avatar') ? Optional.present(Avatar.fromJson(json[r'avatar'])) : const Optional.absent(),
        guardianConfirmation: json.containsKey(r'guardianConfirmation') ? Optional.present(GuardianConfirmationInput.fromJson(json[r'guardianConfirmation'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<ProfileCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProfileCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProfileCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProfileCreate> mapFromJson(dynamic json) {
    final map = <String, ProfileCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProfileCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProfileCreate-objects as value to a dart map
  static Map<String, List<ProfileCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProfileCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProfileCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'ageGroup',
  };
}

