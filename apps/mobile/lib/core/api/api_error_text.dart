// Localized text for API failures (contract-alignment.md 5; copy deck 24.1).
//
// Text always comes from the error code, never from the server's `title` or
// `detail` (ApiProblem does not even keep them). Codes that need a
// screen-specific message (sign-in codes, consent, profile limit) are handled
// by their screens (T-027 to T-029); here they fall back to the generic
// message.

import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';
import 'api_problem.dart';
import 'api_result.dart';

@immutable
final class ApiErrorText {
  const ApiErrorText(this.title, this.body);

  /// Null when the message is a single line (snackbar or inline).
  final String? title;
  final String body;

  static ApiErrorText of(AppLocalizations l10n, ApiFailure failure) {
    final generic = ApiErrorText(l10n.errorGenericTitle, l10n.errorGenericBody);
    if (failure is! ProblemFailure) return generic;
    final problem = failure.problem;
    return switch (problem.code) {
      ApiErrorCode.rulesUnavailable => ApiErrorText(
        l10n.errorRulesUnavailableTitle,
        l10n.errorRulesUnavailableBody,
      ),
      ApiErrorCode.refreshTokenInvalid => ApiErrorText(
        l10n.errorApiSignedOut,
        l10n.errorApiSignedOutBody,
      ),
      ApiErrorCode.forbidden => ApiErrorText(null, l10n.errorApiForbidden),
      ApiErrorCode.notFound => ApiErrorText(null, l10n.errorApiNotFound),
      ApiErrorCode.validationFailed => ApiErrorText(
        null,
        l10n.errorApiValidationFailed,
      ),
      ApiErrorCode.rateLimited => ApiErrorText(
        null,
        l10n.errorApiRateLimited(retryMinutes(problem.retryAfterSeconds)),
      ),
      _ => generic,
    };
  }

  /// Whole minutes to wait, rounded up, at least 1.
  static int retryMinutes(int? seconds) {
    if (seconds == null || seconds <= 0) return 1;
    return (seconds + 59) ~/ 60;
  }

  /// Text under a form field for a `validation_failed` field error.
  /// [maxLength] fills `error.field.tooLong`.
  static String field(
    AppLocalizations l10n,
    FieldErrorKind kind, {
    required int maxLength,
  }) => switch (kind) {
    FieldErrorKind.required => l10n.errorFieldRequired,
    FieldErrorKind.tooLong => l10n.errorFieldTooLong(maxLength),
    FieldErrorKind.duplicate => l10n.errorFieldDuplicate,
    FieldErrorKind.invalid => l10n.errorFieldInvalid,
  };
}
