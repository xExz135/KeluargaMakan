//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class LocalizedText {
  /// Returns a new [LocalizedText] instance.
  LocalizedText({
    required this.id,
    required this.en,
  });

  final String id;

  final String en;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LocalizedText &&
    other.id == id &&
    other.en == en;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (en.hashCode);

  @override
  String toString() => 'LocalizedText[id=$id, en=$en]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'en'] = this.en;
    return json;
  }

  /// Clones this instance of [LocalizedText] and returns a new one where some of the
  /// properties have changed.
  LocalizedText copyWith({
    String? id,
    String? en,
  }) => LocalizedText(
    id: id ?? this.id,
    en: en ?? this.en,
  );

  /// Returns a new [LocalizedText] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LocalizedText? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "LocalizedText[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "LocalizedText[id]" has a null value in JSON.');
        assert(json.containsKey(r'en'), 'Required key "LocalizedText[en]" is missing from JSON.');
        assert(json[r'en'] != null, 'Required key "LocalizedText[en]" has a null value in JSON.');
        return true;
      }());

      return LocalizedText(
        id: mapValueOfType<String>(json, r'id')!,
        en: mapValueOfType<String>(json, r'en')!,
      );
    }
    return null;
  }

  static List<LocalizedText> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LocalizedText>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LocalizedText.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LocalizedText> mapFromJson(dynamic json) {
    final map = <String, LocalizedText>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LocalizedText.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LocalizedText-objects as value to a dart map
  static Map<String, List<LocalizedText>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LocalizedText>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LocalizedText.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'en',
  };
}

