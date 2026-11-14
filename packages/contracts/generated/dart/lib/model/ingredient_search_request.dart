//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class IngredientSearchRequest {
  /// Returns a new [IngredientSearchRequest] instance.
  IngredientSearchRequest({
    required this.query,
    this.limit = const Optional.absent(),
  });

  /// What the user typed. Hidden or control characters are refused (400). The query is never stored or logged.
  final String query;

  /// At most this many results (default and upper limit from configuration).
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
  bool operator ==(Object other) => identical(this, other) || other is IngredientSearchRequest &&
    other.query == query &&
    other.limit == limit;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (query.hashCode) +
    (limit == null ? 0 : limit!.hashCode);

  @override
  String toString() => 'IngredientSearchRequest[query=$query, limit=$limit]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'query'] = this.query;
    if (this.limit.isPresent) {
      final value = this.limit.value;
      json[r'limit'] = value;
    }
    return json;
  }

  /// Clones this instance of [IngredientSearchRequest] and returns a new one where some of the
  /// properties have changed.
  IngredientSearchRequest copyWith({
    String? query,
    Optional<int?>? limit,
  }) => IngredientSearchRequest(
    query: query ?? this.query,
    limit: limit ?? this.limit,
  );

  /// Returns a new [IngredientSearchRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IngredientSearchRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'query'), 'Required key "IngredientSearchRequest[query]" is missing from JSON.');
        assert(json[r'query'] != null, 'Required key "IngredientSearchRequest[query]" has a null value in JSON.');
        return true;
      }());

      return IngredientSearchRequest(
        query: mapValueOfType<String>(json, r'query')!,
        limit: json.containsKey(r'limit') ? Optional.present(json[r'limit'] == null ? null : int.parse('${json[r'limit']}')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<IngredientSearchRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IngredientSearchRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IngredientSearchRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IngredientSearchRequest> mapFromJson(dynamic json) {
    final map = <String, IngredientSearchRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IngredientSearchRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IngredientSearchRequest-objects as value to a dart map
  static Map<String, List<IngredientSearchRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IngredientSearchRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IngredientSearchRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'query',
  };
}

