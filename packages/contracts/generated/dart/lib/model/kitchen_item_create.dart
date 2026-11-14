//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenItemCreate {
  /// Returns a new [KitchenItemCreate] instance.
  KitchenItemCreate({
    this.ingredientId = const Optional.absent(),
    this.customName = const Optional.absent(),
    this.category = const Optional.absent(),
    this.state = const Optional.absent(),
  });

  /// Identifier of a reference ingredient or library dish.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> ingredientId;

  /// A custom ingredient's name as the user typed it (KIT-05), stored in Unicode NFC with surrounding spaces removed. Text with control, format or private-use characters is refused. Names that differ only in case, accents, punctuation or spacing are the same ingredient.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> customName;

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

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenItemCreate &&
    other.ingredientId == ingredientId &&
    other.customName == customName &&
    other.category == category &&
    other.state == state;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ingredientId == null ? 0 : ingredientId!.hashCode) +
    (customName == null ? 0 : customName!.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (state == null ? 0 : state!.hashCode);

  @override
  String toString() => 'KitchenItemCreate[ingredientId=$ingredientId, customName=$customName, category=$category, state=$state]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.ingredientId.isPresent) {
      final value = this.ingredientId.value;
      json[r'ingredientId'] = value;
    }
    if (this.customName.isPresent) {
      final value = this.customName.value;
      json[r'customName'] = value;
    }
    if (this.category.isPresent) {
      final value = this.category.value;
      json[r'category'] = value;
    }
    if (this.state.isPresent) {
      final value = this.state.value;
      json[r'state'] = value;
    }
    return json;
  }

  /// Clones this instance of [KitchenItemCreate] and returns a new one where some of the
  /// properties have changed.
  KitchenItemCreate copyWith({
    Optional<String?>? ingredientId,
    Optional<String?>? customName,
    Optional<KitchenCategory?>? category,
    Optional<KitchenItemState?>? state,
  }) => KitchenItemCreate(
    ingredientId: ingredientId ?? this.ingredientId,
    customName: customName ?? this.customName,
    category: category ?? this.category,
    state: state ?? this.state,
  );

  /// Returns a new [KitchenItemCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenItemCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return KitchenItemCreate(
        ingredientId: json.containsKey(r'ingredientId') ? Optional.present(mapValueOfType<String>(json, r'ingredientId')) : const Optional.absent(),
        customName: json.containsKey(r'customName') ? Optional.present(mapValueOfType<String>(json, r'customName')) : const Optional.absent(),
        category: json.containsKey(r'category') ? Optional.present(KitchenCategory.fromJson(json[r'category'])) : const Optional.absent(),
        state: json.containsKey(r'state') ? Optional.present(KitchenItemState.fromJson(json[r'state'])) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<KitchenItemCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenItemCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenItemCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenItemCreate> mapFromJson(dynamic json) {
    final map = <String, KitchenItemCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenItemCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenItemCreate-objects as value to a dart map
  static Map<String, List<KitchenItemCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenItemCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenItemCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

