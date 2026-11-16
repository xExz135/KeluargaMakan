//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class MealFeedbackInput {
  /// Returns a new [MealFeedbackInput] instance.
  MealFeedbackInput({
    required this.overall,
    this.members = const [],
  });

  final MealRating overall;

  final List<MemberMealFeedback> members;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MealFeedbackInput &&
    other.overall == overall &&
    _deepEquality.equals(other.members, members);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (overall.hashCode) +
    (members.hashCode);

  @override
  String toString() => 'MealFeedbackInput[overall=$overall, members=$members]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'overall'] = this.overall;
      json[r'members'] = this.members;
    return json;
  }

  /// Clones this instance of [MealFeedbackInput] and returns a new one where some of the
  /// properties have changed.
  MealFeedbackInput copyWith({
    MealRating? overall,
    List<MemberMealFeedback>? members,
  }) => MealFeedbackInput(
    overall: overall ?? this.overall,
    members: members ?? this.members,
  );

  /// Returns a new [MealFeedbackInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MealFeedbackInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'overall'), 'Required key "MealFeedbackInput[overall]" is missing from JSON.');
        assert(json[r'overall'] != null, 'Required key "MealFeedbackInput[overall]" has a null value in JSON.');
        assert(json.containsKey(r'members'), 'Required key "MealFeedbackInput[members]" is missing from JSON.');
        assert(json[r'members'] != null, 'Required key "MealFeedbackInput[members]" has a null value in JSON.');
        return true;
      }());

      return MealFeedbackInput(
        overall: MealRating.fromJson(json[r'overall'])!,
        members: MemberMealFeedback.listFromJson(json[r'members']),
      );
    }
    return null;
  }

  static List<MealFeedbackInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MealFeedbackInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MealFeedbackInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MealFeedbackInput> mapFromJson(dynamic json) {
    final map = <String, MealFeedbackInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MealFeedbackInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MealFeedbackInput-objects as value to a dart map
  static Map<String, List<MealFeedbackInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MealFeedbackInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MealFeedbackInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'overall',
    'members',
  };
}

