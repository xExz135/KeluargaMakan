// The signed-in session: tokens in memory, persisted in [TokenStore], and
// refresh-token rotation through the contract's `refreshSession` (ACC-13).
//
// Each refresh token works once; reusing an old one revokes the whole
// session. So refreshes are single-flight: requests that fail together share
// one refresh, and the rotated pair is stored before any request is retried.

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

/// Sends `POST /v1/auth/refresh` with [refreshToken], without a bearer token.
typedef RefreshCall = Future<http.Response> Function(String refreshToken);

sealed class RefreshOutcome {
  const RefreshOutcome();
}

final class Refreshed extends RefreshOutcome {
  const Refreshed(this.tokens);

  final SessionTokens tokens;
}

/// The session is over. [response] is the server's answer, when there was
/// one, so the caller sees `refresh_token_invalid`.
final class RefreshEndedSession extends RefreshOutcome {
  const RefreshEndedSession(this.response);

  final http.Response? response;
}

/// The refresh endpoint answered with a temporary error (for example 503).
/// The session is kept.
final class RefreshFailed extends RefreshOutcome {
  const RefreshFailed(this.response);

  final http.Response response;
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

  /// Fires after the session ended and local user data was cleared.
  Stream<SessionEndReason> get ended => _ended.stream;

  /// Runs when the session ends, before [ended] fires. Used to clear cached
  /// household data on shared phones (contract-alignment.md 5).
  void addEndHandler(Future<void> Function(SessionEndReason) handler) =>
      _endHandlers.add(handler);

  /// Reads the stored session at startup.
  Future<void> load() async => _tokens = await _store.read();

  /// Starts a session after sign-in.
  Future<void> start(SessionTokens tokens) async {
    _tokens = tokens;
    await _store.write(tokens);
  }

  Future<void> end(SessionEndReason reason) async {
    _tokens = null;
    await _store.clear();
    for (final handler in _endHandlers) {
      try {
        await handler(reason);
      } on Object catch (e) {
        debugPrint('Session end handler failed: ${e.runtimeType}');
      }
    }
    _ended.add(reason);
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
      final next = _decodeTokens(response);
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

  static SessionTokens? _decodeTokens(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final decoded = api.SessionTokens.fromJson(json);
      if (decoded == null) return null;
      return SessionTokens(
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
