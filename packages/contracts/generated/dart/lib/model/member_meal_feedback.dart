//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class MemberMealFeedback {
  /// Returns a new [MemberMealFeedback] instance.
  MemberMealFeedback({
    required this.memberId,
    required this.rating,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String memberId;

  final MemberMealRating rating;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MemberMealFeedback &&
    other.memberId == memberId &&
    other.rating == rating;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memberId.hashCode) +
    (rating.hashCode);

  @override
  String toString() => 'MemberMealFeedback[memberId=$memberId, rating=$rating]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'memberId'] = this.memberId;
      json[r'rating'] = this.rating;
    return json;
  }

  /// Clones this instance of [MemberMealFeedback] and returns a new one where some of the
  /// properties have changed.
  MemberMealFeedback copyWith({
    String? memberId,
    MemberMealRating? rating,
  }) => MemberMealFeedback(
    memberId: memberId ?? this.memberId,
    rating: rating ?? this.rating,
  );

  /// Returns a new [MemberMealFeedback] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemberMealFeedback? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'memberId'), 'Required key "MemberMealFeedback[memberId]" is missing from JSON.');
        assert(json[r'memberId'] != null, 'Required key "MemberMealFeedback[memberId]" has a null value in JSON.');
        assert(json.containsKey(r'rating'), 'Required key "MemberMealFeedback[rating]" is missing from JSON.');
        assert(json[r'rating'] != null, 'Required key "MemberMealFeedback[rating]" has a null value in JSON.');
        return true;
      }());

      return MemberMealFeedback(
        memberId: mapValueOfType<String>(json, r'memberId')!,
        rating: MemberMealRating.fromJson(json[r'rating'])!,
      );
    }
    return null;
  }

  static List<MemberMealFeedback> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MemberMealFeedback>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemberMealFeedback.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemberMealFeedback> mapFromJson(dynamic json) {
    final map = <String, MemberMealFeedback>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemberMealFeedback.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemberMealFeedback-objects as value to a dart map
  static Map<String, List<MemberMealFeedback>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MemberMealFeedback>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemberMealFeedback.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'memberId',
    'rating',
  };
}

