//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ProfileUpdate {
  /// Returns a new [ProfileUpdate] instance.
  ProfileUpdate({
    this.name = const Optional.absent(),
    this.avatar = const Optional.absent(),
    this.ageGroup = const Optional.absent(),
    this.portionSize = const Optional.absent(),
    this.ricePortion = const Optional.absent(),
    this.guardianConfirmation = const Optional.absent(),
  });

  /// Nickname such as \"Ayah\" or \"Kakak\" (PRF-01).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> name;

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
  final Optional<AgeGroup?> ageGroup;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<PortionSize?> portionSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<PortionSize?> ricePortion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<GuardianConfirmationInput?> guardianConfirmation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProfileUpdate &&
    other.name == name &&
    other.avatar == avatar &&
    other.ageGroup == ageGroup &&
    other.portionSize == portionSize &&
    other.ricePortion == ricePortion &&
    other.guardianConfirmation == guardianConfirmation;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (avatar == null ? 0 : avatar!.hashCode) +
    (ageGroup == null ? 0 : ageGroup!.hashCode) +
    (portionSize == null ? 0 : portionSize!.hashCode) +
    (ricePortion == null ? 0 : ricePortion!.hashCode) +
    (guardianConfirmation == null ? 0 : guardianConfirmation!.hashCode);

  @override
  String toString() => 'ProfileUpdate[name=$name, avatar=$avatar, ageGroup=$ageGroup, portionSize=$portionSize, ricePortion=$ricePortion, guardianConfirmation=$guardianConfirmation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.avatar.isPresent) {
      final value = this.avatar.value;
      json[r'avatar'] = value;
    }
    if (this.ageGroup.isPresent) {
      final value = this.ageGroup.value;
      json[r'ageGroup'] = value;
    }
    if (this.portionSize.isPresent) {
      final value = this.portionSize.value;
      json[r'portionSize'] = value;
    }
    if (this.ricePortion.isPresent) {
      final value = this.ricePortion.value;
      json[r'ricePortion'] = value;
    }
    if (this.guardianConfirmation.isPresent) {
      final value = this.guardianConfirmation.value;
      json[r'guardianConfirmation'] = value;
    }
    return json;
  }

  /// Clones this instance of [ProfileUpdate] and returns a new one where some of the
  /// properties have changed.
  ProfileUpdate copyWith({
    Optional<String?>? name,
    Optional<Avatar?>? avatar,
    Optional<AgeGroup?>? ageGroup,
    Optional<PortionSize?>? portionSize,
    Optional<PortionSize?>? ricePortion,
    Optional<GuardianConfirmationInput?>? guardianConfirmation,
  }) => ProfileUpdate(
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    ageGroup: ageGroup ?? this.ageGroup,
    portionSize: portionSize ?? this.portionSize,
    ricePortion: ricePortion ?? this.ricePortion,
    guardianConfirmation: guardianConfirmation ?? this.guardianConfirmation,
  );

  /// Returns a new [ProfileUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProfileUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ProfileUpdate(
        name: json.containsKey(r'name') ? Optional.present(mapValueOfType<String>(json, r'name')) : const Optional.absent(),
        avatar: json.containsKey(r'avatar') ? Optional.present(Avatar.fromJson(json[r'avatar'])) : const Optional.absent(),
        ageGroup: json.containsKey(r'ageGroup') ? Optional.present(AgeGroup.fromJson(json[r'ageGroup'])) : const Optional.absent(),
        portionSize: json.containsKey(r'portionSize') ? Optional.present(PortionSize.fromJson(json[r'portionSize'])) : const Optional.absent(),
        ricePortion: json.containsKey(r'ricePortion') ? Optional.present(PortionSize.fromJson(json[r'ricePortion'])) : const Optional.absent(),
        guardianConfirmation: json.containsKey(r'guardianConfirmation') ? Optional.present(GuardianConfirmationInput.fromJson(json[r'guardianConfirmation'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<ProfileUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProfileUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProfileUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProfileUpdate> mapFromJson(dynamic json) {
    final map = <String, ProfileUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProfileUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProfileUpdate-objects as value to a dart map
  static Map<String, List<ProfileUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProfileUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProfileUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

