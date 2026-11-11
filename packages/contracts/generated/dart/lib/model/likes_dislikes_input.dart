//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LikesDislikesInput {
  /// Returns a new [LikesDislikesInput] instance.
  LikesDislikesInput({
    this.likes = const [],
    this.dislikes = const [],
  });

  final List<FoodRefInput> likes;

  final List<FoodRefInput> dislikes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LikesDislikesInput &&
    _deepEquality.equals(other.likes, likes) &&
    _deepEquality.equals(other.dislikes, dislikes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (likes.hashCode) +
    (dislikes.hashCode);

  @override
  String toString() => 'LikesDislikesInput[likes=$likes, dislikes=$dislikes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'likes'] = this.likes;
      json[r'dislikes'] = this.dislikes;
    return json;
  }

  /// Clones this instance of [LikesDislikesInput] and returns a new one where some of the
  /// properties have changed.
  LikesDislikesInput copyWith({
    List<FoodRefInput>? likes,
    List<FoodRefInput>? dislikes,
  }) => LikesDislikesInput(
    likes: likes ?? this.likes,
    dislikes: dislikes ?? this.dislikes,
  );

  /// Returns a new [LikesDislikesInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LikesDislikesInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'likes'), 'Required key "LikesDislikesInput[likes]" is missing from JSON.');
        assert(json[r'likes'] != null, 'Required key "LikesDislikesInput[likes]" has a null value in JSON.');
        assert(json.containsKey(r'dislikes'), 'Required key "LikesDislikesInput[dislikes]" is missing from JSON.');
        assert(json[r'dislikes'] != null, 'Required key "LikesDislikesInput[dislikes]" has a null value in JSON.');
        return true;
      }());

      return LikesDislikesInput(
        likes: FoodRefInput.listFromJson(json[r'likes']),
        dislikes: FoodRefInput.listFromJson(json[r'dislikes']),
      );
    }
    return null;
  }

  static List<LikesDislikesInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LikesDislikesInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LikesDislikesInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LikesDislikesInput> mapFromJson(dynamic json) {
    final map = <String, LikesDislikesInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LikesDislikesInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LikesDislikesInput-objects as value to a dart map
  static Map<String, List<LikesDislikesInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LikesDislikesInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LikesDislikesInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'likes',
    'dislikes',
  };
}

