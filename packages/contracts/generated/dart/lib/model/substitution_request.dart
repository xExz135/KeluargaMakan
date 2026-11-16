//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SubstitutionRequest {
  /// Returns a new [SubstitutionRequest] instance.
  SubstitutionRequest({
    required this.eaters,
    this.adaptationId = const Optional.absent(),
  });

  final EaterSelection eaters;

  /// Substitutions for the adapted version a suggestion returned.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> adaptationId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubstitutionRequest &&
    other.eaters == eaters &&
    other.adaptationId == adaptationId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (eaters.hashCode) +
    (adaptationId == null ? 0 : adaptationId!.hashCode);

  @override
  String toString() => 'SubstitutionRequest[eaters=$eaters, adaptationId=$adaptationId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'eaters'] = this.eaters;
    if (this.adaptationId.isPresent) {
      final value = this.adaptationId.value;
      json[r'adaptationId'] = value;
    }
    return json;
  }

  /// Clones this instance of [SubstitutionRequest] and returns a new one where some of the
  /// properties have changed.
  SubstitutionRequest copyWith({
    EaterSelection? eaters,
    Optional<String?>? adaptationId,
  }) => SubstitutionRequest(
    eaters: eaters ?? this.eaters,
    adaptationId: adaptationId ?? this.adaptationId,
  );

  /// Returns a new [SubstitutionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubstitutionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'eaters'), 'Required key "SubstitutionRequest[eaters]" is missing from JSON.');
        assert(json[r'eaters'] != null, 'Required key "SubstitutionRequest[eaters]" has a null value in JSON.');
        return true;
      }());

      return SubstitutionRequest(
        eaters: EaterSelection.fromJson(json[r'eaters'])!,
        adaptationId: json.containsKey(r'adaptationId') ? Optional.present(mapValueOfType<String>(json, r'adaptationId')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SubstitutionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubstitutionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubstitutionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubstitutionRequest> mapFromJson(dynamic json) {
    final map = <String, SubstitutionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubstitutionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubstitutionRequest-objects as value to a dart map
  static Map<String, List<SubstitutionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubstitutionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubstitutionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'eaters',
  };
}

