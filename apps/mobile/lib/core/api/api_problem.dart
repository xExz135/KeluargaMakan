// Reads `application/problem+json` error bodies (RFC 9457) from the API.
//
// Hand-written on purpose (PR #6 review F1): the generated `Problem.fromJson`
// throws on an error code this app version does not know, but the contract
// says clients treat an unknown code like `internal_error`.
//
// Only the stable fields are kept. `title` and `detail` are developer text in
// English and are dropped here, so no screen can show them by mistake: the UI
// localizes from [ApiErrorCode] (contract-alignment.md 5).

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Contract `ErrorCode` values the app knows. Anything else is
/// [internalError].
enum ApiErrorCode {
  validationFailed('validation_failed'),
  codeInvalid('code_invalid'),
  codeExpired('code_expired'),
  codeAttemptsExceeded('code_attempts_exceeded'),
  unauthenticated('unauthenticated'),
  accessTokenExpired('access_token_expired'),
  refreshTokenInvalid('refresh_token_invalid'),
  googleTokenInvalid('google_token_invalid'),
  forbidden('forbidden'),
  notFound('not_found'),
  householdRequired('household_required'),
  householdExists('household_exists'),
  profileLimitReached('profile_limit_reached'),
  managerProfileNotDeletable('manager_profile_not_deletable'),
  guardianConfirmationRequired('guardian_confirmation_required'),
  consentRequired('consent_required'),
  consentTextOutdated('consent_text_outdated'),
  consentNotActive('consent_not_active'),
  hardRuleDuplicate('hard_rule_duplicate'),
  mappingNotApplicable('mapping_not_applicable'),
  idempotencyKeyReused('idempotency_key_reused'),
  rateLimited('rate_limited'),
  rulesUnavailable('rules_unavailable'),
  signInMethodUnavailable('sign_in_method_unavailable'),
  serviceUnavailable('service_unavailable'),
  internalError('internal_error');

  const ApiErrorCode(this.wire);

  /// The value on the wire.
  final String wire;

  static final Map<String, ApiErrorCode> _byWire = {
    for (final code in values) code.wire: code,
  };

  /// Unknown or missing codes become [internalError] (contract `ErrorCode`).
  static ApiErrorCode fromWire(Object? value) =>
      (value is String ? _byWire[value] : null) ?? internalError;
}

/// Contract `FieldErrorCode`, reduced to what the forms distinguish
/// (contract-alignment.md 5, `validation_failed`).
enum FieldErrorKind {
  required,
  tooLong,
  duplicate,

  /// Every other code, including codes this app version does not know.
  invalid;

  static FieldErrorKind fromWire(Object? value) => switch (value) {
    'required' => required,
    'too_long' => tooLong,
    'duplicate' => duplicate,
    _ => invalid,
  };
}

@immutable
final class ApiFieldError {
  const ApiFieldError(this.pointer, this.kind);

  /// JSON Pointer into the request body, for example `/name`.
  final String pointer;
  final FieldErrorKind kind;

  @override
  bool operator ==(Object other) =>
      other is ApiFieldError && other.pointer == pointer && other.kind == kind;

  @override
  int get hashCode => Object.hash(pointer, kind);

  @override
  String toString() => 'ApiFieldError($pointer, ${kind.name})';
}

/// An error response from the API.
@immutable
final class ApiProblem {
  const ApiProblem({
    required this.status,
    required this.code,
    this.requestId,
    this.retryAfterSeconds,
    this.fieldErrors = const [],
  });

  /// Parses an error response. Never throws: a body that is not a problem
  /// document still gives a problem with [ApiErrorCode.internalError].
  ///
  /// [retryAfterHeader] is the `Retry-After` header, used when the body has
  /// no `retryAfterSeconds`.
  factory ApiProblem.parse(
    int status,
    String body, {
    String? retryAfterHeader,
  }) {
    Map<String, Object?>? json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) json = decoded;
    } on FormatException {
      json = null;
    }
    final retryAfter =
        _nonNegativeInt(json?['retryAfterSeconds']) ??
        _nonNegativeInt(int.tryParse(retryAfterHeader?.trim() ?? ''));
    final requestId = json?['requestId'];
    final errors = json?['errors'];
    return ApiProblem(
      status: status,
      code: ApiErrorCode.fromWire(json?['code']),
      requestId: requestId is String ? requestId : null,
      retryAfterSeconds: retryAfter,
      fieldErrors: [
        if (errors is List)
          for (final e in errors)
            if (e is Map && e['pointer'] is String)
              ApiFieldError(
                e['pointer'] as String,
                FieldErrorKind.fromWire(e['code']),
              ),
      ],
    );
  }

  /// HTTP status of the response.
  final int status;
  final ApiErrorCode code;

  /// Correlation ID for support requests (not shown as error text).
  final String? requestId;
  final int? retryAfterSeconds;
  final List<ApiFieldError> fieldErrors;

  static int? _nonNegativeInt(Object? value) =>
      value is int && value >= 0 ? value : null;

  @override
  String toString() =>
      'ApiProblem($status, ${code.wire}, requestId: $requestId)';
}
