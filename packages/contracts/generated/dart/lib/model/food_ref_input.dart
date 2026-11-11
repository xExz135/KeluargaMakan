//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class FoodRefInput {
  /// Returns a new [FoodRefInput] instance.
  FoodRefInput({
    required this.kind,
    required this.refId,
  });

  final FoodRefKind kind;

  /// Identifier of a reference ingredient or library dish.
  final String refId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FoodRefInput &&
    other.kind == kind &&
    other.refId == refId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (refId.hashCode);

  @override
  String toString() => 'FoodRefInput[kind=$kind, refId=$refId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'refId'] = this.refId;
    return json;
  }

  /// Clones this instance of [FoodRefInput] and returns a new one where some of the
  /// properties have changed.
  FoodRefInput copyWith({
    FoodRefKind? kind,
    String? refId,
  }) => FoodRefInput(
    kind: kind ?? this.kind,
    refId: refId ?? this.refId,
  );

  /// Returns a new [FoodRefInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FoodRefInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "FoodRefInput[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "FoodRefInput[kind]" has a null value in JSON.');
        assert(json.containsKey(r'refId'), 'Required key "FoodRefInput[refId]" is missing from JSON.');
        assert(json[r'refId'] != null, 'Required key "FoodRefInput[refId]" has a null value in JSON.');
        return true;
      }());

      return FoodRefInput(
        kind: FoodRefKind.fromJson(json[r'kind'])!,
        refId: mapValueOfType<String>(json, r'refId')!,
      );
    }
    return null;
  }

  static List<FoodRefInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FoodRefInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FoodRefInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FoodRefInput> mapFromJson(dynamic json) {
    final map = <String, FoodRefInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FoodRefInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FoodRefInput-objects as value to a dart map
  static Map<String, List<FoodRefInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FoodRefInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FoodRefInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'refId',
  };
}

