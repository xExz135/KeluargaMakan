//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SubstitutionLine {
  /// Returns a new [SubstitutionLine] instance.
  SubstitutionLine({
    required this.lineId,
    this.options = const [],
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String lineId;

  final List<SubstitutionOption> options;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubstitutionLine &&
    other.lineId == lineId &&
    _deepEquality.equals(other.options, options);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lineId.hashCode) +
    (options.hashCode);

  @override
  String toString() => 'SubstitutionLine[lineId=$lineId, options=$options]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lineId'] = this.lineId;
      json[r'options'] = this.options;
    return json;
  }

  /// Clones this instance of [SubstitutionLine] and returns a new one where some of the
  /// properties have changed.
  SubstitutionLine copyWith({
    String? lineId,
    List<SubstitutionOption>? options,
  }) => SubstitutionLine(
    lineId: lineId ?? this.lineId,
    options: options ?? this.options,
  );

  /// Returns a new [SubstitutionLine] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubstitutionLine? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'lineId'), 'Required key "SubstitutionLine[lineId]" is missing from JSON.');
        assert(json[r'lineId'] != null, 'Required key "SubstitutionLine[lineId]" has a null value in JSON.');
        assert(json.containsKey(r'options'), 'Required key "SubstitutionLine[options]" is missing from JSON.');
        assert(json[r'options'] != null, 'Required key "SubstitutionLine[options]" has a null value in JSON.');
        return true;
      }());

      return SubstitutionLine(
        lineId: mapValueOfType<String>(json, r'lineId')!,
        options: SubstitutionOption.listFromJson(json[r'options']),
      );
    }
    return null;
  }

  static List<SubstitutionLine> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubstitutionLine>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubstitutionLine.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubstitutionLine> mapFromJson(dynamic json) {
    final map = <String, SubstitutionLine>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubstitutionLine.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubstitutionLine-objects as value to a dart map
  static Map<String, List<SubstitutionLine>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubstitutionLine>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubstitutionLine.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lineId',
    'options',
  };
}

