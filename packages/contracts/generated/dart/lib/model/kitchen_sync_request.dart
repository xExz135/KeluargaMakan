//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenSyncRequest {
  /// Returns a new [KitchenSyncRequest] instance.
  KitchenSyncRequest({
    required this.cursor,
    this.changes = const [],
  });

  /// The `cursor` of the last sync response, or null for a first sync.
  final String? cursor;

  /// Oldest first.
  final List<KitchenChange> changes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenSyncRequest &&
    other.cursor == cursor &&
    _deepEquality.equals(other.changes, changes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (cursor == null ? 0 : cursor!.hashCode) +
    (changes.hashCode);

  @override
  String toString() => 'KitchenSyncRequest[cursor=$cursor, changes=$changes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.cursor != null) {
      json[r'cursor'] = this.cursor;
    } else {
      json[r'cursor'] = null;
    }
      json[r'changes'] = this.changes;
    return json;
  }

  /// Clones this instance of [KitchenSyncRequest] and returns a new one where some of the
  /// properties have changed.
  KitchenSyncRequest copyWith({
    String? cursor,
    bool cursorSetToNull = false,
    List<KitchenChange>? changes,
  }) => KitchenSyncRequest(
    cursor: cursorSetToNull ? null : cursor ?? this.cursor,
    changes: changes ?? this.changes,
  );

  /// Returns a new [KitchenSyncRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenSyncRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cursor'), 'Required key "KitchenSyncRequest[cursor]" is missing from JSON.');
        assert(json.containsKey(r'changes'), 'Required key "KitchenSyncRequest[changes]" is missing from JSON.');
        assert(json[r'changes'] != null, 'Required key "KitchenSyncRequest[changes]" has a null value in JSON.');
        return true;
      }());

      return KitchenSyncRequest(
        cursor: mapValueOfType<String>(json, r'cursor'),
        changes: KitchenChange.listFromJson(json[r'changes']),
      );
    }
    return null;
  }

  static List<KitchenSyncRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenSyncRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenSyncRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenSyncRequest> mapFromJson(dynamic json) {
    final map = <String, KitchenSyncRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenSyncRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenSyncRequest-objects as value to a dart map
  static Map<String, List<KitchenSyncRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenSyncRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenSyncRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cursor',
    'changes',
  };
}

