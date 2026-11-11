// The signed-in session: tokens in memory, persisted in [TokenStore], and
// refresh-token rotation through the contract's `refreshSession` (ACC-13).
//
// Each refresh token works once; reusing an old one revokes the whole
// session. So refreshes are single-flight: requests that fail together share
// one refresh, and the rotated pair is stored before any request is retried.
//
// Single-flight holds within one isolate. Keep every API call on the main
// isolate; a background isolate must not own a second SessionManager, or two
// rotations could race (security review L5).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan_api/api.dart' as api;

import 'token_store.dart';

/// Why the session ended.
enum SessionEndReason {
  /// The user signed out on this phone.
  signedOut,

  /// The server rejected the refresh token (`refresh_token_invalid`), or a
  /// rotated token could not be read. The app shows `error.api.signedOut`.
  expired,
}

/// Reported on [SessionManager.ended] when the session ended but local user
/// data could not be removed. The data stays unreadable: the cache is bound
/// to the account that owned it.
final class SessionDataNotCleared implements Exception {
  const SessionDataNotCleared(this.reason);

  final SessionEndReason reason;

  @override
  String toString() => 'SessionDataNotCleared(${reason.name})';
}

/// Sends `POST /v1/auth/refresh` with [refreshToken], without a bearer token.
typedef RefreshCall = Future<http.Response> Function(String refreshToken);

sealed class RefreshOutcome {
  const RefreshOutcome();
}

final class Refreshed extends RefreshOutcome {
  const Refreshed(this.tokens);

  final SessionTokens tokens;

  @override
  String toString() => 'Refreshed(<redacted>)';
}

/// The session is over. [response] is the server's answer, when there was
/// one, so the caller sees `refresh_token_invalid`.
final class RefreshEndedSession extends RefreshOutcome {
  const RefreshEndedSession(this.response);

  final http.Response? response;

  @override
  String toString() => 'RefreshEndedSession(${response?.statusCode})';
}

/// The refresh endpoint answered with a temporary error (for example 503).
/// The session is kept.
final class RefreshFailed extends RefreshOutcome {
  const RefreshFailed(this.response);

  final http.Response response;

  @override
  String toString() => 'RefreshFailed(${response.statusCode})';
}

final class SessionManager {
  SessionManager({required this._store, required this._refresh});

  final TokenStore _store;
  final RefreshCall _refresh;
  final _ended = StreamController<SessionEndReason>.broadcast();
  final List<Future<void> Function(SessionEndReason)> _endHandlers = [];

  SessionTokens? _tokens;
  Future<RefreshOutcome>? _inFlight;

  SessionTokens? get current => _tokens;
  bool get isSignedIn => _tokens != null;

  /// Fires after the session ended. An error event
  /// ([SessionDataNotCleared]) means local user data could not be removed.
  Stream<SessionEndReason> get ended => _ended.stream;

  /// Runs when the session ends, before the tokens are cleared. Used to clear
  /// cached household data on shared phones (contract-alignment.md 5).
  /// A handler that throws is tried once more, then reported.
  void addEndHandler(Future<void> Function(SessionEndReason) handler) =>
      _endHandlers.add(handler);

  /// Reads the stored session at startup.
  Future<void> load() async => _tokens = await _store.read();

  /// Starts a session after sign-in.
  Future<void> start(SessionTokens tokens) async {
    _tokens = tokens;
    await _store.write(tokens);
  }

  /// Ends the session. Local user data is removed first, then the tokens,
  /// so a crash in between leaves a signed-in phone that refetches, never a
  /// signed-out phone with someone's household on it (security review M2).
  ///
  /// Returns false when removing local data failed. The session is ended
  /// anyway, and the failure is reported on [ended].
  Future<bool> end(SessionEndReason reason) async {
    final cleared = await clearLocalData(reason);
    _tokens = null;
    await _store.clear();
    if (cleared) {
      _ended.add(reason);
    } else {
      _ended.addError(SessionDataNotCleared(reason));
    }
    return cleared;
  }

  /// Runs the end handlers without ending the session. Sign-out calls this
  /// before telling the server, so local data goes first. Returns false when
  /// a handler failed twice.
  Future<bool> clearLocalData(SessionEndReason reason) async {
    var cleared = true;
    for (final handler in _endHandlers) {
      if (!await _tryTwice(() => handler(reason))) cleared = false;
    }
    return cleared;
  }

  static Future<bool> _tryTwice(Future<void> Function() step) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await step();
        return true;
      } on Object catch (e) {
        debugPrint('Session end step failed: ${e.runtimeType}');
      }
    }
    return false;
  }

  /// Gets new tokens after the API rejected [rejectedAccessToken].
  ///
  /// If another request already refreshed, the newer tokens are returned
  /// without a second refresh. Throws [http.ClientException] when the refresh
  /// endpoint cannot be reached; the session is kept.
  Future<RefreshOutcome> refreshAfterRejected(String rejectedAccessToken) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final tokens = _tokens;
    if (tokens == null) {
      return Future.value(const RefreshEndedSession(null));
    }
    if (tokens.accessToken != rejectedAccessToken) {
      return Future.value(Refreshed(tokens));
    }
    final future = _rotate(tokens).whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<RefreshOutcome> _rotate(SessionTokens tokens) async {
    final http.Response response;
    try {
      response = await _refresh(tokens.refreshToken);
    } on api.ApiException catch (e) {
      // The generated client wraps transport errors in ApiException.
      throw http.ClientException('Refresh failed: ${e.code}');
    }
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      final next = _decodeTokens(response, tokens.accountId);
      if (next == null) {
        // The old refresh token is used up, and the new one is unreadable:
        // the session cannot continue.
        await end(SessionEndReason.expired);
        return const RefreshEndedSession(null);
      }
      _tokens = next;
      try {
        await _store.write(next);
      } on Object catch (e) {
        // Keep the rotated pair in memory; the old stored one no longer
        // works, so the next app start signs in again.
        debugPrint('Storing rotated tokens failed: ${e.runtimeType}');
      }
      return Refreshed(next);
    }
    if (status == 400 || status == 401 || status == 403) {
      await end(SessionEndReason.expired);
      return RefreshEndedSession(response);
    }
    return RefreshFailed(response);
  }

  static SessionTokens? _decodeTokens(
    http.Response response,
    String accountId,
  ) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final decoded = api.SessionTokens.fromJson(json);
      if (decoded == null) return null;
      return SessionTokens(
        accountId: accountId,
        accessToken: decoded.accessToken,
        accessTokenExpiresAt: decoded.accessTokenExpiresAt.toUtc(),
        refreshToken: decoded.refreshToken,
        refreshTokenExpiresAt: decoded.refreshTokenExpiresAt.toUtc(),
      );
    } on Object {
      return null;
    }
  }

  Future<void> dispose() => _ended.close();
}
