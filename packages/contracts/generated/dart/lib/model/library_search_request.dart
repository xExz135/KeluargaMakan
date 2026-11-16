//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LibrarySearchRequest {
  /// Returns a new [LibrarySearchRequest] instance.
  LibrarySearchRequest({
    required this.eaters,
    this.query = const Optional.absent(),
    this.regionIds = const Optional.present(const {}),
    this.mealTypes = const Optional.present(const {}),
    this.timeAvailable = const Optional.absent(),
    this.includeNotSafe = const Optional.absent(),
    this.cursor = const Optional.absent(),
    this.limit = const Optional.absent(),
  });

  final EaterSelection eaters;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> query;

  final Optional<Set<String>?> regionIds;

  final Optional<Set<MealType>?> mealTypes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<TimeAvailable?> timeAvailable;

  /// Also list recipes that are Not safe for a selected member, with that result (\"Tampilkan\"). Default false.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> includeNotSafe;

  /// Opaque page position issued by the server, never text a user typed.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> cursor;

  /// Items per page (default and upper limit from configuration).
  ///
  /// Minimum value: 1
  /// Maximum value: 50
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> limit;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LibrarySearchRequest &&
    other.eaters == eaters &&
    other.query == query &&
    _deepEquality.equals(other.regionIds, regionIds) &&
    _deepEquality.equals(other.mealTypes, mealTypes) &&
    other.timeAvailable == timeAvailable &&
    other.includeNotSafe == includeNotSafe &&
    other.cursor == cursor &&
    other.limit == limit;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (eaters.hashCode) +
    (query == null ? 0 : query!.hashCode) +
    (regionIds.hashCode) +
    (mealTypes.hashCode) +
    (timeAvailable == null ? 0 : timeAvailable!.hashCode) +
    (includeNotSafe == null ? 0 : includeNotSafe!.hashCode) +
    (cursor == null ? 0 : cursor!.hashCode) +
    (limit == null ? 0 : limit!.hashCode);

  @override
  String toString() => 'LibrarySearchRequest[eaters=$eaters, query=$query, regionIds=$regionIds, mealTypes=$mealTypes, timeAvailable=$timeAvailable, includeNotSafe=$includeNotSafe, cursor=$cursor, limit=$limit]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'eaters'] = this.eaters;
    if (this.query.isPresent) {
      final value = this.query.value;
      json[r'query'] = value;
    }
    if (this.regionIds.isPresent) {
      final value = this.regionIds.value;
      json[r'regionIds'] = value == null ? null : value.toList(growable: false);
    }
    if (this.mealTypes.isPresent) {
      final value = this.mealTypes.value;
      json[r'mealTypes'] = value == null ? null : value.toList(growable: false);
    }
    if (this.timeAvailable.isPresent) {
      final value = this.timeAvailable.value;
      json[r'timeAvailable'] = value;
    }
    if (this.includeNotSafe.isPresent) {
      final value = this.includeNotSafe.value;
      json[r'includeNotSafe'] = value;
    }
    if (this.cursor.isPresent) {
      final value = this.cursor.value;
      json[r'cursor'] = value;
    }
    if (this.limit.isPresent) {
      final value = this.limit.value;
      json[r'limit'] = value;
    }
    return json;
  }

  /// Clones this instance of [LibrarySearchRequest] and returns a new one where some of the
  /// properties have changed.
  LibrarySearchRequest copyWith({
    EaterSelection? eaters,
    Optional<String?>? query,
    Optional<Set<String>?>? regionIds,
    Optional<Set<MealType>?>? mealTypes,
    Optional<TimeAvailable?>? timeAvailable,
    Optional<bool?>? includeNotSafe,
    Optional<String?>? cursor,
    Optional<int?>? limit,
  }) => LibrarySearchRequest(
    eaters: eaters ?? this.eaters,
    query: query ?? this.query,
    regionIds: regionIds ?? this.regionIds,
    mealTypes: mealTypes ?? this.mealTypes,
    timeAvailable: timeAvailable ?? this.timeAvailable,
    includeNotSafe: includeNotSafe ?? this.includeNotSafe,
    cursor: cursor ?? this.cursor,
    limit: limit ?? this.limit,
  );

  /// Returns a new [LibrarySearchRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LibrarySearchRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'eaters'), 'Required key "LibrarySearchRequest[eaters]" is missing from JSON.');
        assert(json[r'eaters'] != null, 'Required key "LibrarySearchRequest[eaters]" has a null value in JSON.');
        return true;
      }());

      return LibrarySearchRequest(
        eaters: EaterSelection.fromJson(json[r'eaters'])!,
        query: json.containsKey(r'query') ? Optional.present(mapValueOfType<String>(json, r'query')) : const Optional.absent(),
        regionIds: json.containsKey(r'regionIds') ? Optional.present(json[r'regionIds'] is Iterable
            ? (json[r'regionIds'] as Iterable).cast<String>().toSet()
            : const {}) : const Optional.absent(),
        mealTypes: json.containsKey(r'mealTypes') ? Optional.present(MealType.listFromJson(json[r'mealTypes']).toSet()) : const Optional.absent(),
        timeAvailable: json.containsKey(r'timeAvailable') ? Optional.present(TimeAvailable.fromJson(json[r'timeAvailable'])) : const Optional.absent(),
        includeNotSafe: json.containsKey(r'includeNotSafe') ? Optional.present(mapValueOfType<bool>(json, r'includeNotSafe')) : const Optional.absent(),
        cursor: json.containsKey(r'cursor') ? Optional.present(mapValueOfType<String>(json, r'cursor')) : const Optional.absent(),
        limit: json.containsKey(r'limit') ? Optional.present(json[r'limit'] == null ? null : int.parse('${json[r'limit']}')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<LibrarySearchRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LibrarySearchRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibrarySearchRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LibrarySearchRequest> mapFromJson(dynamic json) {
    final map = <String, LibrarySearchRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LibrarySearchRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LibrarySearchRequest-objects as value to a dart map
  static Map<String, List<LibrarySearchRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LibrarySearchRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LibrarySearchRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'eaters',
  };
}

