// What a failed code request or verification means for the sign-in screens
// (contract-alignment.md 5; ACC-01). Text comes from the error code only.

import 'package:flutter/material.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/onboarding_scaffold.dart';

enum SignInProblem {
  /// `validation_failed`: the number or email was refused.
  invalidInput,

  /// `code_invalid`: boxes cleared, try again.
  wrongCode,

  /// `code_expired`: ask for a new code.
  expired,

  /// `code_attempts_exceeded`: the challenge is locked; ask for a new code.
  attemptsExceeded,

  /// `rate_limited` (429): wait for `Retry-After`.
  tooMany,

  /// `sign_in_method_unavailable` (503), or a build without an API: no code
  /// can be sent yet (QUESTIONS #16: no real code sender is connected).
  unavailable,

  /// No connection.
  offline,

  /// Anything else; the input is kept for a retry.
  generic;

  static SignInProblem of(ApiFailure failure) => switch (failure) {
    NetworkFailure() => offline,
    NotConfiguredFailure() => unavailable,
    ProblemFailure(:final code) => switch (code) {
      ApiErrorCode.validationFailed => invalidInput,
      ApiErrorCode.codeInvalid => wrongCode,
      ApiErrorCode.codeExpired => expired,
      ApiErrorCode.codeAttemptsExceeded => attemptsExceeded,
      ApiErrorCode.rateLimited => tooMany,
      ApiErrorCode.signInMethodUnavailable => unavailable,
      _ => generic,
    },
    _ => generic,
  };
}

/// How long to wait after a 429: `retryAfterSeconds` or `Retry-After`, and
/// one minute when the answer had neither.
Duration retryWait(ApiFailure failure) {
  final seconds = switch (failure) {
    ProblemFailure(:final problem) => problem.retryAfterSeconds,
    _ => null,
  };
  return Duration(seconds: seconds == null || seconds <= 0 ? 60 : seconds);
}

/// Guards the resend countdown against a phone clock that is far behind the
/// server's: the server still refuses an early resend with 429.
const maxResendWait = Duration(minutes: 10);

/// When "Kirim ulang" becomes available on this phone's clock.
DateTime localResendAt(api.SignInCodeChallenge challenge, DateTime now) {
  var wait = challenge.resendAvailableAt.toUtc().difference(now.toUtc());
  if (wait.isNegative) wait = Duration.zero;
  if (wait > maxResendWait) wait = maxResendWait;
  return now.add(wait);
}

class SignInProblemMessage extends StatelessWidget {
  const SignInProblemMessage({
    super.key,
    required this.problem,
    required this.waitMinutes,
  });

  final SignInProblem problem;
  final int waitMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (problem) {
      SignInProblem.unavailable => InlineMessage(
        key: const Key('signIn.unavailable'),
        kind: InlineMessageKind.info,
        title: l10n.onboardingCodeUnavailableTitle,
        text: l10n.onboardingCodeUnavailableBody,
      ),
      SignInProblem.offline => InlineMessage(
        key: const Key('signIn.offline'),
        kind: InlineMessageKind.info,
        text: l10n.onboardingWelcomeOffline,
      ),
      SignInProblem.tooMany => InlineMessage(
        key: const Key('signIn.tooMany'),
        text: l10n.onboardingCodeErrorTooMany(waitMinutes),
      ),
      SignInProblem.wrongCode => InlineMessage(
        key: const Key('signIn.wrongCode'),
        text: l10n.onboardingCodeErrorWrong,
      ),
      SignInProblem.expired => InlineMessage(
        key: const Key('signIn.expired'),
        text: l10n.onboardingCodeErrorExpired,
      ),
      SignInProblem.attemptsExceeded => InlineMessage(
        key: const Key('signIn.attempts'),
        text: l10n.onboardingCodeErrorAttempts,
      ),
      SignInProblem.invalidInput || SignInProblem.generic => InlineMessage(
        key: const Key('signIn.generic'),
        title: l10n.errorGenericTitle,
        text: l10n.errorGenericBody,
      ),
    };
  }
}
