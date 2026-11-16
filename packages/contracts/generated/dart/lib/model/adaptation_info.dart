//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class AdaptationInfo {
  /// Returns a new [AdaptationInfo] instance.
  AdaptationInfo({
    required this.adaptationId,
    required this.aiAdapted,
    this.changes = const [],
    required this.expiresAt,
  });

  /// Household-bound (see Conventions).
  final String? adaptationId;

  final bool aiAdapted;

  final List<LocalizedText> changes;

  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdaptationInfo &&
    other.adaptationId == adaptationId &&
    other.aiAdapted == aiAdapted &&
    _deepEquality.equals(other.changes, changes) &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (adaptationId == null ? 0 : adaptationId!.hashCode) +
    (aiAdapted.hashCode) +
    (changes.hashCode) +
    (expiresAt == null ? 0 : expiresAt!.hashCode);

  @override
  String toString() => 'AdaptationInfo[adaptationId=$adaptationId, aiAdapted=$aiAdapted, changes=$changes, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.adaptationId != null) {
      json[r'adaptationId'] = this.adaptationId;
    } else {
      json[r'adaptationId'] = null;
    }
      json[r'aiAdapted'] = this.aiAdapted;
      json[r'changes'] = this.changes;
    if (this.expiresAt != null) {
      json[r'expiresAt'] = this.expiresAt!.toUtc().toIso8601String();
    } else {
      json[r'expiresAt'] = null;
    }
    return json;
  }

  /// Clones this instance of [AdaptationInfo] and returns a new one where some of the
  /// properties have changed.
  AdaptationInfo copyWith({
    String? adaptationId,
    bool adaptationIdSetToNull = false,
    bool? aiAdapted,
    List<LocalizedText>? changes,
    DateTime? expiresAt,
    bool expiresAtSetToNull = false,
  }) => AdaptationInfo(
    adaptationId: adaptationIdSetToNull ? null : adaptationId ?? this.adaptationId,
    aiAdapted: aiAdapted ?? this.aiAdapted,
    changes: changes ?? this.changes,
    expiresAt: expiresAtSetToNull ? null : expiresAt ?? this.expiresAt,
  );

  /// Returns a new [AdaptationInfo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdaptationInfo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'adaptationId'), 'Required key "AdaptationInfo[adaptationId]" is missing from JSON.');
        assert(json.containsKey(r'aiAdapted'), 'Required key "AdaptationInfo[aiAdapted]" is missing from JSON.');
        assert(json[r'aiAdapted'] != null, 'Required key "AdaptationInfo[aiAdapted]" has a null value in JSON.');
        assert(json.containsKey(r'changes'), 'Required key "AdaptationInfo[changes]" is missing from JSON.');
        assert(json[r'changes'] != null, 'Required key "AdaptationInfo[changes]" has a null value in JSON.');
        assert(json.containsKey(r'expiresAt'), 'Required key "AdaptationInfo[expiresAt]" is missing from JSON.');
        return true;
      }());

      return AdaptationInfo(
        adaptationId: mapValueOfType<String>(json, r'adaptationId'),
        aiAdapted: mapValueOfType<bool>(json, r'aiAdapted')!,
        changes: LocalizedText.listFromJson(json[r'changes']),
        expiresAt: mapDateTime(json, r'expiresAt', r''),
      );
    }
    return null;
  }

  static List<AdaptationInfo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdaptationInfo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdaptationInfo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdaptationInfo> mapFromJson(dynamic json) {
    final map = <String, AdaptationInfo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdaptationInfo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdaptationInfo-objects as value to a dart map
  static Map<String, List<AdaptationInfo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdaptationInfo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdaptationInfo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'adaptationId',
    'aiAdapted',
    'changes',
    'expiresAt',
  };
}

