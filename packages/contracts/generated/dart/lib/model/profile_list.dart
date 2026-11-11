//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ProfileList {
  /// Returns a new [ProfileList] instance.
  ProfileList({
    this.items = const [],
    required this.maxProfiles,
  });

  /// Manager's profile first.
  final List<Profile> items;

  /// Configured profile limit (PRF-02, at least 12, target).
  ///
  /// Minimum value: 12
  final int maxProfiles;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProfileList &&
    _deepEquality.equals(other.items, items) &&
    other.maxProfiles == maxProfiles;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (maxProfiles.hashCode);

  @override
  String toString() => 'ProfileList[items=$items, maxProfiles=$maxProfiles]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
      json[r'maxProfiles'] = this.maxProfiles;
    return json;
  }

  /// Clones this instance of [ProfileList] and returns a new one where some of the
  /// properties have changed.
  ProfileList copyWith({
    List<Profile>? items,
    int? maxProfiles,
  }) => ProfileList(
    items: items ?? this.items,
    maxProfiles: maxProfiles ?? this.maxProfiles,
  );

  /// Returns a new [ProfileList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProfileList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "ProfileList[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "ProfileList[items]" has a null value in JSON.');
        assert(json.containsKey(r'maxProfiles'), 'Required key "ProfileList[maxProfiles]" is missing from JSON.');
        assert(json[r'maxProfiles'] != null, 'Required key "ProfileList[maxProfiles]" has a null value in JSON.');
        return true;
      }());

      return ProfileList(
        items: Profile.listFromJson(json[r'items']),
        maxProfiles: mapValueOfType<int>(json, r'maxProfiles')!,
      );
    }
    return null;
  }

  static List<ProfileList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProfileList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProfileList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProfileList> mapFromJson(dynamic json) {
    final map = <String, ProfileList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProfileList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProfileList-objects as value to a dart map
  static Map<String, List<ProfileList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProfileList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProfileList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'maxProfiles',
  };
}

