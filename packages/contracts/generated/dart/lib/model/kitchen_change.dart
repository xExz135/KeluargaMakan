//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenChange {
  /// Returns a new [KitchenChange] instance.
  KitchenChange({
    required this.changeId,
    required this.ingredient,
    required this.operation,
    required this.ageMs,
    this.category = const Optional.absent(),
    this.state = const Optional.absent(),
    this.quantity = const Optional.absent(),
    this.brand = const Optional.absent(),
  });

  /// Random UUID made with the change; a repeat returns the first result.
  final String changeId;

  final KitchenIngredientKey ingredient;

  final KitchenChangeOperation operation;

  /// Milliseconds from the edit to sending this request, measured on the phone. The server dates the change at its own time minus this age (KIT-16), so the phone's clock setting does not matter, and never later. A negative age, or one older than the server's limit (at most 30 days, 2592000000), makes only this change `rejected` (`validation_failed`); the rest of the sync still applies.
  final int ageMs;

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
  final Optional<KitchenItemState?> state;

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
  bool operator ==(Object other) => identical(this, other) || other is KitchenChange &&
    other.changeId == changeId &&
    other.ingredient == ingredient &&
    other.operation == operation &&
    other.ageMs == ageMs &&
    other.category == category &&
    other.state == state &&
    other.quantity == quantity &&
    other.brand == brand;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (changeId.hashCode) +
    (ingredient.hashCode) +
    (operation.hashCode) +
    (ageMs.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (state == null ? 0 : state!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (brand == null ? 0 : brand!.hashCode);

  @override
  String toString() => 'KitchenChange[changeId=$changeId, ingredient=$ingredient, operation=$operation, ageMs=$ageMs, category=$category, state=$state, quantity=$quantity, brand=$brand]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'changeId'] = this.changeId;
      json[r'ingredient'] = this.ingredient;
      json[r'operation'] = this.operation;
      json[r'ageMs'] = this.ageMs;
    if (this.category.isPresent) {
      final value = this.category.value;
      json[r'category'] = value;
    }
    if (this.state.isPresent) {
      final value = this.state.value;
      json[r'state'] = value;
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

  /// Clones this instance of [KitchenChange] and returns a new one where some of the
  /// properties have changed.
  KitchenChange copyWith({
    String? changeId,
    KitchenIngredientKey? ingredient,
    KitchenChangeOperation? operation,
    int? ageMs,
    Optional<KitchenCategory?>? category,
    Optional<KitchenItemState?>? state,
    Optional<KitchenQuantity?>? quantity,
    Optional<KitchenBrandInput?>? brand,
  }) => KitchenChange(
    changeId: changeId ?? this.changeId,
    ingredient: ingredient ?? this.ingredient,
    operation: operation ?? this.operation,
    ageMs: ageMs ?? this.ageMs,
    category: category ?? this.category,
    state: state ?? this.state,
    quantity: quantity ?? this.quantity,
    brand: brand ?? this.brand,
  );

  /// Returns a new [KitchenChange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenChange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'changeId'), 'Required key "KitchenChange[changeId]" is missing from JSON.');
        assert(json[r'changeId'] != null, 'Required key "KitchenChange[changeId]" has a null value in JSON.');
        assert(json.containsKey(r'ingredient'), 'Required key "KitchenChange[ingredient]" is missing from JSON.');
        assert(json[r'ingredient'] != null, 'Required key "KitchenChange[ingredient]" has a null value in JSON.');
        assert(json.containsKey(r'operation'), 'Required key "KitchenChange[operation]" is missing from JSON.');
        assert(json[r'operation'] != null, 'Required key "KitchenChange[operation]" has a null value in JSON.');
        assert(json.containsKey(r'ageMs'), 'Required key "KitchenChange[ageMs]" is missing from JSON.');
        assert(json[r'ageMs'] != null, 'Required key "KitchenChange[ageMs]" has a null value in JSON.');
        return true;
      }());

      return KitchenChange(
        changeId: mapValueOfType<String>(json, r'changeId')!,
        ingredient: KitchenIngredientKey.fromJson(json[r'ingredient'])!,
        operation: KitchenChangeOperation.fromJson(json[r'operation'])!,
        ageMs: mapValueOfType<int>(json, r'ageMs')!,
        category: json.containsKey(r'category') ? Optional.present(KitchenCategory.fromJson(json[r'category'])) : const Optional.absent(),
        state: json.containsKey(r'state') ? Optional.present(KitchenItemState.fromJson(json[r'state'])) : const Optional.absent(),
        quantity: json.containsKey(r'quantity') ? Optional.present(KitchenQuantity.fromJson(json[r'quantity'])) : const Optional.absent(),
        brand: json.containsKey(r'brand') ? Optional.present(KitchenBrandInput.fromJson(json[r'brand'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<KitchenChange> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenChange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenChange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenChange> mapFromJson(dynamic json) {
    final map = <String, KitchenChange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenChange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenChange-objects as value to a dart map
  static Map<String, List<KitchenChange>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenChange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenChange.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'changeId',
    'ingredient',
    'operation',
    'ageMs',
  };
}

