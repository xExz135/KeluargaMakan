// Sign-in, sign-out and the signed-in account (ACC-01, ACC-02, ACC-13).
// Screens come with T-027; this is the data side they use.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../../core/api/session_manager.dart';
import '../../core/api/token_store.dart';
import '../../core/storage/key_value_store.dart';
import '../decoders.dart';

/// The result of a sign-in.
final class SignedIn {
  const SignedIn({required this.account, required this.isNewAccount});

  final api.Account account;
  final bool isNewAccount;
}

/// Contract `DeviceInfo`: a random installation ID and the app version. No
/// device name, model or advertising ID.
final class InstallationInfo {
  InstallationInfo(this._store);

  final KeyValueStore _store;

  /// Set per build with `--dart-define=KM_APP_VERSION=...`.
  static const appVersion = String.fromEnvironment(
    'KM_APP_VERSION',
    defaultValue: '0.1.0',
  );

  Future<api.DeviceInfo> deviceInfo() async => api.DeviceInfo(
    installationId: await installationId(),
    platform: api.DevicePlatform.android,
    appVersion: appVersion,
  );

  Future<String> installationId() async {
    final stored = _store.getString(PreferenceKeys.installationId);
    if (stored != null && _uuid.hasMatch(stored)) return stored;
    final id = randomUuidV4();
    await _store.setString(PreferenceKeys.installationId, id);
    return id;
  }

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
}

/// A random (version 4) UUID, for installation IDs and `Idempotency-Key`.
String randomUuidV4([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final class AuthRepository {
  AuthRepository({
    required this._caller,
    required api.ApiClient client,
    required this._session,
    required this._installation,
  }) : _auth = api.AuthApi(client),
       _account = api.AccountApi(client);

  final ApiCaller _caller;
  final api.AuthApi _auth;
  final api.AccountApi _account;
  final SessionManager _session;
  final InstallationInfo _installation;

  bool get isSignedIn => _session.isSignedIn;

  Future<ApiResult<api.SignInCodeChallenge>> requestSignInCode({
    required api.SignInChannel channel,
    required String destination,
    required api.Language language,
  }) => _caller.call(
    'requestSignInCode',
    () => _auth.requestSignInCodeWithHttpInfo(
      api.SignInCodeRequest(
        channel: channel,
        destination: destination,
        language: language,
      ),
    ),
    decodeWith(api.SignInCodeChallenge.fromJson, 'sign-in challenge'),
  );

  Future<ApiResult<SignedIn>> verifySignInCode({
    required String challengeId,
    required String code,
  }) async {
    final device = await _installation.deviceInfo();
    return _startSession(
      'verifySignInCode',
      () => _auth.verifySignInCodeWithHttpInfo(
        api.SignInCodeVerification(
          challengeId: challengeId,
          code: code,
          device: device,
        ),
      ),
    );
  }

  Future<ApiResult<SignedIn>> signInWithGoogle(String idToken) async {
    final device = await _installation.deviceInfo();
    return _startSession(
      'signInWithGoogle',
      () => _auth.signInWithGoogleWithHttpInfo(
        api.GoogleSignIn(idToken: idToken, device: device),
      ),
    );
  }

  Future<ApiResult<SignedIn>> _startSession(
    String operation,
    Future<http.Response> Function() send,
  ) async {
    final result = await _caller.call(
      operation,
      send,
      decodeWith(api.Session.fromJson, 'session'),
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final session):
        final t = session.tokens;
        await _session.start(
          SessionTokens(
            accessToken: t.accessToken,
            accessTokenExpiresAt: t.accessTokenExpiresAt.toUtc(),
            refreshToken: t.refreshToken,
            refreshTokenExpiresAt: t.refreshTokenExpiresAt.toUtc(),
          ),
        );
        return Ok(
          SignedIn(
            account: session.account,
            isNewAccount: session.isNewAccount,
          ),
        );
    }
  }

  /// Signs out on this phone (ACC-13). The local session and cached
  /// household data are cleared even when the API cannot be reached; the
  /// household stays on the server.
  Future<void> signOut() async {
    if (_session.isSignedIn) {
      await _caller.callNoContent('signOut', () => _auth.signOutWithHttpInfo());
    }
    await _session.end(SessionEndReason.signedOut);
  }

  Future<ApiResult<api.Account>> getAccount() => _caller.call(
    'getAccount',
    () => _account.getAccountWithHttpInfo(),
    decodeWith(api.Account.fromJson, 'account'),
  );
}

final installationInfoProvider = Provider<InstallationInfo>(
  (ref) => InstallationInfo(ref.watch(keyValueStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
    session: ref.watch(sessionManagerProvider),
    installation: ref.watch(installationInfoProvider),
  ),
);
