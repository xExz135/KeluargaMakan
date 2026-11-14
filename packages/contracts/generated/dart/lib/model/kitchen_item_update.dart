//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenItemUpdate {
  /// Returns a new [KitchenItemUpdate] instance.
  KitchenItemUpdate({
    this.state = const Optional.absent(),
    this.category = const Optional.absent(),
    this.quantity = const Optional.absent(),
    this.brand = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<KitchenItemState?> state;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<KitchenCategory?> category;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<KitchenQuantity?> quantity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<KitchenBrandInput?> brand;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenItemUpdate &&
    other.state == state &&
    other.category == category &&
    other.quantity == quantity &&
    other.brand == brand;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (state == null ? 0 : state!.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (brand == null ? 0 : brand!.hashCode);

  @override
  String toString() => 'KitchenItemUpdate[state=$state, category=$category, quantity=$quantity, brand=$brand]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.state.isPresent) {
      final value = this.state.value;
      json[r'state'] = value;
    }
    if (this.category.isPresent) {
      final value = this.category.value;
      json[r'category'] = value;
    }
    if (this.quantity.isPresent) {
      final value = this.quantity.value;
      json[r'quantity'] = value;
    }
    if (this.brand.isPresent) {
      final value = this.brand.value;
      json[r'brand'] = value;
    }
    return json;
  }

  /// Clones this instance of [KitchenItemUpdate] and returns a new one where some of the
  /// properties have changed.
  KitchenItemUpdate copyWith({
    Optional<KitchenItemState?>? state,
    Optional<KitchenCategory?>? category,
    Optional<KitchenQuantity?>? quantity,
    Optional<KitchenBrandInput?>? brand,
  }) => KitchenItemUpdate(
    state: state ?? this.state,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    brand: brand ?? this.brand,
  );

  /// Returns a new [KitchenItemUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenItemUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return KitchenItemUpdate(
        state: json.containsKey(r'state') ? Optional.present(KitchenItemState.fromJson(json[r'state'])) : const Optional.absent(),
        category: json.containsKey(r'category') ? Optional.present(KitchenCategory.fromJson(json[r'category'])) : const Optional.absent(),
        quantity: json.containsKey(r'quantity') ? Optional.present(KitchenQuantity.fromJson(json[r'quantity'])) : const Optional.absent(),
        brand: json.containsKey(r'brand') ? Optional.present(KitchenBrandInput.fromJson(json[r'brand'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<KitchenItemUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenItemUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenItemUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenItemUpdate> mapFromJson(dynamic json) {
    final map = <String, KitchenItemUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenItemUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenItemUpdate-objects as value to a dart map
  static Map<String, List<KitchenItemUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenItemUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenItemUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

