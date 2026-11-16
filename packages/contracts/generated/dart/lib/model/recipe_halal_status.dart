//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeHalalStatus {
  /// Returns a new [RecipeHalalStatus] instance.
  RecipeHalalStatus({
    required this.status,
    this.findings = const [],
  });

  final HalalStatus status;

  /// The ingredients behind `not_halal` or `check_label`; empty for `halal`.
  final List<SafetyFinding> findings;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeHalalStatus &&
    other.status == status &&
    _deepEquality.equals(other.findings, findings);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (findings.hashCode);

  @override
  String toString() => 'RecipeHalalStatus[status=$status, findings=$findings]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
      json[r'findings'] = this.findings;
    return json;
  }

  /// Clones this instance of [RecipeHalalStatus] and returns a new one where some of the
  /// properties have changed.
  RecipeHalalStatus copyWith({
    HalalStatus? status,
    List<SafetyFinding>? findings,
  }) => RecipeHalalStatus(
    status: status ?? this.status,
    findings: findings ?? this.findings,
  );

  /// Returns a new [RecipeHalalStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeHalalStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'), 'Required key "RecipeHalalStatus[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "RecipeHalalStatus[status]" has a null value in JSON.');
        assert(json.containsKey(r'findings'), 'Required key "RecipeHalalStatus[findings]" is missing from JSON.');
        assert(json[r'findings'] != null, 'Required key "RecipeHalalStatus[findings]" has a null value in JSON.');
        return true;
      }());

      return RecipeHalalStatus(
        status: HalalStatus.fromJson(json[r'status'])!,
        findings: SafetyFinding.listFromJson(json[r'findings']),
      );
    }
    return null;
  }

  static List<RecipeHalalStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeHalalStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeHalalStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeHalalStatus> mapFromJson(dynamic json) {
    final map = <String, RecipeHalalStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeHalalStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeHalalStatus-objects as value to a dart map
  static Map<String, List<RecipeHalalStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeHalalStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeHalalStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'findings',
  };
}

