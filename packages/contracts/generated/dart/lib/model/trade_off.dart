//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class TradeOff {
  /// Returns a new [TradeOff] instance.
  TradeOff({
    required this.kind,
    this.memberIds = const {},
    this.otherMemberIds = const {},
    required this.ingredient,
    required this.text,
  });

  final TradeOffKind kind;

  final Set<String> memberIds;

  final Set<String> otherMemberIds;

  final LocalizedText? ingredient;

  final LocalizedText? text;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TradeOff &&
    other.kind == kind &&
    _deepEquality.equals(other.memberIds, memberIds) &&
    _deepEquality.equals(other.otherMemberIds, otherMemberIds) &&
    other.ingredient == ingredient &&
    other.text == text;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (memberIds.hashCode) +
    (otherMemberIds.hashCode) +
    (ingredient == null ? 0 : ingredient!.hashCode) +
    (text == null ? 0 : text!.hashCode);

  @override
  String toString() => 'TradeOff[kind=$kind, memberIds=$memberIds, otherMemberIds=$otherMemberIds, ingredient=$ingredient, text=$text]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'memberIds'] = this.memberIds.toList(growable: false);
      json[r'otherMemberIds'] = this.otherMemberIds.toList(growable: false);
    if (this.ingredient != null) {
      json[r'ingredient'] = this.ingredient;
    } else {
      json[r'ingredient'] = null;
    }
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
    return json;
  }

  /// Clones this instance of [TradeOff] and returns a new one where some of the
  /// properties have changed.
  TradeOff copyWith({
    TradeOffKind? kind,
    Set<String>? memberIds,
    Set<String>? otherMemberIds,
    LocalizedText? ingredient,
    bool ingredientSetToNull = false,
    LocalizedText? text,
    bool textSetToNull = false,
  }) => TradeOff(
    kind: kind ?? this.kind,
    memberIds: memberIds ?? this.memberIds,
    otherMemberIds: otherMemberIds ?? this.otherMemberIds,
    ingredient: ingredientSetToNull ? null : ingredient ?? this.ingredient,
    text: textSetToNull ? null : text ?? this.text,
  );

  /// Returns a new [TradeOff] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TradeOff? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "TradeOff[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "TradeOff[kind]" has a null value in JSON.');
        assert(json.containsKey(r'memberIds'), 'Required key "TradeOff[memberIds]" is missing from JSON.');
        assert(json[r'memberIds'] != null, 'Required key "TradeOff[memberIds]" has a null value in JSON.');
        assert(json.containsKey(r'otherMemberIds'), 'Required key "TradeOff[otherMemberIds]" is missing from JSON.');
        assert(json[r'otherMemberIds'] != null, 'Required key "TradeOff[otherMemberIds]" has a null value in JSON.');
        assert(json.containsKey(r'ingredient'), 'Required key "TradeOff[ingredient]" is missing from JSON.');
        assert(json.containsKey(r'text'), 'Required key "TradeOff[text]" is missing from JSON.');
        return true;
      }());

      return TradeOff(
        kind: TradeOffKind.fromJson(json[r'kind'])!,
        memberIds: json[r'memberIds'] is Iterable
            ? (json[r'memberIds'] as Iterable).cast<String>().toSet()
            : const {},
        otherMemberIds: json[r'otherMemberIds'] is Iterable
            ? (json[r'otherMemberIds'] as Iterable).cast<String>().toSet()
            : const {},
        ingredient: LocalizedText.fromJson(json[r'ingredient']),
        text: LocalizedText.fromJson(json[r'text']),
      );
    }
    return null;
  }

  static List<TradeOff> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TradeOff>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TradeOff.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TradeOff> mapFromJson(dynamic json) {
    final map = <String, TradeOff>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TradeOff.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TradeOff-objects as value to a dart map
  static Map<String, List<TradeOff>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TradeOff>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TradeOff.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'memberIds',
    'otherMemberIds',
    'ingredient',
    'text',
  };
}

