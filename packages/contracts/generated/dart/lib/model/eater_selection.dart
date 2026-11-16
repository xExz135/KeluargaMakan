//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class EaterSelection {
  /// Returns a new [EaterSelection] instance.
  EaterSelection({
    required this.mode,
    this.memberIds = const {},
  });

  final EaterMode mode;

  final Set<String> memberIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EaterSelection &&
    other.mode == mode &&
    _deepEquality.equals(other.memberIds, memberIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (mode.hashCode) +
    (memberIds.hashCode);

  @override
  String toString() => 'EaterSelection[mode=$mode, memberIds=$memberIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'mode'] = this.mode;
      json[r'memberIds'] = this.memberIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [EaterSelection] and returns a new one where some of the
  /// properties have changed.
  EaterSelection copyWith({
    EaterMode? mode,
    Set<String>? memberIds,
  }) => EaterSelection(
    mode: mode ?? this.mode,
    memberIds: memberIds ?? this.memberIds,
  );

  /// Returns a new [EaterSelection] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EaterSelection? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'mode'), 'Required key "EaterSelection[mode]" is missing from JSON.');
        assert(json[r'mode'] != null, 'Required key "EaterSelection[mode]" has a null value in JSON.');
        assert(json.containsKey(r'memberIds'), 'Required key "EaterSelection[memberIds]" is missing from JSON.');
        assert(json[r'memberIds'] != null, 'Required key "EaterSelection[memberIds]" has a null value in JSON.');
        return true;
      }());

      return EaterSelection(
        mode: EaterMode.fromJson(json[r'mode'])!,
        memberIds: json[r'memberIds'] is Iterable
            ? (json[r'memberIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<EaterSelection> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EaterSelection>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EaterSelection.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EaterSelection> mapFromJson(dynamic json) {
    final map = <String, EaterSelection>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EaterSelection.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EaterSelection-objects as value to a dart map
  static Map<String, List<EaterSelection>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EaterSelection>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EaterSelection.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'mode',
    'memberIds',
  };
}

