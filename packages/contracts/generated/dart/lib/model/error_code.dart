//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

/// Stable machine-readable error code. New codes may be added; clients treat an unknown code like `internal_error`.
enum ErrorCode {
  validationFailed._(r'validation_failed'),
  codeInvalid._(r'code_invalid'),
  codeExpired._(r'code_expired'),
  codeAttemptsExceeded._(r'code_attempts_exceeded'),
  unauthenticated._(r'unauthenticated'),
  accessTokenExpired._(r'access_token_expired'),
  refreshTokenInvalid._(r'refresh_token_invalid'),
  googleTokenInvalid._(r'google_token_invalid'),
  forbidden._(r'forbidden'),
  notFound._(r'not_found'),
  householdRequired._(r'household_required'),
  householdExists._(r'household_exists'),
  profileLimitReached._(r'profile_limit_reached'),
  managerProfileNotDeletable._(r'manager_profile_not_deletable'),
  guardianConfirmationRequired._(r'guardian_confirmation_required'),
  consentRequired._(r'consent_required'),
  consentTextOutdated._(r'consent_text_outdated'),
  consentNotActive._(r'consent_not_active'),
  hardRuleDuplicate._(r'hard_rule_duplicate'),
  mappingNotApplicable._(r'mapping_not_applicable'),
  idempotencyKeyReused._(r'idempotency_key_reused'),
  rateLimited._(r'rate_limited'),
  rulesUnavailable._(r'rules_unavailable'),
  signInMethodUnavailable._(r'sign_in_method_unavailable'),
  serviceUnavailable._(r'service_unavailable'),
  internalError._(r'internal_error'),
  ;

  /// Instantiate a new enum with the provided value.
  const ErrorCode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ErrorCode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ErrorCode? fromJson(dynamic value) => ErrorCodeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ErrorCode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ErrorCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ErrorCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ErrorCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ErrorCode] to String,
/// and [decode] dynamic data back to [ErrorCode].
class ErrorCodeTypeTransformer {
  factory ErrorCodeTypeTransformer() => _instance ??= const ErrorCodeTypeTransformer._();

  const ErrorCodeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ErrorCode data) => data._value;

  /// Returns the instance of [ErrorCode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ErrorCode? decode(dynamic data, {bool allowNull = true}) {
    if (data is ErrorCode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'validation_failed': return ErrorCode.validationFailed;
        case r'code_invalid': return ErrorCode.codeInvalid;
        case r'code_expired': return ErrorCode.codeExpired;
        case r'code_attempts_exceeded': return ErrorCode.codeAttemptsExceeded;
        case r'unauthenticated': return ErrorCode.unauthenticated;
        case r'access_token_expired': return ErrorCode.accessTokenExpired;
        case r'refresh_token_invalid': return ErrorCode.refreshTokenInvalid;
        case r'google_token_invalid': return ErrorCode.googleTokenInvalid;
        case r'forbidden': return ErrorCode.forbidden;
        case r'not_found': return ErrorCode.notFound;
        case r'household_required': return ErrorCode.householdRequired;
        case r'household_exists': return ErrorCode.householdExists;
        case r'profile_limit_reached': return ErrorCode.profileLimitReached;
        case r'manager_profile_not_deletable': return ErrorCode.managerProfileNotDeletable;
        case r'guardian_confirmation_required': return ErrorCode.guardianConfirmationRequired;
        case r'consent_required': return ErrorCode.consentRequired;
        case r'consent_text_outdated': return ErrorCode.consentTextOutdated;
        case r'consent_not_active': return ErrorCode.consentNotActive;
        case r'hard_rule_duplicate': return ErrorCode.hardRuleDuplicate;
        case r'mapping_not_applicable': return ErrorCode.mappingNotApplicable;
        case r'idempotency_key_reused': return ErrorCode.idempotencyKeyReused;
        case r'rate_limited': return ErrorCode.rateLimited;
        case r'rules_unavailable': return ErrorCode.rulesUnavailable;
        case r'sign_in_method_unavailable': return ErrorCode.signInMethodUnavailable;
        case r'service_unavailable': return ErrorCode.serviceUnavailable;
        case r'internal_error': return ErrorCode.internalError;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ErrorCodeTypeTransformer? _instance;
}

