//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LibrarySearchResult {
  /// Returns a new [LibrarySearchResult] instance.
  LibrarySearchResult({
    this.items = const [],
    required this.nextCursor,
    required this.totalCount,
    required this.hiddenNotSafe,
    required this.libraryVersion,
  });

  /// Best match first; empty when nothing matched.
  final List<LibraryRecipeListItem> items;

  /// Opaque page position issued by the server, never text a user typed.
  final String? nextCursor;

  /// Matching recipes that are listed (hidden ones not counted).
  ///
  /// Minimum value: 0
  final int totalCount;

  final HiddenNotSafe hiddenNotSafe;

  final String libraryVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LibrarySearchResult &&
    _deepEquality.equals(other.items, items) &&
    other.nextCursor == nextCursor &&
    other.totalCount == totalCount &&
    other.hiddenNotSafe == hiddenNotSafe &&
    other.libraryVersion == libraryVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (nextCursor == null ? 0 : nextCursor!.hashCode) +
    (totalCount.hashCode) +
    (hiddenNotSafe.hashCode) +
    (libraryVersion.hashCode);

  @override
  String toString() => 'LibrarySearchResult[items=$items, nextCursor=$nextCursor, totalCount=$totalCount, hiddenNotSafe=$hiddenNotSafe, libraryVersion=$libraryVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
    if (this.nextCursor != null) {
      json[r'nextCursor'] = this.nextCursor;
    } else {
      json[r'nextCursor'] = null;
    }
      json[r'totalCount'] = this.totalCount;
      json[r'hiddenNotSafe'] = this.hiddenNotSafe;
      json[r'libraryVersion'] = this.libraryVersion;
    return json;
  }

  /// Clones this instance of [LibrarySearchResult] and returns a new one where some of the
  /// properties have changed.
  LibrarySearchResult copyWith({
    List<LibraryRecipeListItem>? items,
    String? nextCursor,
    bool nextCursorSetToNull = false,
    int? totalCount,
    HiddenNotSafe? hiddenNotSafe,
    String? libraryVersion,
  }) => LibrarySearchResult(
    items: items ?? this.items,
    nextCursor: nextCursorSetToNull ? null : nextCursor ?? this.nextCursor,
    totalCount: totalCount ?? this.totalCount,
    hiddenNotSafe: hiddenNotSafe ?? this.hiddenNotSafe,
    libraryVersion: libraryVersion ?? this.libraryVersion,
  );

  /// Returns a new [LibrarySearchResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LibrarySearchResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "LibrarySearchResult[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "LibrarySearchResult[items]" has a null value in JSON.');
        assert(json.containsKey(r'nextCursor'), 'Required key "LibrarySearchResult[nextCursor]" is missing from JSON.');
        assert(json.containsKey(r'totalCount'), 'Required key "LibrarySearchResult[totalCount]" is missing from JSON.');
        assert(json[r'totalCount'] != null, 'Required key "LibrarySearchResult[totalCount]" has a null value in JSON.');
        assert(json.containsKey(r'hiddenNotSafe'), 'Required key "LibrarySearchResult[hiddenNotSafe]" is missing from JSON.');
        assert(json[r'hiddenNotSafe'] != null, 'Required key "LibrarySearchResult[hiddenNotSafe]" has a null value in JSON.');
        assert(json.containsKey(r'libraryVersion'), 'Required key "LibrarySearchResult[libraryVersion]" is missing from JSON.');
        assert(json[r'libraryVersion'] != null, 'Required key "LibrarySearchResult[libraryVersion]" has a null value in JSON.');
        return true;
      }());

      return LibrarySearchResult(
        items: LibraryRecipeListItem.listFromJson(json[r'items']),
        nextCursor: mapValueOfType<String>(json, r'nextCursor'),
        totalCount: mapValueOfType<int>(json, r'totalCount')!,
        hiddenNotSafe: HiddenNotSafe.fromJson(json[r'hiddenNotSafe'])!,
        libraryVersion: mapValueOfType<String>(json, r'libraryVersion')!,
      );
    }
    return null;
  }

  static List<LibrarySearchResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LibrarySearchResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibrarySearchResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LibrarySearchResult> mapFromJson(dynamic json) {
    final map = <String, LibrarySearchResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LibrarySearchResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LibrarySearchResult-objects as value to a dart map
  static Map<String, List<LibrarySearchResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LibrarySearchResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LibrarySearchResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'nextCursor',
    'totalCount',
    'hiddenNotSafe',
    'libraryVersion',
  };
}

