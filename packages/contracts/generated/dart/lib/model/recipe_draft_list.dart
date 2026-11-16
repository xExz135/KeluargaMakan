//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeDraftList {
  /// Returns a new [RecipeDraftList] instance.
  RecipeDraftList({
    this.items = const [],
    required this.nextCursor,
  });

  final List<RecipeDraft> items;

  /// Opaque page position issued by the server, never text a user typed.
  final String? nextCursor;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeDraftList &&
    _deepEquality.equals(other.items, items) &&
    other.nextCursor == nextCursor;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() => 'RecipeDraftList[items=$items, nextCursor=$nextCursor]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
    if (this.nextCursor != null) {
      json[r'nextCursor'] = this.nextCursor;
    } else {
      json[r'nextCursor'] = null;
    }
    return json;
  }

  /// Clones this instance of [RecipeDraftList] and returns a new one where some of the
  /// properties have changed.
  RecipeDraftList copyWith({
    List<RecipeDraft>? items,
    String? nextCursor,
    bool nextCursorSetToNull = false,
  }) => RecipeDraftList(
    items: items ?? this.items,
    nextCursor: nextCursorSetToNull ? null : nextCursor ?? this.nextCursor,
  );

  /// Returns a new [RecipeDraftList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeDraftList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "RecipeDraftList[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "RecipeDraftList[items]" has a null value in JSON.');
        assert(json.containsKey(r'nextCursor'), 'Required key "RecipeDraftList[nextCursor]" is missing from JSON.');
        return true;
      }());

      return RecipeDraftList(
        items: RecipeDraft.listFromJson(json[r'items']),
        nextCursor: mapValueOfType<String>(json, r'nextCursor'),
      );
    }
    return null;
  }

  static List<RecipeDraftList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeDraftList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeDraftList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeDraftList> mapFromJson(dynamic json) {
    final map = <String, RecipeDraftList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeDraftList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeDraftList-objects as value to a dart map
  static Map<String, List<RecipeDraftList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeDraftList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeDraftList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'nextCursor',
  };
}

