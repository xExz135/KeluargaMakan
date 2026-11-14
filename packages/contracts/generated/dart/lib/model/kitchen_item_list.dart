//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenItemList {
  /// Returns a new [KitchenItemList] instance.
  KitchenItemList({
    this.items = const [],
    required this.maxItems,
    required this.referenceVersion,
  });

  /// In KIT-03 category order.
  final List<KitchenItem> items;

  /// The configured limit of items per household.
  ///
  /// Minimum value: 1
  final int maxItems;

  /// DAT-06 version of the reference data the names come from, or null when it is not available.
  final String? referenceVersion;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenItemList &&
    _deepEquality.equals(other.items, items) &&
    other.maxItems == maxItems &&
    other.referenceVersion == referenceVersion;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (maxItems.hashCode) +
    (referenceVersion == null ? 0 : referenceVersion!.hashCode);

  @override
  String toString() => 'KitchenItemList[items=$items, maxItems=$maxItems, referenceVersion=$referenceVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
      json[r'maxItems'] = this.maxItems;
    if (this.referenceVersion != null) {
      json[r'referenceVersion'] = this.referenceVersion;
    } else {
      json[r'referenceVersion'] = null;
    }
    return json;
  }

  /// Clones this instance of [KitchenItemList] and returns a new one where some of the
  /// properties have changed.
  KitchenItemList copyWith({
    List<KitchenItem>? items,
    int? maxItems,
    String? referenceVersion,
    bool referenceVersionSetToNull = false,
  }) => KitchenItemList(
    items: items ?? this.items,
    maxItems: maxItems ?? this.maxItems,
    referenceVersion: referenceVersionSetToNull ? null : referenceVersion ?? this.referenceVersion,
  );

  /// Returns a new [KitchenItemList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenItemList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "KitchenItemList[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "KitchenItemList[items]" has a null value in JSON.');
        assert(json.containsKey(r'maxItems'), 'Required key "KitchenItemList[maxItems]" is missing from JSON.');
        assert(json[r'maxItems'] != null, 'Required key "KitchenItemList[maxItems]" has a null value in JSON.');
        assert(json.containsKey(r'referenceVersion'), 'Required key "KitchenItemList[referenceVersion]" is missing from JSON.');
        return true;
      }());

      return KitchenItemList(
        items: KitchenItem.listFromJson(json[r'items']),
        maxItems: mapValueOfType<int>(json, r'maxItems')!,
        referenceVersion: mapValueOfType<String>(json, r'referenceVersion'),
      );
    }
    return null;
  }

  static List<KitchenItemList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenItemList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenItemList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenItemList> mapFromJson(dynamic json) {
    final map = <String, KitchenItemList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenItemList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenItemList-objects as value to a dart map
  static Map<String, List<KitchenItemList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenItemList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenItemList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'maxItems',
    'referenceVersion',
  };
}

