//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminSubstitution {
  /// Returns a new [AdminSubstitution] instance.
  AdminSubstitution({
    required this.substitutionId,
    required this.lineId,
    this.replacements = const [],
    required this.effectNote,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String substitutionId;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String lineId;

  final List<AdminIngredientLine> replacements;

  final LocalizedText? effectNote;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminSubstitution &&
    other.substitutionId == substitutionId &&
    other.lineId == lineId &&
    _deepEquality.equals(other.replacements, replacements) &&
    other.effectNote == effectNote;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (substitutionId.hashCode) +
    (lineId.hashCode) +
    (replacements.hashCode) +
    (effectNote == null ? 0 : effectNote!.hashCode);

  @override
  String toString() => 'AdminSubstitution[substitutionId=$substitutionId, lineId=$lineId, replacements=$replacements, effectNote=$effectNote]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'substitutionId'] = this.substitutionId;
      json[r'lineId'] = this.lineId;
      json[r'replacements'] = this.replacements;
    if (this.effectNote != null) {
      json[r'effectNote'] = this.effectNote;
    } else {
      json[r'effectNote'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdminSubstitution] and returns a new one where some of the
  /// properties have changed.
  AdminSubstitution copyWith({
    String? substitutionId,
    String? lineId,
    List<AdminIngredientLine>? replacements,
    LocalizedText? effectNote,
    bool effectNoteSetToNull = false,
  }) => AdminSubstitution(
    substitutionId: substitutionId ?? this.substitutionId,
    lineId: lineId ?? this.lineId,
    replacements: replacements ?? this.replacements,
    effectNote: effectNoteSetToNull ? null : effectNote ?? this.effectNote,
  );

  /// Returns a new [AdminSubstitution] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminSubstitution? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'substitutionId'), 'Required key "AdminSubstitution[substitutionId]" is missing from JSON.');
        assert(json[r'substitutionId'] != null, 'Required key "AdminSubstitution[substitutionId]" has a null value in JSON.');
        assert(json.containsKey(r'lineId'), 'Required key "AdminSubstitution[lineId]" is missing from JSON.');
        assert(json[r'lineId'] != null, 'Required key "AdminSubstitution[lineId]" has a null value in JSON.');
        assert(json.containsKey(r'replacements'), 'Required key "AdminSubstitution[replacements]" is missing from JSON.');
        assert(json[r'replacements'] != null, 'Required key "AdminSubstitution[replacements]" has a null value in JSON.');
        assert(json.containsKey(r'effectNote'), 'Required key "AdminSubstitution[effectNote]" is missing from JSON.');
        return true;
      }());

      return AdminSubstitution(
        substitutionId: mapValueOfType<String>(json, r'substitutionId')!,
        lineId: mapValueOfType<String>(json, r'lineId')!,
        replacements: AdminIngredientLine.listFromJson(json[r'replacements']),
        effectNote: LocalizedText.fromJson(json[r'effectNote']),
      );
    }
    return null;
  }

  static List<AdminSubstitution> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminSubstitution>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminSubstitution.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminSubstitution> mapFromJson(dynamic json) {
    final map = <String, AdminSubstitution>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminSubstitution.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminSubstitution-objects as value to a dart map
  static Map<String, List<AdminSubstitution>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminSubstitution>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminSubstitution.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'substitutionId',
    'lineId',
    'replacements',
    'effectNote',
  };
}

