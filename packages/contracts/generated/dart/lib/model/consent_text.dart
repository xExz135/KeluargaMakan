//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ConsentText {
  /// Returns a new [ConsentText] instance.
  ConsentText({
    required this.purpose,
    required this.version,
    required this.language,
    required this.title,
    this.sections = const [],
    required this.effectiveDate,
    required this.isDraft,
  });

  final ConsentPurpose purpose;

  final String version;

  final Language language;

  final String title;

  final List<ConsentTextSection> sections;

  final DateTime effectiveDate;

  /// True until the text is approved by legal review.
  final bool isDraft;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConsentText &&
    other.purpose == purpose &&
    other.version == version &&
    other.language == language &&
    other.title == title &&
    _deepEquality.equals(other.sections, sections) &&
    other.effectiveDate == effectiveDate &&
    other.isDraft == isDraft;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (purpose.hashCode) +
    (version.hashCode) +
    (language.hashCode) +
    (title.hashCode) +
    (sections.hashCode) +
    (effectiveDate.hashCode) +
    (isDraft.hashCode);

  @override
  String toString() => 'ConsentText[purpose=$purpose, version=$version, language=$language, title=$title, sections=$sections, effectiveDate=$effectiveDate, isDraft=$isDraft]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'purpose'] = this.purpose;
      json[r'version'] = this.version;
      json[r'language'] = this.language;
      json[r'title'] = this.title;
      json[r'sections'] = this.sections;
      json[r'effectiveDate'] = _dateFormatter.format(this.effectiveDate);
      json[r'isDraft'] = this.isDraft;
    return json;
  }

  /// Clones this instance of [ConsentText] and returns a new one where some of the
  /// properties have changed.
  ConsentText copyWith({
    ConsentPurpose? purpose,
    String? version,
    Language? language,
    String? title,
    List<ConsentTextSection>? sections,
    DateTime? effectiveDate,
    bool? isDraft,
  }) => ConsentText(
    purpose: purpose ?? this.purpose,
    version: version ?? this.version,
    language: language ?? this.language,
    title: title ?? this.title,
    sections: sections ?? this.sections,
    effectiveDate: effectiveDate ?? this.effectiveDate,
    isDraft: isDraft ?? this.isDraft,
  );

  /// Returns a new [ConsentText] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConsentText? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'purpose'), 'Required key "ConsentText[purpose]" is missing from JSON.');
        assert(json[r'purpose'] != null, 'Required key "ConsentText[purpose]" has a null value in JSON.');
        assert(json.containsKey(r'version'), 'Required key "ConsentText[version]" is missing from JSON.');
        assert(json[r'version'] != null, 'Required key "ConsentText[version]" has a null value in JSON.');
        assert(json.containsKey(r'language'), 'Required key "ConsentText[language]" is missing from JSON.');
        assert(json[r'language'] != null, 'Required key "ConsentText[language]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "ConsentText[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "ConsentText[title]" has a null value in JSON.');
        assert(json.containsKey(r'sections'), 'Required key "ConsentText[sections]" is missing from JSON.');
        assert(json[r'sections'] != null, 'Required key "ConsentText[sections]" has a null value in JSON.');
        assert(json.containsKey(r'effectiveDate'), 'Required key "ConsentText[effectiveDate]" is missing from JSON.');
        assert(json[r'effectiveDate'] != null, 'Required key "ConsentText[effectiveDate]" has a null value in JSON.');
        assert(json.containsKey(r'isDraft'), 'Required key "ConsentText[isDraft]" is missing from JSON.');
        assert(json[r'isDraft'] != null, 'Required key "ConsentText[isDraft]" has a null value in JSON.');
        return true;
      }());

      return ConsentText(
        purpose: ConsentPurpose.fromJson(json[r'purpose'])!,
        version: mapValueOfType<String>(json, r'version')!,
        language: Language.fromJson(json[r'language'])!,
        title: mapValueOfType<String>(json, r'title')!,
        sections: ConsentTextSection.listFromJson(json[r'sections']),
        effectiveDate: mapDateTime(json, r'effectiveDate', r'')!,
        isDraft: mapValueOfType<bool>(json, r'isDraft')!,
      );
    }
    return null;
  }

  static List<ConsentText> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConsentText>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConsentText.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConsentText> mapFromJson(dynamic json) {
    final map = <String, ConsentText>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConsentText.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConsentText-objects as value to a dart map
  static Map<String, List<ConsentText>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConsentText>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConsentText.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'purpose',
    'version',
    'language',
    'title',
    'sections',
    'effectiveDate',
    'isDraft',
  };
}

