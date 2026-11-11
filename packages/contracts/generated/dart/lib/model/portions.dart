//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Portions {
  /// Returns a new [Portions] instance.
  Portions({
    required this.portionSize,
    required this.portionSizeIsDefault,
    required this.ricePortion,
    required this.ricePortionIsDefault,
  });

  final PortionSize portionSize;

  final bool portionSizeIsDefault;

  final PortionSize ricePortion;

  final bool ricePortionIsDefault;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Portions &&
    other.portionSize == portionSize &&
    other.portionSizeIsDefault == portionSizeIsDefault &&
    other.ricePortion == ricePortion &&
    other.ricePortionIsDefault == ricePortionIsDefault;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (portionSize.hashCode) +
    (portionSizeIsDefault.hashCode) +
    (ricePortion.hashCode) +
    (ricePortionIsDefault.hashCode);

  @override
  String toString() => 'Portions[portionSize=$portionSize, portionSizeIsDefault=$portionSizeIsDefault, ricePortion=$ricePortion, ricePortionIsDefault=$ricePortionIsDefault]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'portionSize'] = this.portionSize;
      json[r'portionSizeIsDefault'] = this.portionSizeIsDefault;
      json[r'ricePortion'] = this.ricePortion;
      json[r'ricePortionIsDefault'] = this.ricePortionIsDefault;
    return json;
  }

  /// Clones this instance of [Portions] and returns a new one where some of the
  /// properties have changed.
  Portions copyWith({
    PortionSize? portionSize,
    bool? portionSizeIsDefault,
    PortionSize? ricePortion,
    bool? ricePortionIsDefault,
  }) => Portions(
    portionSize: portionSize ?? this.portionSize,
    portionSizeIsDefault: portionSizeIsDefault ?? this.portionSizeIsDefault,
    ricePortion: ricePortion ?? this.ricePortion,
    ricePortionIsDefault: ricePortionIsDefault ?? this.ricePortionIsDefault,
  );

  /// Returns a new [Portions] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Portions? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'portionSize'), 'Required key "Portions[portionSize]" is missing from JSON.');
        assert(json[r'portionSize'] != null, 'Required key "Portions[portionSize]" has a null value in JSON.');
        assert(json.containsKey(r'portionSizeIsDefault'), 'Required key "Portions[portionSizeIsDefault]" is missing from JSON.');
        assert(json[r'portionSizeIsDefault'] != null, 'Required key "Portions[portionSizeIsDefault]" has a null value in JSON.');
        assert(json.containsKey(r'ricePortion'), 'Required key "Portions[ricePortion]" is missing from JSON.');
        assert(json[r'ricePortion'] != null, 'Required key "Portions[ricePortion]" has a null value in JSON.');
        assert(json.containsKey(r'ricePortionIsDefault'), 'Required key "Portions[ricePortionIsDefault]" is missing from JSON.');
        assert(json[r'ricePortionIsDefault'] != null, 'Required key "Portions[ricePortionIsDefault]" has a null value in JSON.');
        return true;
      }());

      return Portions(
        portionSize: PortionSize.fromJson(json[r'portionSize'])!,
        portionSizeIsDefault: mapValueOfType<bool>(json, r'portionSizeIsDefault')!,
        ricePortion: PortionSize.fromJson(json[r'ricePortion'])!,
        ricePortionIsDefault: mapValueOfType<bool>(json, r'ricePortionIsDefault')!,
      );
    }
    return null;
  }

  static List<Portions> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Portions>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Portions.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Portions> mapFromJson(dynamic json) {
    final map = <String, Portions>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Portions.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Portions-objects as value to a dart map
  static Map<String, List<Portions>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Portions>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Portions.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'portionSize',
    'portionSizeIsDefault',
    'ricePortion',
    'ricePortionIsDefault',
  };
}

