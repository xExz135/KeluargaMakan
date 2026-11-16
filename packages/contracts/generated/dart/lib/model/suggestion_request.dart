//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SuggestionRequest {
  /// Returns a new [SuggestionRequest] instance.
  SuggestionRequest({
    required this.eaters,
    required this.mealType,
    required this.timeAvailable,
    this.cuisine = const Optional.absent(),
    this.onlyWhatIHave = const Optional.absent(),
  });

  final EaterSelection eaters;

  final MealType mealType;

  final TimeAvailable timeAvailable;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<Cuisine?> cuisine;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> onlyWhatIHave;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SuggestionRequest &&
    other.eaters == eaters &&
    other.mealType == mealType &&
    other.timeAvailable == timeAvailable &&
    other.cuisine == cuisine &&
    other.onlyWhatIHave == onlyWhatIHave;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (eaters.hashCode) +
    (mealType.hashCode) +
    (timeAvailable.hashCode) +
    (cuisine == null ? 0 : cuisine!.hashCode) +
    (onlyWhatIHave == null ? 0 : onlyWhatIHave!.hashCode);

  @override
  String toString() => 'SuggestionRequest[eaters=$eaters, mealType=$mealType, timeAvailable=$timeAvailable, cuisine=$cuisine, onlyWhatIHave=$onlyWhatIHave]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'eaters'] = this.eaters;
      json[r'mealType'] = this.mealType;
      json[r'timeAvailable'] = this.timeAvailable;
    if (this.cuisine.isPresent) {
      final value = this.cuisine.value;
      json[r'cuisine'] = value;
    }
    if (this.onlyWhatIHave.isPresent) {
      final value = this.onlyWhatIHave.value;
      json[r'onlyWhatIHave'] = value;
    }
    return json;
  }

  /// Clones this instance of [SuggestionRequest] and returns a new one where some of the
  /// properties have changed.
  SuggestionRequest copyWith({
    EaterSelection? eaters,
    MealType? mealType,
    TimeAvailable? timeAvailable,
    Optional<Cuisine?>? cuisine,
    Optional<bool?>? onlyWhatIHave,
  }) => SuggestionRequest(
    eaters: eaters ?? this.eaters,
    mealType: mealType ?? this.mealType,
    timeAvailable: timeAvailable ?? this.timeAvailable,
    cuisine: cuisine ?? this.cuisine,
    onlyWhatIHave: onlyWhatIHave ?? this.onlyWhatIHave,
  );

  /// Returns a new [SuggestionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SuggestionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'eaters'), 'Required key "SuggestionRequest[eaters]" is missing from JSON.');
        assert(json[r'eaters'] != null, 'Required key "SuggestionRequest[eaters]" has a null value in JSON.');
        assert(json.containsKey(r'mealType'), 'Required key "SuggestionRequest[mealType]" is missing from JSON.');
        assert(json[r'mealType'] != null, 'Required key "SuggestionRequest[mealType]" has a null value in JSON.');
        assert(json.containsKey(r'timeAvailable'), 'Required key "SuggestionRequest[timeAvailable]" is missing from JSON.');
        assert(json[r'timeAvailable'] != null, 'Required key "SuggestionRequest[timeAvailable]" has a null value in JSON.');
        return true;
      }());

      return SuggestionRequest(
        eaters: EaterSelection.fromJson(json[r'eaters'])!,
        mealType: MealType.fromJson(json[r'mealType'])!,
        timeAvailable: TimeAvailable.fromJson(json[r'timeAvailable'])!,
        cuisine: json.containsKey(r'cuisine') ? Optional.present(Cuisine.fromJson(json[r'cuisine'])) : const Optional.absent(),
        onlyWhatIHave: json.containsKey(r'onlyWhatIHave') ? Optional.present(mapValueOfType<bool>(json, r'onlyWhatIHave')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SuggestionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SuggestionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SuggestionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SuggestionRequest> mapFromJson(dynamic json) {
    final map = <String, SuggestionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SuggestionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SuggestionRequest-objects as value to a dart map
  static Map<String, List<SuggestionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SuggestionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SuggestionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'eaters',
    'mealType',
    'timeAvailable',
  };
}

