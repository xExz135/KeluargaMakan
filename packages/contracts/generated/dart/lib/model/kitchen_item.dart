//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenItem {
  /// Returns a new [KitchenItem] instance.
  KitchenItem({
    required this.id,
    required this.ingredientId,
    required this.isCustom,
    required this.displayName,
    required this.customName,
    required this.category,
    required this.state,
    required this.quantity,
    required this.brand,
    required this.isDefaultStaple,
    required this.usageRank,
    required this.changedAt,
    required this.createdAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  /// Identifier of a reference ingredient or library dish.
  final String? ingredientId;

  /// True exactly when `ingredientId` is null (KIT-05 flag).
  final bool isCustom;

  final LocalizedText? displayName;

  /// A custom ingredient's name as the user typed it (KIT-05), stored in Unicode NFC with surrounding spaces removed. Text with control, format or private-use characters is refused. Names that differ only in case, accents, punctuation or spacing are the same ingredient.
  final String? customName;

  final KitchenCategory category;

  final KitchenItemState state;

  final KitchenQuantity? quantity;

  final KitchenBrand? brand;

  /// Created with the household as a default staple (KIT-07, ACC-05).
  final bool isDefaultStaple;

  /// KIT-06: 1 is the most used item in its category. A use is a change of state (it ran out, or came back after being out), and older uses count less (configured half-life). Null when the item has no recent use; clients then fall back to their own order.
  ///
  /// Minimum value: 1
  final int? usageRank;

  final DateTime changedAt;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenItem &&
    other.id == id &&
    other.ingredientId == ingredientId &&
    other.isCustom == isCustom &&
    other.displayName == displayName &&
    other.customName == customName &&
    other.category == category &&
    other.state == state &&
    other.quantity == quantity &&
    other.brand == brand &&
    other.isDefaultStaple == isDefaultStaple &&
    other.usageRank == usageRank &&
    other.changedAt == changedAt &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (ingredientId == null ? 0 : ingredientId!.hashCode) +
    (isCustom.hashCode) +
    (displayName == null ? 0 : displayName!.hashCode) +
    (customName == null ? 0 : customName!.hashCode) +
    (category.hashCode) +
    (state.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (brand == null ? 0 : brand!.hashCode) +
    (isDefaultStaple.hashCode) +
    (usageRank == null ? 0 : usageRank!.hashCode) +
    (changedAt.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'KitchenItem[id=$id, ingredientId=$ingredientId, isCustom=$isCustom, displayName=$displayName, customName=$customName, category=$category, state=$state, quantity=$quantity, brand=$brand, isDefaultStaple=$isDefaultStaple, usageRank=$usageRank, changedAt=$changedAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.ingredientId != null) {
      json[r'ingredientId'] = this.ingredientId;
    } else {
      json[r'ingredientId'] = null;
    }
      json[r'isCustom'] = this.isCustom;
    if (this.displayName != null) {
      json[r'displayName'] = this.displayName;
    } else {
      json[r'displayName'] = null;
    }
    if (this.customName != null) {
      json[r'customName'] = this.customName;
    } else {
      json[r'customName'] = null;
    }
      json[r'category'] = this.category;
      json[r'state'] = this.state;
    if (this.quantity != null) {
      json[r'quantity'] = this.quantity;
    } else {
      json[r'quantity'] = null;
    }
    if (this.brand != null) {
      json[r'brand'] = this.brand;
    } else {
      json[r'brand'] = null;
    }
      json[r'isDefaultStaple'] = this.isDefaultStaple;
    if (this.usageRank != null) {
      json[r'usageRank'] = this.usageRank;
    } else {
      json[r'usageRank'] = null;
    }
      json[r'changedAt'] = this.changedAt.toUtc().toIso8601String();
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [KitchenItem] and returns a new one where some of the
  /// properties have changed.
  KitchenItem copyWith({
    String? id,
    String? ingredientId,
    bool ingredientIdSetToNull = false,
    bool? isCustom,
    LocalizedText? displayName,
    bool displayNameSetToNull = false,
    String? customName,
    bool customNameSetToNull = false,
    KitchenCategory? category,
    KitchenItemState? state,
    KitchenQuantity? quantity,
    bool quantitySetToNull = false,
    KitchenBrand? brand,
    bool brandSetToNull = false,
    bool? isDefaultStaple,
    int? usageRank,
    bool usageRankSetToNull = false,
    DateTime? changedAt,
    DateTime? createdAt,
  }) => KitchenItem(
    id: id ?? this.id,
    ingredientId: ingredientIdSetToNull ? null : ingredientId ?? this.ingredientId,
    isCustom: isCustom ?? this.isCustom,
    displayName: displayNameSetToNull ? null : displayName ?? this.displayName,
    customName: customNameSetToNull ? null : customName ?? this.customName,
    category: category ?? this.category,
    state: state ?? this.state,
    quantity: quantitySetToNull ? null : quantity ?? this.quantity,
    brand: brandSetToNull ? null : brand ?? this.brand,
    isDefaultStaple: isDefaultStaple ?? this.isDefaultStaple,
    usageRank: usageRankSetToNull ? null : usageRank ?? this.usageRank,
    changedAt: changedAt ?? this.changedAt,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [KitchenItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "KitchenItem[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "KitchenItem[id]" has a null value in JSON.');
        assert(json.containsKey(r'ingredientId'), 'Required key "KitchenItem[ingredientId]" is missing from JSON.');
        assert(json.containsKey(r'isCustom'), 'Required key "KitchenItem[isCustom]" is missing from JSON.');
        assert(json[r'isCustom'] != null, 'Required key "KitchenItem[isCustom]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'), 'Required key "KitchenItem[displayName]" is missing from JSON.');
        assert(json.containsKey(r'customName'), 'Required key "KitchenItem[customName]" is missing from JSON.');
        assert(json.containsKey(r'category'), 'Required key "KitchenItem[category]" is missing from JSON.');
        assert(json[r'category'] != null, 'Required key "KitchenItem[category]" has a null value in JSON.');
        assert(json.containsKey(r'state'), 'Required key "KitchenItem[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "KitchenItem[state]" has a null value in JSON.');
        assert(json.containsKey(r'quantity'), 'Required key "KitchenItem[quantity]" is missing from JSON.');
        assert(json.containsKey(r'brand'), 'Required key "KitchenItem[brand]" is missing from JSON.');
        assert(json.containsKey(r'isDefaultStaple'), 'Required key "KitchenItem[isDefaultStaple]" is missing from JSON.');
        assert(json[r'isDefaultStaple'] != null, 'Required key "KitchenItem[isDefaultStaple]" has a null value in JSON.');
        assert(json.containsKey(r'usageRank'), 'Required key "KitchenItem[usageRank]" is missing from JSON.');
        assert(json.containsKey(r'changedAt'), 'Required key "KitchenItem[changedAt]" is missing from JSON.');
        assert(json[r'changedAt'] != null, 'Required key "KitchenItem[changedAt]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "KitchenItem[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "KitchenItem[createdAt]" has a null value in JSON.');
        return true;
      }());

      return KitchenItem(
        id: mapValueOfType<String>(json, r'id')!,
        ingredientId: mapValueOfType<String>(json, r'ingredientId'),
        isCustom: mapValueOfType<bool>(json, r'isCustom')!,
        displayName: LocalizedText.fromJson(json[r'displayName']),
        customName: mapValueOfType<String>(json, r'customName'),
        category: KitchenCategory.fromJson(json[r'category'])!,
        state: KitchenItemState.fromJson(json[r'state'])!,
        quantity: KitchenQuantity.fromJson(json[r'quantity']),
        brand: KitchenBrand.fromJson(json[r'brand']),
        isDefaultStaple: mapValueOfType<bool>(json, r'isDefaultStaple')!,
        usageRank: mapValueOfType<int>(json, r'usageRank'),
        changedAt: mapDateTime(json, r'changedAt', r'')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<KitchenItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenItem> mapFromJson(dynamic json) {
    final map = <String, KitchenItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenItem-objects as value to a dart map
  static Map<String, List<KitchenItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'ingredientId',
    'isCustom',
    'displayName',
    'customName',
    'category',
    'state',
    'quantity',
    'brand',
    'isDefaultStaple',
    'usageRank',
    'changedAt',
    'createdAt',
  };
}

