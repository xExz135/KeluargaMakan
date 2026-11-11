// The generated Dart API client (packages/contracts/generated/dart, T-015),
// wired with the build's base URL, bearer auth from the session and a
// timeout.
//
// The app talks only to the KeluargaMakan API, never to an AI provider or the
// AI service (ARCHITECTURE 3). The generated client is used as generated and
// never hand-edited. Feature code reads repositories (lib/data), which use
// [ApiCaller]; no widget calls the API directly.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan_api/api.dart' as api;

import '../config/app_config.dart';
import '../config/config_keys.dart';
import '../storage/app_database.dart';
import '../time/household_time.dart';
import 'api_problem.dart';
import 'api_result.dart';
import 'auth_http_client.dart';
import 'session_manager.dart';
import 'token_store.dart';

/// Where the API lives. Set per build with
/// `--dart-define=KM_API_BASE_URL=https://...`; no secrets here.
///
/// Only `https` is accepted, except in debug builds, where `http` is allowed
/// for a local server on [localHosts] (security review M1). Android's
/// cleartext block does not cover Dart sockets, so this check is what keeps
/// tokens and hard rules off plain HTTP. A refused URL counts as "not
/// configured": nothing is sent.
final class ApiEnvironment {
  const ApiEnvironment(this.baseUrl, {this.debugBuild = kDebugMode});

  factory ApiEnvironment.fromBuild() =>
      ApiEnvironment(Uri.parse(const String.fromEnvironment(_key)));

  static const _key = 'KM_API_BASE_URL';

  /// This machine, and the host machine as seen from the Android emulator.
  static const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  /// Empty when no base URL was provided at build time.
  final Uri baseUrl;

  /// True only in debug builds; release and profile builds require https.
  final bool debugBuild;

  bool get isConfigured {
    if (baseUrl.host.isEmpty || baseUrl.userInfo.isNotEmpty) return false;
    if (baseUrl.isScheme('https')) return true;
    return debugBuild &&
        baseUrl.isScheme('http') &&
        localHosts.contains(baseUrl.host);
  }

  /// The generated client appends paths such as `/v1/account`.
  String get basePath {
    final text = baseUrl.toString();
    return text.endsWith('/') ? text.substring(0, text.length - 1) : text;
  }
}

final apiEnvironmentProvider = Provider<ApiEnvironment>(
  (ref) => ApiEnvironment.fromBuild(),
);

/// The raw HTTP client. Tests override it with `MockClient`.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

Duration _timeout(Ref ref) => Duration(
  milliseconds: ref
      .watch(appConfigProvider)
      .get(ConfigKeys.apiRequestTimeoutMs),
);

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final env = ref.watch(apiEnvironmentProvider);
  final raw = ref.watch(httpClientProvider);
  final timeout = _timeout(ref);
  // The refresh call bypasses AuthenticatingClient: it has no bearer token
  // and must never trigger another refresh.
  final refreshApi = api.AuthApi(
    api.ApiClient(basePath: env.basePath)..client = TimeoutClient(raw, timeout),
  );
  final manager = SessionManager(
    store: ref.watch(tokenStoreProvider),
    refresh: (refreshToken) => refreshApi.refreshSessionWithHttpInfo(
      api.SessionRefresh(refreshToken: refreshToken),
    ),
  );
  // Shared phones: when the session ends, the household's cached data goes
  // with it (contract-alignment.md 5, `refresh_token_invalid`).
  manager
    ..addEndHandler((_) => ref.read(appDatabaseProvider).clearUserData())
    ..addEndHandler(
      (_) async => ref.read(knownHouseholdTimeZoneProvider.notifier).set(null),
    );
  ref.onDispose(manager.dispose);
  return manager;
});

final apiClientProvider = Provider<api.ApiClient>((ref) {
  final env = ref.watch(apiEnvironmentProvider);
  return api.ApiClient(basePath: env.basePath)
    ..client = AuthenticatingClient(
      inner: ref.watch(httpClientProvider),
      session: ref.watch(sessionManagerProvider),
      timeout: _timeout(ref),
    );
});

final apiCallerProvider = Provider<ApiCaller>(
  (ref) => ApiCaller(ref.watch(apiEnvironmentProvider)),
);

/// Runs a generated `*WithHttpInfo` call and turns every outcome into an
/// [ApiResult].
///
/// Repositories use the `WithHttpInfo` variants so that errors and decoding
/// are handled here, in one place: problem bodies go through [ApiProblem]
/// (F1), and decoding catches every error the generated models can throw
/// (`TypeError` from a null check, `AssertionError` in debug builds,
/// `FormatException`, `ArgumentError` for enums) and fails closed (F2).
final class ApiCaller {
  const ApiCaller(this._env);

  final ApiEnvironment _env;

  /// A call whose 2xx answer has a JSON body decoded by [decode]. [decode]
  /// throws when the body does not match the contract.
  Future<ApiResult<T>> call<T>(
    String operation,
    Future<http.Response> Function() send,
    T Function(Object? json) decode,
  ) async {
    final sent = await _send(operation, send);
    final http.Response response;
    switch (sent) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        response = value;
    }
    if (response.bodyBytes.isEmpty || response.statusCode == 204) {
      return Err(DecodeFailure(operation));
    }
    try {
      return Ok(decode(jsonDecode(utf8.decode(response.bodyBytes))));
    } on Object catch (e) {
      // Only the error type is logged: the payload can hold health data.
      debugPrint('API decode failed: $operation (${e.runtimeType})');
      return Err(DecodeFailure(operation));
    }
  }

  /// A call whose 2xx answer has no body that the app needs.
  Future<ApiResult<void>> callNoContent(
    String operation,
    Future<http.Response> Function() send,
  ) async {
    final sent = await _send(operation, send);
    return switch (sent) {
      Ok() => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  Future<ApiResult<http.Response>> _send(
    String operation,
    Future<http.Response> Function() send,
  ) async {
    if (!_env.isConfigured) return const Err(NotConfiguredFailure());
    final http.Response response;
    try {
      response = await send();
    } on api.ApiException {
      // The generated client throws ApiException only for transport errors
      // (socket, TLS, timeout, connection).
      return const Err(NetworkFailure());
    } on http.ClientException {
      return const Err(NetworkFailure());
    } on Object catch (e) {
      debugPrint('API call failed: $operation (${e.runtimeType})');
      return Err(DecodeFailure(operation));
    }
    final status = response.statusCode;
    if (status >= 400) {
      return Err(
        ProblemFailure(
          ApiProblem.parse(
            status,
            utf8.decode(response.bodyBytes, allowMalformed: true),
            retryAfterHeader: response.headers['retry-after'],
          ),
        ),
      );
    }
    if (status < 200 || status >= 300) return Err(DecodeFailure(operation));
    return Ok(response);
  }
}

/// Throws [FormatException] when a generated `fromJson` returned null.
T required<T>(T? value, String what) =>
    value ?? (throw FormatException('Missing or invalid $what'));
