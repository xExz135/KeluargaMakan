//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Profile {
  /// Returns a new [Profile] instance.
  Profile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.ageGroup,
    required this.isChild,
    required this.isManager,
    required this.guardianConfirmation,
    required this.portions,
    required this.rules,
    required this.preferences,
    required this.likesDislikes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// Nickname such as \"Ayah\" or \"Kakak\" (PRF-01).
  final String name;

  final Avatar avatar;

  final AgeGroup ageGroup;

  /// Derived from `ageGroup` (infant, child or teen): stricter data handling applies, health data is off by default and the profile is never used for marketing (PRF-18, SET-10). Read-only.
  final bool isChild;

  /// True for the manager's own profile. Read-only.
  final bool isManager;

  /// Present for child profiles; null for adults.
  final GuardianConfirmation? guardianConfirmation;

  final Portions portions;

  final ProfileRules rules;

  final SoftPreferences preferences;

  final LikesDislikes likesDislikes;

  final DateTime createdAt;

  final DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Profile &&
    other.id == id &&
    other.name == name &&
    other.avatar == avatar &&
    other.ageGroup == ageGroup &&
    other.isChild == isChild &&
    other.isManager == isManager &&
    other.guardianConfirmation == guardianConfirmation &&
    other.portions == portions &&
    other.rules == rules &&
    other.preferences == preferences &&
    other.likesDislikes == likesDislikes &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (avatar.hashCode) +
    (ageGroup.hashCode) +
    (isChild.hashCode) +
    (isManager.hashCode) +
    (guardianConfirmation == null ? 0 : guardianConfirmation!.hashCode) +
    (portions.hashCode) +
    (rules.hashCode) +
    (preferences.hashCode) +
    (likesDislikes.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'Profile[id=$id, name=$name, avatar=$avatar, ageGroup=$ageGroup, isChild=$isChild, isManager=$isManager, guardianConfirmation=$guardianConfirmation, portions=$portions, rules=$rules, preferences=$preferences, likesDislikes=$likesDislikes, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'avatar'] = this.avatar;
      json[r'ageGroup'] = this.ageGroup;
      json[r'isChild'] = this.isChild;
      json[r'isManager'] = this.isManager;
    if (this.guardianConfirmation != null) {
      json[r'guardianConfirmation'] = this.guardianConfirmation;
    } else {
      json[r'guardianConfirmation'] = null;
    }
      json[r'portions'] = this.portions;
      json[r'rules'] = this.rules;
      json[r'preferences'] = this.preferences;
      json[r'likesDislikes'] = this.likesDislikes;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [Profile] and returns a new one where some of the
  /// properties have changed.
  Profile copyWith({
    String? id,
    String? name,
    Avatar? avatar,
    AgeGroup? ageGroup,
    bool? isChild,
    bool? isManager,
    GuardianConfirmation? guardianConfirmation,
    bool guardianConfirmationSetToNull = false,
    Portions? portions,
    ProfileRules? rules,
    SoftPreferences? preferences,
    LikesDislikes? likesDislikes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    ageGroup: ageGroup ?? this.ageGroup,
    isChild: isChild ?? this.isChild,
    isManager: isManager ?? this.isManager,
    guardianConfirmation: guardianConfirmationSetToNull ? null : guardianConfirmation ?? this.guardianConfirmation,
    portions: portions ?? this.portions,
    rules: rules ?? this.rules,
    preferences: preferences ?? this.preferences,
    likesDislikes: likesDislikes ?? this.likesDislikes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a new [Profile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Profile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Profile[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Profile[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "Profile[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "Profile[name]" has a null value in JSON.');
        assert(json.containsKey(r'avatar'), 'Required key "Profile[avatar]" is missing from JSON.');
        assert(json[r'avatar'] != null, 'Required key "Profile[avatar]" has a null value in JSON.');
        assert(json.containsKey(r'ageGroup'), 'Required key "Profile[ageGroup]" is missing from JSON.');
        assert(json[r'ageGroup'] != null, 'Required key "Profile[ageGroup]" has a null value in JSON.');
        assert(json.containsKey(r'isChild'), 'Required key "Profile[isChild]" is missing from JSON.');
        assert(json[r'isChild'] != null, 'Required key "Profile[isChild]" has a null value in JSON.');
        assert(json.containsKey(r'isManager'), 'Required key "Profile[isManager]" is missing from JSON.');
        assert(json[r'isManager'] != null, 'Required key "Profile[isManager]" has a null value in JSON.');
        assert(json.containsKey(r'guardianConfirmation'), 'Required key "Profile[guardianConfirmation]" is missing from JSON.');
        assert(json.containsKey(r'portions'), 'Required key "Profile[portions]" is missing from JSON.');
        assert(json[r'portions'] != null, 'Required key "Profile[portions]" has a null value in JSON.');
        assert(json.containsKey(r'rules'), 'Required key "Profile[rules]" is missing from JSON.');
        assert(json[r'rules'] != null, 'Required key "Profile[rules]" has a null value in JSON.');
        assert(json.containsKey(r'preferences'), 'Required key "Profile[preferences]" is missing from JSON.');
        assert(json[r'preferences'] != null, 'Required key "Profile[preferences]" has a null value in JSON.');
        assert(json.containsKey(r'likesDislikes'), 'Required key "Profile[likesDislikes]" is missing from JSON.');
        assert(json[r'likesDislikes'] != null, 'Required key "Profile[likesDislikes]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "Profile[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "Profile[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "Profile[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null, 'Required key "Profile[updatedAt]" has a null value in JSON.');
        return true;
      }());

      return Profile(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        avatar: Avatar.fromJson(json[r'avatar'])!,
        ageGroup: AgeGroup.fromJson(json[r'ageGroup'])!,
        isChild: mapValueOfType<bool>(json, r'isChild')!,
        isManager: mapValueOfType<bool>(json, r'isManager')!,
        guardianConfirmation: GuardianConfirmation.fromJson(json[r'guardianConfirmation']),
        portions: Portions.fromJson(json[r'portions'])!,
        rules: ProfileRules.fromJson(json[r'rules'])!,
        preferences: SoftPreferences.fromJson(json[r'preferences'])!,
        likesDislikes: LikesDislikes.fromJson(json[r'likesDislikes'])!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<Profile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Profile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Profile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Profile> mapFromJson(dynamic json) {
    final map = <String, Profile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Profile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Profile-objects as value to a dart map
  static Map<String, List<Profile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Profile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Profile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'avatar',
    'ageGroup',
    'isChild',
    'isManager',
    'guardianConfirmation',
    'portions',
    'rules',
    'preferences',
    'likesDislikes',
    'createdAt',
    'updatedAt',
  };
}

