//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LikesDislikes {
  /// Returns a new [LikesDislikes] instance.
  LikesDislikes({
    this.likes = const [],
    this.dislikes = const [],
    required this.updatedAt,
  });

  final List<FoodRef> likes;

  final List<FoodRef> dislikes;

  /// Null until first saved.
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LikesDislikes &&
    _deepEquality.equals(other.likes, likes) &&
    _deepEquality.equals(other.dislikes, dislikes) &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (likes.hashCode) +
    (dislikes.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode);

  @override
  String toString() => 'LikesDislikes[likes=$likes, dislikes=$dislikes, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'likes'] = this.likes;
      json[r'dislikes'] = this.dislikes;
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    return json;
  }

  /// Clones this instance of [LikesDislikes] and returns a new one where some of the
  /// properties have changed.
  LikesDislikes copyWith({
    List<FoodRef>? likes,
    List<FoodRef>? dislikes,
    DateTime? updatedAt,
    bool updatedAtSetToNull = false,
  }) => LikesDislikes(
    likes: likes ?? this.likes,
    dislikes: dislikes ?? this.dislikes,
    updatedAt: updatedAtSetToNull ? null : updatedAt ?? this.updatedAt,
  );

  /// Returns a new [LikesDislikes] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LikesDislikes? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'likes'), 'Required key "LikesDislikes[likes]" is missing from JSON.');
        assert(json[r'likes'] != null, 'Required key "LikesDislikes[likes]" has a null value in JSON.');
        assert(json.containsKey(r'dislikes'), 'Required key "LikesDislikes[dislikes]" is missing from JSON.');
        assert(json[r'dislikes'] != null, 'Required key "LikesDislikes[dislikes]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'), 'Required key "LikesDislikes[updatedAt]" is missing from JSON.');
        return true;
      }());

      return LikesDislikes(
        likes: FoodRef.listFromJson(json[r'likes']),
        dislikes: FoodRef.listFromJson(json[r'dislikes']),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
      );
    }
    return null;
  }

  static List<LikesDislikes> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LikesDislikes>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LikesDislikes.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LikesDislikes> mapFromJson(dynamic json) {
    final map = <String, LikesDislikes>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LikesDislikes.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LikesDislikes-objects as value to a dart map
  static Map<String, List<LikesDislikes>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LikesDislikes>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LikesDislikes.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'likes',
    'dislikes',
    'updatedAt',
  };
}

