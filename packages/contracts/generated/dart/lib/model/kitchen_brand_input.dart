//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class KitchenBrandInput {
  /// Returns a new [KitchenBrandInput] instance.
  KitchenBrandInput({
    this.brandId = const Optional.absent(),
    this.customName = const Optional.absent(),
  });

  /// Identifier of a reference ingredient or library dish.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> brandId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> customName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is KitchenBrandInput &&
    other.brandId == brandId &&
    other.customName == customName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (brandId == null ? 0 : brandId!.hashCode) +
    (customName == null ? 0 : customName!.hashCode);

  @override
  String toString() => 'KitchenBrandInput[brandId=$brandId, customName=$customName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.brandId.isPresent) {
      final value = this.brandId.value;
      json[r'brandId'] = value;
    }
    if (this.customName.isPresent) {
      final value = this.customName.value;
      json[r'customName'] = value;
    }
    return json;
  }

  /// Clones this instance of [KitchenBrandInput] and returns a new one where some of the
  /// properties have changed.
  KitchenBrandInput copyWith({
    Optional<String?>? brandId,
    Optional<String?>? customName,
  }) => KitchenBrandInput(
    brandId: brandId ?? this.brandId,
    customName: customName ?? this.customName,
  );

  /// Returns a new [KitchenBrandInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KitchenBrandInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return KitchenBrandInput(
        brandId: json.containsKey(r'brandId') ? Optional.present(mapValueOfType<String>(json, r'brandId')) : const Optional.absent(),
        customName: json.containsKey(r'customName') ? Optional.present(mapValueOfType<String>(json, r'customName')) : const Optional.absent(),
      );
    }
    return null;
  }

  static List<KitchenBrandInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <KitchenBrandInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KitchenBrandInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KitchenBrandInput> mapFromJson(dynamic json) {
    final map = <String, KitchenBrandInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KitchenBrandInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KitchenBrandInput-objects as value to a dart map
  static Map<String, List<KitchenBrandInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<KitchenBrandInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KitchenBrandInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

