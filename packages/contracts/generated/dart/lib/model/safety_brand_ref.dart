//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyBrandRef {
  /// Returns a new [SafetyBrandRef] instance.
  SafetyBrandRef({
    required this.brandId,
    required this.name,
  });

  /// Identifier of a reference ingredient or library dish.
  final String brandId;

  final String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyBrandRef &&
    other.brandId == brandId &&
    other.name == name;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (brandId.hashCode) +
    (name.hashCode);

  @override
  String toString() => 'SafetyBrandRef[brandId=$brandId, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'brandId'] = this.brandId;
      json[r'name'] = this.name;
    return json;
  }

  /// Clones this instance of [SafetyBrandRef] and returns a new one where some of the
  /// properties have changed.
  SafetyBrandRef copyWith({
    String? brandId,
    String? name,
  }) => SafetyBrandRef(
    brandId: brandId ?? this.brandId,
    name: name ?? this.name,
  );

  /// Returns a new [SafetyBrandRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyBrandRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brandId'), 'Required key "SafetyBrandRef[brandId]" is missing from JSON.');
        assert(json[r'brandId'] != null, 'Required key "SafetyBrandRef[brandId]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "SafetyBrandRef[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "SafetyBrandRef[name]" has a null value in JSON.');
        return true;
      }());

      return SafetyBrandRef(
        brandId: mapValueOfType<String>(json, r'brandId')!,
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<SafetyBrandRef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyBrandRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyBrandRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyBrandRef> mapFromJson(dynamic json) {
    final map = <String, SafetyBrandRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyBrandRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyBrandRef-objects as value to a dart map
  static Map<String, List<SafetyBrandRef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyBrandRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyBrandRef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brandId',
    'name',
  };
}

