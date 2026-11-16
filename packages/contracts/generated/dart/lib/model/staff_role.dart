//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Staff roles for the internal admin tool (INT-15, QUESTIONS #20). Operations list the roles they allow in `x-staff-roles`. Staff never read household data.
enum StaffRole {
  contentEditor._(r'content_editor'),
  safetyReviewer._(r'safety_reviewer'),
  nutritionReviewer._(r'nutrition_reviewer'),
  admin._(r'admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const StaffRole._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [StaffRole] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static StaffRole? fromJson(dynamic value) => StaffRoleTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [StaffRole]
  /// that were successfully decoded from the passed [JSON][json].
  static List<StaffRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StaffRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StaffRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [StaffRole] to String,
/// and [decode] dynamic data back to [StaffRole].
class StaffRoleTypeTransformer {
  factory StaffRoleTypeTransformer() => _instance ??= const StaffRoleTypeTransformer._();

  const StaffRoleTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(StaffRole data) => data._value;

  /// Returns the instance of [StaffRole] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  StaffRole? decode(dynamic data, {bool allowNull = true}) {
    if (data is StaffRole) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'content_editor': return StaffRole.contentEditor;
        case r'safety_reviewer': return StaffRole.safetyReviewer;
        case r'nutrition_reviewer': return StaffRole.nutritionReviewer;
        case r'admin': return StaffRole.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static StaffRoleTypeTransformer? _instance;
}

