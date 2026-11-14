//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecognitionResult {
  /// Returns a new [RecognitionResult] instance.
  RecognitionResult({
    this.items = const [],
    required this.referenceVersion,
  });

  /// Items matching saved kitchen items first (REC-05). Empty when nothing was recognized.
  final List<RecognizedItem> items;

  final String referenceVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecognitionResult &&
    _deepEquality.equals(other.items, items) &&
    other.referenceVersion == referenceVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (referenceVersion.hashCode);

  @override
  String toString() => 'RecognitionResult[items=$items, referenceVersion=$referenceVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
      json[r'referenceVersion'] = this.referenceVersion;
    return json;
  }

  /// Clones this instance of [RecognitionResult] and returns a new one where some of the
  /// properties have changed.
  RecognitionResult copyWith({
    List<RecognizedItem>? items,
    String? referenceVersion,
  }) => RecognitionResult(
    items: items ?? this.items,
    referenceVersion: referenceVersion ?? this.referenceVersion,
  );

  /// Returns a new [RecognitionResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecognitionResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "RecognitionResult[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "RecognitionResult[items]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "RecognitionResult[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "RecognitionResult[referenceVersion]" has a null value in JSON.');
        return true;
      }());

      return RecognitionResult(
        items: RecognizedItem.listFromJson(json[r'items']),
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
      );
    }
    return null;
  }

  static List<RecognitionResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecognitionResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecognitionResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecognitionResult> mapFromJson(dynamic json) {
    final map = <String, RecognitionResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecognitionResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecognitionResult-objects as value to a dart map
  static Map<String, List<RecognitionResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecognitionResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecognitionResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'referenceVersion',
  };
}

