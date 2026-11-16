//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class RecipeSafety {
  /// Returns a new [RecipeSafety] instance.
  RecipeSafety({
    required this.checkId,
    required this.checkedAt,
    required this.ruleSetVersion,
    required this.referenceVersion,
    this.members = const [],
    required this.halalStatus,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String checkId;

  final DateTime checkedAt;

  final String ruleSetVersion;

  final String referenceVersion;

  final List<MemberSafetyResult> members;

  final RecipeHalalStatus halalStatus;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecipeSafety &&
    other.checkId == checkId &&
    other.checkedAt == checkedAt &&
    other.ruleSetVersion == ruleSetVersion &&
    other.referenceVersion == referenceVersion &&
    _deepEquality.equals(other.members, members) &&
    other.halalStatus == halalStatus;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (checkId.hashCode) +
    (checkedAt.hashCode) +
    (ruleSetVersion.hashCode) +
    (referenceVersion.hashCode) +
    (members.hashCode) +
    (halalStatus.hashCode);

  @override
  String toString() => 'RecipeSafety[checkId=$checkId, checkedAt=$checkedAt, ruleSetVersion=$ruleSetVersion, referenceVersion=$referenceVersion, members=$members, halalStatus=$halalStatus]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'checkId'] = this.checkId;
      json[r'checkedAt'] = this.checkedAt.toUtc().toIso8601String();
      json[r'ruleSetVersion'] = this.ruleSetVersion;
      json[r'referenceVersion'] = this.referenceVersion;
      json[r'members'] = this.members;
      json[r'halalStatus'] = this.halalStatus;
    return json;
  }

  /// Clones this instance of [RecipeSafety] and returns a new one where some of the
  /// properties have changed.
  RecipeSafety copyWith({
    String? checkId,
    DateTime? checkedAt,
    String? ruleSetVersion,
    String? referenceVersion,
    List<MemberSafetyResult>? members,
    RecipeHalalStatus? halalStatus,
  }) => RecipeSafety(
    checkId: checkId ?? this.checkId,
    checkedAt: checkedAt ?? this.checkedAt,
    ruleSetVersion: ruleSetVersion ?? this.ruleSetVersion,
    referenceVersion: referenceVersion ?? this.referenceVersion,
    members: members ?? this.members,
    halalStatus: halalStatus ?? this.halalStatus,
  );

  /// Returns a new [RecipeSafety] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecipeSafety? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'checkId'), 'Required key "RecipeSafety[checkId]" is missing from JSON.');
        assert(json[r'checkId'] != null, 'Required key "RecipeSafety[checkId]" has a null value in JSON.');
        assert(json.containsKey(r'checkedAt'), 'Required key "RecipeSafety[checkedAt]" is missing from JSON.');
        assert(json[r'checkedAt'] != null, 'Required key "RecipeSafety[checkedAt]" has a null value in JSON.');
        assert(json.containsKey(r'ruleSetVersion'), 'Required key "RecipeSafety[ruleSetVersion]" is missing from JSON.');
        assert(json[r'ruleSetVersion'] != null, 'Required key "RecipeSafety[ruleSetVersion]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "RecipeSafety[referenceVersion]" is missing from JSON.');
        assert(json[r'referenceVersion'] != null, 'Required key "RecipeSafety[referenceVersion]" has a null value in JSON.');
        assert(json.containsKey(r'members'), 'Required key "RecipeSafety[members]" is missing from JSON.');
        assert(json[r'members'] != null, 'Required key "RecipeSafety[members]" has a null value in JSON.');
        assert(json.containsKey(r'halalStatus'), 'Required key "RecipeSafety[halalStatus]" is missing from JSON.');
        assert(json[r'halalStatus'] != null, 'Required key "RecipeSafety[halalStatus]" has a null value in JSON.');
        return true;
      }());

      return RecipeSafety(
        checkId: mapValueOfType<String>(json, r'checkId')!,
        checkedAt: mapDateTime(json, r'checkedAt', r'')!,
        ruleSetVersion: mapValueOfType<String>(json, r'ruleSetVersion')!,
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion')!,
        members: MemberSafetyResult.listFromJson(json[r'members']),
        halalStatus: RecipeHalalStatus.fromJson(json[r'halalStatus'])!,
      );
    }
    return null;
  }

  static List<RecipeSafety> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecipeSafety>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecipeSafety.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecipeSafety> mapFromJson(dynamic json) {
    final map = <String, RecipeSafety>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecipeSafety.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecipeSafety-objects as value to a dart map
  static Map<String, List<RecipeSafety>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecipeSafety>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecipeSafety.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checkId',
    'checkedAt',
    'ruleSetVersion',
    'referenceVersion',
    'members',
    'halalStatus',
  };
}

