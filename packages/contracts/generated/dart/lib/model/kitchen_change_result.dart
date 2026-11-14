//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenChangeResult {
  /// Returns a new [KitchenChangeResult] instance.
  KitchenChangeResult({
    required this.changeId,
    required this.outcome,
    required this.itemId,
    required this.errorCode,
  });

  final String changeId;

  final KitchenChangeOutcome outcome;

  /// The server's item for the ingredient, or null when there is none.
  final String? itemId;

  /// Why a change was rejected, for example `validation_failed` or `kitchen_item_limit_reached`.
  final ErrorCode? errorCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenChangeResult &&
    other.changeId == changeId &&
    other.outcome == outcome &&
    other.itemId == itemId &&
    other.errorCode == errorCode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (changeId.hashCode) +
    (outcome.hashCode) +
    (itemId == null ? 0 : itemId!.hashCode) +
    (errorCode == null ? 0 : errorCode!.hashCode);

  @override
  String toString() => 'KitchenChangeResult[changeId=$changeId, outcome=$outcome, itemId=$itemId, errorCode=$errorCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'changeId'] = this.changeId;
      json[r'outcome'] = this.outcome;
    if (this.itemId != null) {
      json[r'itemId'] = this.itemId;
    } else {
      json[r'itemId'] = null;
    }
    if (this.errorCode != null) {
      json[r'errorCode'] = this.errorCode;
    } else {
      json[r'errorCode'] = null;
    }
    return json;
  }

  /// Clones this instance of [KitchenChangeResult] and returns a new one where some of the
  /// properties have changed.
  KitchenChangeResult copyWith({
    String? changeId,
    KitchenChangeOutcome? outcome,
    String? itemId,
    bool itemIdSetToNull = false,
    ErrorCode? errorCode,
    bool errorCodeSetToNull = false,
  }) => KitchenChangeResult(
    changeId: changeId ?? this.changeId,
    outcome: outcome ?? this.outcome,
    itemId: itemIdSetToNull ? null : itemId ?? this.itemId,
    errorCode: errorCodeSetToNull ? null : errorCode ?? this.errorCode,
  );

  /// Returns a new [KitchenChangeResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenChangeResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'changeId'), 'Required key "KitchenChangeResult[changeId]" is missing from JSON.');
        assert(json[r'changeId'] != null, 'Required key "KitchenChangeResult[changeId]" has a null value in JSON.');
        assert(json.containsKey(r'outcome'), 'Required key "KitchenChangeResult[outcome]" is missing from JSON.');
        assert(json[r'outcome'] != null, 'Required key "KitchenChangeResult[outcome]" has a null value in JSON.');
        assert(json.containsKey(r'itemId'), 'Required key "KitchenChangeResult[itemId]" is missing from JSON.');
        assert(json.containsKey(r'errorCode'), 'Required key "KitchenChangeResult[errorCode]" is missing from JSON.');
        return true;
      }());

      return KitchenChangeResult(
        changeId: mapValueOfType<String>(json, r'changeId')!,
        outcome: KitchenChangeOutcome.fromJson(json[r'outcome'])!,
        itemId: mapValueOfType<String>(json, r'itemId'),
        errorCode: ErrorCode.fromJson(json[r'errorCode']),
      );
    }
    return null;
  }

  static List<KitchenChangeResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenChangeResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenChangeResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenChangeResult> mapFromJson(dynamic json) {
    final map = <String, KitchenChangeResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenChangeResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenChangeResult-objects as value to a dart map
  static Map<String, List<KitchenChangeResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenChangeResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenChangeResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'changeId',
    'outcome',
    'itemId',
    'errorCode',
  };
}

