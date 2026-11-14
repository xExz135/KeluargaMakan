//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenSyncResponse {
  /// Returns a new [KitchenSyncResponse] instance.
  KitchenSyncResponse({
    required this.cursor,
    required this.full,
    this.items = const [],
    this.removedItemIds = const [],
    this.results = const [],
    required this.maxItems,
    required this.referenceVersion,
  });

  /// Opaque; send it with the next sync.
  final String cursor;

  /// True when `items` is the whole kitchen (first sync, or a cursor too old to continue from); the phone then replaces its copy, keeping only changes still queued.
  final bool full;

  /// Items changed since the cursor, in KIT-03 category order.
  final List<KitchenItem> items;

  /// Items removed since the cursor (empty when `full`).
  final List<String> removedItemIds;

  /// One result per sent change, in the same order.
  final List<KitchenChangeResult> results;

  /// Minimum value: 1
  final int maxItems;

  final String? referenceVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenSyncResponse &&
    other.cursor == cursor &&
    other.full == full &&
    _deepEquality.equals(other.items, items) &&
    _deepEquality.equals(other.removedItemIds, removedItemIds) &&
    _deepEquality.equals(other.results, results) &&
    other.maxItems == maxItems &&
    other.referenceVersion == referenceVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (cursor.hashCode) +
    (full.hashCode) +
    (items.hashCode) +
    (removedItemIds.hashCode) +
    (results.hashCode) +
    (maxItems.hashCode) +
    (referenceVersion == null ? 0 : referenceVersion!.hashCode);

  @override
  String toString() => 'KitchenSyncResponse[cursor=$cursor, full=$full, items=$items, removedItemIds=$removedItemIds, results=$results, maxItems=$maxItems, referenceVersion=$referenceVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'cursor'] = this.cursor;
      json[r'full'] = this.full;
      json[r'items'] = this.items;
      json[r'removedItemIds'] = this.removedItemIds;
      json[r'results'] = this.results;
      json[r'maxItems'] = this.maxItems;
    if (this.referenceVersion != null) {
      json[r'referenceVersion'] = this.referenceVersion;
    } else {
      json[r'referenceVersion'] = null;
    }
    return json;
  }

  /// Clones this instance of [KitchenSyncResponse] and returns a new one where some of the
  /// properties have changed.
  KitchenSyncResponse copyWith({
    String? cursor,
    bool? full,
    List<KitchenItem>? items,
    List<String>? removedItemIds,
    List<KitchenChangeResult>? results,
    int? maxItems,
    String? referenceVersion,
    bool referenceVersionSetToNull = false,
  }) => KitchenSyncResponse(
    cursor: cursor ?? this.cursor,
    full: full ?? this.full,
    items: items ?? this.items,
    removedItemIds: removedItemIds ?? this.removedItemIds,
    results: results ?? this.results,
    maxItems: maxItems ?? this.maxItems,
    referenceVersion: referenceVersionSetToNull ? null : referenceVersion ?? this.referenceVersion,
  );

  /// Returns a new [KitchenSyncResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenSyncResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cursor'), 'Required key "KitchenSyncResponse[cursor]" is missing from JSON.');
        assert(json[r'cursor'] != null, 'Required key "KitchenSyncResponse[cursor]" has a null value in JSON.');
        assert(json.containsKey(r'full'), 'Required key "KitchenSyncResponse[full]" is missing from JSON.');
        assert(json[r'full'] != null, 'Required key "KitchenSyncResponse[full]" has a null value in JSON.');
        assert(json.containsKey(r'items'), 'Required key "KitchenSyncResponse[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "KitchenSyncResponse[items]" has a null value in JSON.');
        assert(json.containsKey(r'removedItemIds'), 'Required key "KitchenSyncResponse[removedItemIds]" is missing from JSON.');
        assert(json[r'removedItemIds'] != null, 'Required key "KitchenSyncResponse[removedItemIds]" has a null value in JSON.');
        assert(json.containsKey(r'results'), 'Required key "KitchenSyncResponse[results]" is missing from JSON.');
        assert(json[r'results'] != null, 'Required key "KitchenSyncResponse[results]" has a null value in JSON.');
        assert(json.containsKey(r'maxItems'), 'Required key "KitchenSyncResponse[maxItems]" is missing from JSON.');
        assert(json[r'maxItems'] != null, 'Required key "KitchenSyncResponse[maxItems]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "KitchenSyncResponse[referenceVersion]" is missing from JSON.');
        return true;
      }());

      return KitchenSyncResponse(
        cursor: mapValueOfType<String>(json, r'cursor')!,
        full: mapValueOfType<bool>(json, r'full')!,
        items: KitchenItem.listFromJson(json[r'items']),
        removedItemIds: json[r'removedItemIds'] is Iterable
            ? (json[r'removedItemIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        results: KitchenChangeResult.listFromJson(json[r'results']),
        maxItems: mapValueOfType<int>(json, r'maxItems')!,
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion'),
      );
    }
    return null;
  }

  static List<KitchenSyncResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenSyncResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenSyncResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenSyncResponse> mapFromJson(dynamic json) {
    final map = <String, KitchenSyncResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenSyncResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenSyncResponse-objects as value to a dart map
  static Map<String, List<KitchenSyncResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenSyncResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenSyncResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cursor',
    'full',
    'items',
    'removedItemIds',
    'results',
    'maxItems',
    'referenceVersion',
  };
}

