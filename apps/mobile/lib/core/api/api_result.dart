// What a repository call returns: a value, or a failure the UI can name.
//
// Repositories never throw to feature code and never turn a failure into a
// default value (PR #6 review F2, QUESTIONS #39). A payload that cannot be
// decoded is a [DecodeFailure], not an empty list.

import 'package:flutter/foundation.dart';

import 'api_problem.dart';

sealed class ApiFailure {
  const ApiFailure();
}

/// The API answered with an error (`application/problem+json`).
///
/// Codes a screen must handle in its own way get their own subtype
/// ([ConsentChangedFailure], [ManagerProfileMustBeAdultFailure]); use
/// [ProblemFailure.of] to build the right one.
base class ProblemFailure extends ApiFailure {
  const ProblemFailure(this.problem);

  factory ProblemFailure.of(ApiProblem problem) => switch (problem.code) {
    ApiErrorCode.consentChanged => ConsentChangedFailure(problem),
    ApiErrorCode.managerProfileMustBeAdult => ManagerProfileMustBeAdultFailure(
      problem,
    ),
    _ => ProblemFailure(problem),
  };

  final ApiProblem problem;

  ApiErrorCode get code => problem.code;

  @override
  String toString() => 'ProblemFailure(${problem.code.wire})';
}

/// 409 `consent_changed` (contract 0.1.2, security review T-019 M1): the
/// member's consent moved on the server since the manager was shown it
/// (another phone decided or withdrew). Nothing was recorded. The screen
/// reloads the member and asks again; it never resends the same request.
final class ConsentChangedFailure extends ProblemFailure {
  const ConsentChangedFailure(super.problem);

  @override
  String toString() => 'ConsentChangedFailure()';
}

/// 409 `manager_profile_must_be_adult` (QUESTIONS #46): the manager's own
/// profile cannot take an infant, child or teen age group.
final class ManagerProfileMustBeAdultFailure extends ProblemFailure {
  const ManagerProfileMustBeAdultFailure(super.problem);

  @override
  String toString() => 'ManagerProfileMustBeAdultFailure()';
}

/// No answer: no connection, a timeout or a TLS error.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure();

  @override
  String toString() => 'NetworkFailure()';
}

/// The answer did not match the contract: invalid JSON, a missing required
/// field, an enum value this app version does not know, or no body where one
/// was expected. Fails closed.
final class DecodeFailure extends ApiFailure {
  const DecodeFailure(this.operation);

  /// The operation, for logs. Never the payload: it can hold health data.
  final String operation;

  @override
  String toString() => 'DecodeFailure($operation)';
}

/// The build has no API base URL (`--dart-define=KM_API_BASE_URL`).
final class NotConfiguredFailure extends ApiFailure {
  const NotConfiguredFailure();

  @override
  String toString() => 'NotConfiguredFailure()';
}

extension ApiFailureCodes on ApiFailure {
  /// The problem code, or null for failures without a server answer.
  ApiErrorCode? get problemCode => switch (this) {
    ProblemFailure(:final code) => code,
    _ => null,
  };

  /// Hard rules could not be read on the server (QUESTIONS #39). Cek Aman
  /// cannot run, so who's eating and suggestions are blocked.
  bool get isRulesUnavailable => problemCode == ApiErrorCode.rulesUnavailable;

  /// The session ended (refresh token rejected): the user signs in again.
  bool get isSignedOut => problemCode == ApiErrorCode.refreshTokenInvalid;
}

@immutable
sealed class ApiResult<T> {
  const ApiResult();

  /// The value, or null on failure. For code that only needs the happy path;
  /// screens should switch on [Ok] and [Err] instead.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };
}

final class Ok<T> extends ApiResult<T> {
  const Ok(this.value);

  final T value;

  /// Only the type: the value can hold tokens or hard rules, and the
  /// generated models print every field (security review L2).
  @override
  String toString() => 'Ok<$T>';
}

final class Err<T> extends ApiResult<T> {
  const Err(this.failure);

  final ApiFailure failure;

  @override
  String toString() => 'Err($failure)';
}
