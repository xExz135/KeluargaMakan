//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class FoodRef {
  /// Returns a new [FoodRef] instance.
  FoodRef({
    required this.kind,
    required this.refId,
    required this.displayName,
  });

  final FoodRefKind kind;

  /// Identifier of a reference ingredient or library dish.
  final String refId;

  /// Reference display name, filled by the server.
  final LocalizedText displayName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FoodRef &&
    other.kind == kind &&
    other.refId == refId &&
    other.displayName == displayName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (refId.hashCode) +
    (displayName.hashCode);

  @override
  String toString() => 'FoodRef[kind=$kind, refId=$refId, displayName=$displayName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'refId'] = this.refId;
      json[r'displayName'] = this.displayName;
    return json;
  }

  /// Clones this instance of [FoodRef] and returns a new one where some of the
  /// properties have changed.
  FoodRef copyWith({
    FoodRefKind? kind,
    String? refId,
    LocalizedText? displayName,
  }) => FoodRef(
    kind: kind ?? this.kind,
    refId: refId ?? this.refId,
    displayName: displayName ?? this.displayName,
  );

  /// Returns a new [FoodRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FoodRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "FoodRef[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "FoodRef[kind]" has a null value in JSON.');
        assert(json.containsKey(r'refId'), 'Required key "FoodRef[refId]" is missing from JSON.');
        assert(json[r'refId'] != null, 'Required key "FoodRef[refId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "FoodRef[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null, 'Required key "FoodRef[displayName]" has a null value in JSON.');
        return true;
      }());

      return FoodRef(
        kind: FoodRefKind.fromJson(json[r'kind'])!,
        refId: mapValueOfType<String>(json, r'refId')!,
        displayName: LocalizedText.fromJson(json[r'displayName'])!,
      );
    }
    return null;
  }

  static List<FoodRef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FoodRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FoodRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FoodRef> mapFromJson(dynamic json) {
    final map = <String, FoodRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FoodRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FoodRef-objects as value to a dart map
  static Map<String, List<FoodRef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FoodRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FoodRef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'refId',
    'displayName',
  };
}

