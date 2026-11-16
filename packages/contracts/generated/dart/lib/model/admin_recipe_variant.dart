//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdminRecipeVariant {
  /// Returns a new [AdminRecipeVariant] instance.
  AdminRecipeVariant({
    required this.variantId,
    required this.label,
    required this.separateBeforeStepId,
    this.omittedLineIds = const {},
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String variantId;

  final LocalizedText label;

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String separateBeforeStepId;

  final Set<String> omittedLineIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminRecipeVariant &&
    other.variantId == variantId &&
    other.label == label &&
    other.separateBeforeStepId == separateBeforeStepId &&
    _deepEquality.equals(other.omittedLineIds, omittedLineIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (variantId.hashCode) +
    (label.hashCode) +
    (separateBeforeStepId.hashCode) +
    (omittedLineIds.hashCode);

  @override
  String toString() => 'AdminRecipeVariant[variantId=$variantId, label=$label, separateBeforeStepId=$separateBeforeStepId, omittedLineIds=$omittedLineIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'variantId'] = this.variantId;
      json[r'label'] = this.label;
      json[r'separateBeforeStepId'] = this.separateBeforeStepId;
      json[r'omittedLineIds'] = this.omittedLineIds.toList(growable: false);
    return json;
  }

  /// Clones this instance of [AdminRecipeVariant] and returns a new one where some of the
  /// properties have changed.
  AdminRecipeVariant copyWith({
    String? variantId,
    LocalizedText? label,
    String? separateBeforeStepId,
    Set<String>? omittedLineIds,
  }) => AdminRecipeVariant(
    variantId: variantId ?? this.variantId,
    label: label ?? this.label,
    separateBeforeStepId: separateBeforeStepId ?? this.separateBeforeStepId,
    omittedLineIds: omittedLineIds ?? this.omittedLineIds,
  );

  /// Returns a new [AdminRecipeVariant] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminRecipeVariant? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'variantId'), 'Required key "AdminRecipeVariant[variantId]" is missing from JSON.');
        assert(json[r'variantId'] != null, 'Required key "AdminRecipeVariant[variantId]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "AdminRecipeVariant[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "AdminRecipeVariant[label]" has a null value in JSON.');
        assert(json.containsKey(r'separateBeforeStepId'), 'Required key "AdminRecipeVariant[separateBeforeStepId]" is missing from JSON.');
        assert(json[r'separateBeforeStepId'] != null, 'Required key "AdminRecipeVariant[separateBeforeStepId]" has a null value in JSON.');
        assert(json.containsKey(r'omittedLineIds'), 'Required key "AdminRecipeVariant[omittedLineIds]" is missing from JSON.');
        assert(json[r'omittedLineIds'] != null, 'Required key "AdminRecipeVariant[omittedLineIds]" has a null value in JSON.');
        return true;
      }());

      return AdminRecipeVariant(
        variantId: mapValueOfType<String>(json, r'variantId')!,
        label: LocalizedText.fromJson(json[r'label'])!,
        separateBeforeStepId: mapValueOfType<String>(json, r'separateBeforeStepId')!,
        omittedLineIds: json[r'omittedLineIds'] is Iterable
            ? (json[r'omittedLineIds'] as Iterable).cast<String>().toSet()
            : const {},
      );
    }
    return null;
  }

  static List<AdminRecipeVariant> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminRecipeVariant>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminRecipeVariant.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminRecipeVariant> mapFromJson(dynamic json) {
    final map = <String, AdminRecipeVariant>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminRecipeVariant.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminRecipeVariant-objects as value to a dart map
  static Map<String, List<AdminRecipeVariant>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminRecipeVariant>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminRecipeVariant.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'variantId',
    'label',
    'separateBeforeStepId',
    'omittedLineIds',
  };
}

