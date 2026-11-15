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
/// data, or the stored tokens, could not be removed. Cached data stays
/// unreadable (the cache is bound to the account that owned it), and tokens
/// that could not be removed are not trusted at the next start
/// ([SessionRevocationMarker]).
final class SessionDataNotCleared implements Exception {
  const SessionDataNotCleared(this.reason, {this.tokensRemoved = true});

  final SessionEndReason reason;

  /// False when the token store could not be cleared.
  final bool tokensRemoved;

  @override
  String toString() =>
      'SessionDataNotCleared(${reason.name}, tokensRemoved: $tokensRemoved)';
}

/// Remembers, outside the token store, that the stored session was ended
/// (security review T-027 L4). Set before the tokens are removed and cleared
/// after; while it is set, stored tokens are never used.
abstract interface class SessionRevocationMarker {
  bool get isSet;

  Future<void> set();

  Future<void> clear();
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
  SessionManager({
    required this._store,
    required this._refresh,
    this._revocation,
  });

  final TokenStore _store;
  final RefreshCall _refresh;
  final SessionRevocationMarker? _revocation;
  final _ended = StreamController<SessionEndReason>.broadcast();

  // Synchronous, so providers holding one account's data reset before
  // anything else runs for the next account (security review T-027 M1).
  final _accounts = StreamController<String?>.broadcast(sync: true);
  final List<Future<void> Function(SessionEndReason)> _endHandlers = [];

  SessionTokens? _tokens;
  Future<RefreshOutcome>? _inFlight;
  int _epoch = 0;
  bool _ending = false;

  SessionTokens? get current => _tokens;
  bool get isSignedIn => _tokens != null;

  /// Changes when a session starts and when ending one begins (before local
  /// data is wiped). A cache write stamped with an older epoch is dropped,
  /// so a late answer cannot put an account's data back between the wipe
  /// and the removal of the tokens (security review T-033).
  int get epoch => _epoch;

  /// True from the start of the wipe until the session has ended. Cache
  /// writes are refused meanwhile.
  bool get isEnding => _ending;

  /// Fires after the session ended. An error event
  /// ([SessionDataNotCleared]) means local user data could not be removed.
  Stream<SessionEndReason> get ended => _ended.stream;

  /// Runs when the session ends, before the tokens are cleared. Used to clear
  /// cached household data on shared phones (contract-alignment.md 5).
  /// A handler that throws is tried once more, then reported.
  void addEndHandler(Future<void> Function(SessionEndReason) handler) =>
      _endHandlers.add(handler);

  /// The signed-in account ID on every change: load, sign-in, end. Null when
  /// signed out. Delivered synchronously.
  Stream<String?> get accountChanges => _accounts.stream;

  /// Reads the stored session at startup. A session that was ended but whose
  /// tokens could not be removed is not used: removal is tried again, and
  /// the phone starts signed out either way.
  Future<void> load() async {
    final revocation = _revocation;
    if (revocation != null && revocation.isSet) {
      _tokens = null;
      if (await _tryTwice(_store.clear)) await _tryTwice(revocation.clear);
    } else {
      _tokens = await _store.read();
    }
    _accounts.add(_tokens?.accountId);
  }

  /// Starts a session after sign-in.
  Future<void> start(SessionTokens tokens) async {
    _epoch++;
    _ending = false;
    _tokens = tokens;
    _accounts.add(tokens.accountId);
    await _store.write(tokens);
    final revocation = _revocation;
    // If this fails, the next start signs out: safe, never the reverse.
    if (revocation != null && revocation.isSet) {
      await _tryTwice(revocation.clear);
    }
  }

  /// Ends the session. Local user data is removed first, then the tokens,
  /// so a crash in between leaves a signed-in phone that refetches, never a
  /// signed-out phone with someone's household on it (security review M2).
  /// The revocation marker is set before the tokens are removed, so tokens
  /// that cannot be removed are not used at the next start (T-027 L4).
  ///
  /// Never throws. Returns false when removing local data or the tokens
  /// failed. The session is ended anyway, and the failure is reported on
  /// [ended].
  Future<bool> end(SessionEndReason reason) async {
    final cleared = await clearLocalData(reason);
    _tokens = null;
    _ending = false;
    _accounts.add(null);
    final revocation = _revocation;
    final marked = revocation != null && await _tryTwice(revocation.set);
    final tokensRemoved = await _tryTwice(_store.clear);
    if (tokensRemoved && marked) await _tryTwice(revocation.clear);
    if (cleared && tokensRemoved) {
      _ended.add(reason);
    } else {
      _ended.addError(
        SessionDataNotCleared(reason, tokensRemoved: tokensRemoved),
      );
    }
    return cleared && tokensRemoved;
  }

  /// Runs the end handlers without ending the session. Sign-out calls this
  /// before telling the server, so local data goes first. Returns false when
  /// a handler failed twice.
  Future<bool> clearLocalData(SessionEndReason reason) async {
    _epoch++;
    _ending = true;
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

  /// Gets new tokens after the API rejected [rejectedAccessToken], which
  /// belonged to [accountId].
  ///
  /// If another request already refreshed, the newer tokens are returned
  /// without a second refresh, but only when they are [accountId]'s
  /// (security review T-034 M1): after a sign-out and another sign-in on
  /// this phone, the current tokens are someone else's, so the answer is
  /// [RefreshEndedSession] and the request is never repeated with them.
  /// Throws [http.ClientException] when the refresh endpoint cannot be
  /// reached; the session is kept.
  Future<RefreshOutcome> refreshAfterRejected(
    String rejectedAccessToken, {
    required String accountId,
  }) {
    final tokens = _tokens;
    if (tokens == null || tokens.accountId != accountId) {
      return Future.value(const RefreshEndedSession(null));
    }
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (tokens.accessToken != rejectedAccessToken) {
      return Future.value(Refreshed(tokens));
    }
    final future = _rotate(tokens).whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<RefreshOutcome> _rotate(SessionTokens tokens) async {
    final epoch = _epoch;
    final http.Response response;
    try {
      response = await _refresh(tokens.refreshToken);
    } on api.ApiException catch (e) {
      // The generated client wraps transport errors in ApiException.
      throw http.ClientException('Refresh failed: ${e.code}');
    }
    // The session changed while the refresh was on its way (sign-out, or
    // another account signed in): its answer neither restores the old
    // account's tokens nor ends the session that is current now.
    if (_epoch != epoch || !identical(_tokens, tokens)) {
      return const RefreshEndedSession(null);
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

  Future<void> dispose() async {
    await _ended.close();
    await _accounts.close();
  }
}
