// TEST FIXTURE: not real safety or nutrition data.
//
// A small in-memory stand-in for the KeluargaMakan API's sign-in, account
// and household endpoints (contract v0.1.2), shared by several "phones" in
// one test so ACC-13 (sign in again on another phone) can be checked.
// Contacts, codes and names are invented.

import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keluargamakan/app/app.dart';
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/config/app_config.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';
import 'package:keluargamakan/core/time/clock.dart';
import 'package:keluargamakan/data/session_restore.dart';
import 'package:keluargamakan/features/auth/google_id_token.dart';

import 'api_fixtures.dart' show profileJson;
import 'pump_app.dart';

/// The fixture code every challenge accepts unless [FakeServer.code] says
/// otherwise.
const fixtureCode = '123456';

final class _Challenge {
  _Challenge(this.destination, this.code, this.expiresAt);

  final String destination;
  final String code;
  final DateTime expiresAt;
  int wrong = 0;
}

final class FakeServer {
  FakeServer({this.codeLength = 6, this.maxWrongCodes = 3});

  /// The server's clock. pumpPhone sets it to the test's fake clock, so
  /// countdowns on the phone and times from the server agree.
  DateTime Function()? now;
  final int codeLength;
  final int maxWrongCodes;

  /// The code the next challenges accept.
  String code = fixtureCode;

  /// Seconds until a resend is allowed (`resendAvailableAt`).
  int resendAfterSeconds = 0;

  /// Answers a request before the normal handling, when it returns non-null.
  http.Response? Function(http.Request request)? intercept;

  /// Paths whose answer is held back this long (a slow network).
  final Map<String, Duration> delays = {};

  /// The family list each account gets from `GET /v1/household/profiles`,
  /// contract-shaped (helpers/api_fixtures.dart). Missing: the manager only,
  /// without rules.
  final Map<String, List<Map<String, Object?>>> profilesByAccount = {};

  /// Every request received, in order.
  final List<http.Request> requests = [];

  final Map<String, String> _accountByDestination = {};
  final Map<String, String> _destinationByAccount = {};
  final Map<String, String> _householdNameByAccount = {};
  final Map<String, String> _accountByToken = {};
  final Map<String, _Challenge> _challenges = {};
  int _ids = 0;

  DateTime get _now => (now ?? DateTime.now)().toUtc();

  /// The account for [destination], if one was created.
  String? accountFor(String destination) => _accountByDestination[destination];

  String? householdNameOf(String accountId) =>
      _householdNameByAccount[accountId];

  /// Creates a household directly, as if an earlier request had worked.
  void createHouseholdFor(String accountId, String managerName) =>
      _householdNameByAccount[accountId] = managerName;

  int count(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == path).length;

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final delay = delays[request.url.path];
    if (delay != null) await Future<void>.delayed(delay);
    final intercepted = intercept?.call(request);
    if (intercepted != null) return intercepted;
    final path = request.url.path;
    switch ((request.method, path)) {
      case ('GET', '/v1/household/profiles'):
        final account = _account(request);
        if (account == null) return problem('unauthenticated', 401);
        if (!_householdNameByAccount.containsKey(account)) {
          return problem('household_required', 409);
        }
        return json({
          'items':
              profilesByAccount[account] ??
              [
                profileJson(
                  id: 'p-$account',
                  name: _householdNameByAccount[account]!,
                ),
              ],
          'maxProfiles': 12,
        });
      case ('POST', '/v1/auth/code/request'):
        return _requestCode(request);
      case ('POST', '/v1/auth/code/verify'):
        return _verify(request);
      case ('POST', '/v1/auth/google'):
        return problem('sign_in_method_unavailable', 503);
      case ('POST', '/v1/auth/sign-out'):
        final account = _account(request);
        if (account == null) return problem('unauthenticated', 401);
        _accountByToken.removeWhere((_, a) => a == account);
        return http.Response('', 204);
      case ('GET', '/v1/account'):
        final account = _account(request);
        if (account == null) return problem('unauthenticated', 401);
        return json(_accountJson(account));
      case ('GET', '/v1/household'):
        final account = _account(request);
        if (account == null) return problem('unauthenticated', 401);
        if (!_householdNameByAccount.containsKey(account)) {
          return problem('household_required', 409);
        }
        return json(_householdJson(account));
      case ('POST', '/v1/household'):
        final account = _account(request);
        if (account == null) return problem('unauthenticated', 401);
        if (_householdNameByAccount.containsKey(account)) {
          return problem('household_exists', 409);
        }
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final manager = body['managerProfile']! as Map<String, Object?>;
        _householdNameByAccount[account] = manager['name']! as String;
        return json(_householdJson(account), 201);
    }
    return problem('not_found', 404);
  }

  http.Response _requestCode(http.Request request) {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final destination = body['destination']! as String;
    final id = _uuid();
    _challenges[id] = _Challenge(
      destination,
      code,
      _now.add(const Duration(minutes: 10)),
    );
    return json({
      'challengeId': id,
      'channel': body['channel'],
      'codeLength': codeLength,
      'expiresAt': _now.add(const Duration(minutes: 10)).toIso8601String(),
      'resendAvailableAt': _now
          .add(Duration(seconds: resendAfterSeconds))
          .toIso8601String(),
    }, 202);
  }

  http.Response _verify(http.Request request) {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final challenge = _challenges[body['challengeId']];
    if (challenge == null) return problem('code_invalid', 400);
    if (challenge.wrong >= maxWrongCodes) {
      return problem('code_attempts_exceeded', 400);
    }
    if (!_now.isBefore(challenge.expiresAt)) {
      return problem('code_expired', 400);
    }
    if (body['code'] != challenge.code) {
      challenge.wrong++;
      return problem(
        challenge.wrong >= maxWrongCodes
            ? 'code_attempts_exceeded'
            : 'code_invalid',
        400,
      );
    }
    _challenges.remove(body['challengeId']);
    var account = _accountByDestination[challenge.destination];
    final isNew = account == null;
    if (account == null) {
      account = 'acc-${++_ids}';
      _accountByDestination[challenge.destination] = account;
      _destinationByAccount[account] = challenge.destination;
    }
    final token = 'access-${++_ids}';
    _accountByToken[token] = account;
    return json({
      'tokens': {
        'tokenType': 'Bearer',
        'accessToken': token,
        'accessTokenExpiresAt': _now
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'refreshToken': 'refresh-$_ids',
        'refreshTokenExpiresAt': _now
            .add(const Duration(days: 30))
            .toIso8601String(),
      },
      'account': _accountJson(account),
      'isNewAccount': isNew,
    });
  }

  String? _account(http.Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    return _accountByToken[header.substring(7)];
  }

  Map<String, Object?> _accountJson(String account) {
    final destination = _destinationByAccount[account]!;
    final isEmail = destination.contains('@');
    return {
      'id': account,
      'role': 'manager',
      'householdId': _householdNameByAccount.containsKey(account)
          ? 'hh-$account'
          : null,
      'signInMethods': [isEmail ? 'email' : 'phone'],
      'phone': isEmail ? null : destination,
      'email': isEmail ? destination : null,
      'createdAt': '2026-11-01T03:00:00Z',
    };
  }

  Map<String, Object?> _householdJson(String account) => {
    'id': 'hh-$account',
    'name': null,
    'city': null,
    'timeZone': 'Asia/Jakarta',
    'language': 'id',
    'managerAccountId': account,
    'managerProfileId': 'p-$account',
    'createdAt': '2026-11-01T03:00:00Z',
    'updatedAt': '2026-11-01T03:00:00Z',
  };

  String _uuid() {
    final n = (++_ids).toRadixString(16).padLeft(12, '0');
    return '6f1a2b3c-4d5e-4f60-8a7b-$n';
  }

  static http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  static http.Response problem(
    String code,
    int status, {
    Map<String, String> headers = const {},
    Map<String, Object?> extra = const {},
  }) => http.Response(
    jsonEncode({
      'type': 'urn:keluargamakan:problem:$code',
      'title': 'Server title',
      'status': status,
      'code': code,
      'requestId': 'req-1',
      ...extra,
    }),
    status,
    headers: {'content-type': 'application/problem+json', ...headers},
  );
}

/// One phone: its own token store, database and preferences.
/// A token store whose [clear] can be made to fail, like a Keystore error.
final class FlakyTokenStore implements TokenStore {
  final _inner = InMemoryTokenStore();
  bool failClear = false;

  @override
  Future<SessionTokens?> read() => _inner.read();

  @override
  Future<void> write(SessionTokens tokens) => _inner.write(tokens);

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('keystore unavailable');
    await _inner.clear();
  }
}

final class TestPhone {
  TestPhone({InMemoryKeyValueStore? store, TokenStore? tokens})
    : store = store ?? InMemoryKeyValueStore(),
      tokens = tokens ?? InMemoryTokenStore(),
      db = _memoryDb();

  final InMemoryKeyValueStore store;
  final TokenStore tokens;
  final AppDatabase db;

  static AppDatabase _memoryDb() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return AppDatabase(NativeDatabase.memory());
  }
}

/// Pumps the whole app on [phone] against [server], starting like main():
/// the stored session is restored first.
Future<ProviderContainer> pumpPhone(
  WidgetTester tester, {
  required FakeServer server,
  required TestPhone phone,
  Map<String, Object?> config = const {},
  GoogleIdTokenSource? google,
  Locale deviceLocale = const Locale('id', 'ID'),
  double textScale = 1.0,
  Size size = TestWindows.phone,
  Brightness platformBrightness = Brightness.light,
  String baseUrl = 'https://api.test',
}) async {
  simulateDevice(
    tester,
    deviceLocale: deviceLocale,
    textScale: textScale,
    size: size,
    platformBrightness: platformBrightness,
  );
  DateTime fakeNow() => tester.binding.clock.now();
  server.now ??= fakeNow;
  final container = ProviderContainer(
    overrides: [
      apiEnvironmentProvider.overrideWithValue(
        ApiEnvironment(Uri.parse(baseUrl)),
      ),
      httpClientProvider.overrideWithValue(MockClient(server.handle)),
      tokenStoreProvider.overrideWithValue(phone.tokens),
      appDatabaseProvider.overrideWithValue(phone.db),
      keyValueStoreProvider.overrideWithValue(phone.store),
      appConfigProvider.overrideWithValue(
        AppConfig([MapConfigSource(config), const LocalDefaultsConfigSource()]),
      ),
      clockProvider.overrideWithValue(fakeNow),
      if (google != null) googleIdTokenSourceProvider.overrideWithValue(google),
    ],
  );
  addTearDown(container.dispose);
  await restoreSession(container);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const KeluargaMakanApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Ends the app on this phone, as closing it would.
Future<void> closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

/// Types [text] into the field with [key].
Future<void> enterText(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}
