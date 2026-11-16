//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SafetyReportReceipt {
  /// Returns a new [SafetyReportReceipt] instance.
  SafetyReportReceipt({
    required this.reportId,
    required this.receivedAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String reportId;

  final DateTime receivedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SafetyReportReceipt &&
    other.reportId == reportId &&
    other.receivedAt == receivedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reportId.hashCode) +
    (receivedAt.hashCode);

  @override
  String toString() => 'SafetyReportReceipt[reportId=$reportId, receivedAt=$receivedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'reportId'] = this.reportId;
      json[r'receivedAt'] = this.receivedAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SafetyReportReceipt] and returns a new one where some of the
  /// properties have changed.
  SafetyReportReceipt copyWith({
    String? reportId,
    DateTime? receivedAt,
  }) => SafetyReportReceipt(
    reportId: reportId ?? this.reportId,
    receivedAt: receivedAt ?? this.receivedAt,
  );

  /// Returns a new [SafetyReportReceipt] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SafetyReportReceipt? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'reportId'), 'Required key "SafetyReportReceipt[reportId]" is missing from JSON.');
        assert(json[r'reportId'] != null, 'Required key "SafetyReportReceipt[reportId]" has a null value in JSON.');
        assert(json.containsKey(r'receivedAt'), 'Required key "SafetyReportReceipt[receivedAt]" is missing from JSON.');
        assert(json[r'receivedAt'] != null, 'Required key "SafetyReportReceipt[receivedAt]" has a null value in JSON.');
        return true;
      }());

      return SafetyReportReceipt(
        reportId: mapValueOfType<String>(json, r'reportId')!,
        receivedAt: mapDateTime(json, r'receivedAt', r'')!,
      );
    }
    return null;
  }

  static List<SafetyReportReceipt> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SafetyReportReceipt>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SafetyReportReceipt.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SafetyReportReceipt> mapFromJson(dynamic json) {
    final map = <String, SafetyReportReceipt>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SafetyReportReceipt.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SafetyReportReceipt-objects as value to a dart map
  static Map<String, List<SafetyReportReceipt>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SafetyReportReceipt>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SafetyReportReceipt.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reportId',
    'receivedAt',
  };
}

