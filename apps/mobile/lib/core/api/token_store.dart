// Where the session tokens live on the device.
//
// The contract marks tokens as `credential` data: "Store tokens in encrypted
// device storage only." On Android, flutter_secure_storage encrypts values
// with AES-GCM under a key wrapped by the Android Keystore. Tokens are never
// written to the drift database, shared preferences or logs.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The tokens of the signed-in session (contract `SessionTokens`), with the
/// account they belong to. The account ID binds the on-device cache to this
/// session, so another account never reads it (security review M2).
@immutable
final class SessionTokens {
  const SessionTokens({
    required this.accountId,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final String accountId;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;

  Map<String, Object?> toJson() => {
    'accountId': accountId,
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
  };

  /// Null when [json] is not a complete token set.
  static SessionTokens? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final account = json['accountId'];
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final accessExp = _date(json['accessTokenExpiresAt']);
    final refreshExp = _date(json['refreshTokenExpiresAt']);
    if (account is! String ||
        account.isEmpty ||
        access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        accessExp == null ||
        refreshExp == null) {
      return null;
    }
    return SessionTokens(
      accountId: account,
      accessToken: access,
      accessTokenExpiresAt: accessExp,
      refreshToken: refresh,
      refreshTokenExpiresAt: refreshExp,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  // Never print tokens.
  @override
  String toString() => 'SessionTokens(<redacted>)';
}

abstract interface class TokenStore {
  /// The stored session, or null when signed out or unreadable.
  Future<SessionTokens?> read();

  /// Replaces the stored session. Access and refresh tokens are written
  /// together, so a rotated refresh token is never stored without its pair.
  Future<void> write(SessionTokens tokens);

  Future<void> clear();
}

final class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              // An unreadable entry (for example after a restore to a new
              // phone, where the Keystore key is gone) is wiped, which signs
              // the user out instead of crashing.
              resetOnError: true,
              storageNamespace: 'keluargamakan_session',
            ),
          );

  static const _key = 'auth.session.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<SessionTokens?> read() async {
    final String? raw;
    try {
      raw = await _storage.read(key: _key);
    } on Object {
      await clear();
      return null;
    }
    if (raw == null) return null;
    Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      json = null;
    }
    final tokens = SessionTokens.fromJson(json);
    if (tokens == null) await clear();
    return tokens;
  }

  @override
  Future<void> write(SessionTokens tokens) =>
      _storage.write(key: _key, value: jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      // Nothing more to do: the next read fails and clears again.
    }
  }
}

/// For tests.
final class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._tokens]);

  SessionTokens? _tokens;
  int writes = 0;

  @override
  Future<SessionTokens?> read() async => _tokens;

  @override
  Future<void> write(SessionTokens tokens) async {
    writes++;
    _tokens = tokens;
  }

  @override
  Future<void> clear() async => _tokens = null;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
