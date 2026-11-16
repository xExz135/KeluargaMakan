//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class HiddenNotSafe {
  /// Returns a new [HiddenNotSafe] instance.
  HiddenNotSafe({
    required this.count,
    this.memberIds = const {},
  });

  /// Minimum value: 0
  final int count;

  final Set<String> memberIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HiddenNotSafe &&
    other.count == count &&
    _deepEquality.equals(other.memberIds, memberIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (count.hashCode) +
    (memberIds.hashCode);

  @override
  String toString() => 'HiddenNotSafe[count=$count, memberIds=$memberIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'count'] = this.count;
      json[r'memberIds'] = this.memberIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [HiddenNotSafe] and returns a new one where some of the
  /// properties have changed.
  HiddenNotSafe copyWith({
    int? count,
    Set<String>? memberIds,
  }) => HiddenNotSafe(
    count: count ?? this.count,
    memberIds: memberIds ?? this.memberIds,
  );

  /// Returns a new [HiddenNotSafe] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HiddenNotSafe? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'count'), 'Required key "HiddenNotSafe[count]" is missing from JSON.');
        assert(json[r'count'] != null, 'Required key "HiddenNotSafe[count]" has a null value in JSON.');
        assert(json.containsKey(r'memberIds'), 'Required key "HiddenNotSafe[memberIds]" is missing from JSON.');
        assert(json[r'memberIds'] != null, 'Required key "HiddenNotSafe[memberIds]" has a null value in JSON.');
        return true;
      }());

      return HiddenNotSafe(
        count: mapValueOfType<int>(json, r'count')!,
        memberIds: json[r'memberIds'] is Iterable
            ? (json[r'memberIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<HiddenNotSafe> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HiddenNotSafe>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HiddenNotSafe.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HiddenNotSafe> mapFromJson(dynamic json) {
    final map = <String, HiddenNotSafe>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HiddenNotSafe.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HiddenNotSafe-objects as value to a dart map
  static Map<String, List<HiddenNotSafe>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HiddenNotSafe>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HiddenNotSafe.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'count',
    'memberIds',
  };
}

