//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecognizedItem {
  /// Returns a new [RecognizedItem] instance.
  RecognizedItem({
    required this.id,
    required this.label,
    required this.ingredientId,
    required this.displayName,
    required this.confidence,
    this.options = const [],
    required this.kitchenItemId,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// The name as read from the photo, shown when there is no reference match.
  final String label;

  /// The reference ingredient the API matched by name, or null. A name that does not match is never guessed into an ID (AI-06).
  final String? ingredientId;

  final LocalizedText? displayName;

  final RecognitionConfidence confidence;

  /// Likely options for a low-confidence item, for example tempe or tofu (REC-03).
  final List<RecognitionOption> options;

  /// The saved kitchen item this matches, preferred over new ones (REC-05).
  final String? kitchenItemId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecognizedItem &&
    other.id == id &&
    other.label == label &&
    other.ingredientId == ingredientId &&
    other.displayName == displayName &&
    other.confidence == confidence &&
    _deepEquality.equals(other.options, options) &&
    other.kitchenItemId == kitchenItemId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (label.hashCode) +
    (ingredientId == null ? 0 : ingredientId!.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (confidence.hashCode) +
    (options.hashCode) +
    (kitchenItemId == null ? 0 : kitchenItemId!.hashCode);

  @override
  String toString() => 'RecognizedItem[id=$id, label=$label, ingredientId=$ingredientId, displayName=$displayName, confidence=$confidence, options=$options, kitchenItemId=$kitchenItemId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'label'] = this.label;
    if (this.ingredientId != null) {
      json[r'ingredientId'] = this.ingredientId;
    } else {
      json[r'ingredientId'] = null;
    }
    if (this.displayName != null) {
      json[r'displayName'] = this.displayName;
    } else {
      json[r'displayName'] = null;
    }
      json[r'confidence'] = this.confidence;
      json[r'options'] = this.options;
    if (this.kitchenItemId != null) {
      json[r'kitchenItemId'] = this.kitchenItemId;
    } else {
      json[r'kitchenItemId'] = null;
    }
    return json;
  }

  /// Clones this instance of [RecognizedItem] and returns a new one where some of the
  /// properties have changed.
  RecognizedItem copyWith({
    String? id,
    String? label,
    String? ingredientId,
    bool ingredientIdSetToNull = false,
    LocalizedText? displayName,
    bool displayNameSetToNull = false,
    RecognitionConfidence? confidence,
    List<RecognitionOption>? options,
    String? kitchenItemId,
    bool kitchenItemIdSetToNull = false,
  }) => RecognizedItem(
    id: id ?? this.id,
    label: label ?? this.label,
    ingredientId: ingredientIdSetToNull ? null : ingredientId ?? this.ingredientId,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    confidence: confidence ?? this.confidence,
    options: options ?? this.options,
    kitchenItemId: kitchenItemIdSetToNull ? null : kitchenItemId ?? this.kitchenItemId,
  );

  /// Returns a new [RecognizedItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecognizedItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "RecognizedItem[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "RecognizedItem[id]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "RecognizedItem[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "RecognizedItem[label]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "RecognizedItem[ingredientId]" is missing from JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "RecognizedItem[displayName]" is missing from JSON.');
        assert(json.containsKey(r'confidence'), 'Required key "RecognizedItem[confidence]" is missing from JSON.');
        assert(json[r'confidence'] != null, 'Required key "RecognizedItem[confidence]" has a null value in JSON.');
        assert(json.containsKey(r'options'), 'Required key "RecognizedItem[options]" is missing from JSON.');
        assert(json[r'options'] != null, 'Required key "RecognizedItem[options]" has a null value in JSON.');
        assert(json.containsKey(r'kitchenItemId'), 'Required key "RecognizedItem[kitchenItemId]" is missing from JSON.');
        return true;
      }());

      return RecognizedItem(
        id: mapValueOfType<String>(json, r'id')!,
        label: mapValueOfType<String>(json, r'label')!,
        ingredientId: mapValueOfType<String>(json, r'ingredientId'),
        displayName: LocalizedText.fromJson(json[r'displayName']),
        confidence: RecognitionConfidence.fromJson(json[r'confidence'])!,
        options: RecognitionOption.listFromJson(json[r'options']),
        kitchenItemId: mapValueOfType<String>(json, r'kitchenItemId'),
      );
    }
    return null;
  }

  static List<RecognizedItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecognizedItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecognizedItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecognizedItem> mapFromJson(dynamic json) {
    final map = <String, RecognizedItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecognizedItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecognizedItem-objects as value to a dart map
  static Map<String, List<RecognizedItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecognizedItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecognizedItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'label',
    'ingredientId',
    'displayName',
    'confidence',
    'options',
    'kitchenItemId',
  };
}

