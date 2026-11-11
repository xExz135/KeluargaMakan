// ACC-13: bearer auth, silent refresh with token rotation, and the end of a
// session (contract-alignment.md 5). MockClient only; there is no backend.
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan_api/api.dart' as api;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/data/decoders.dart';
import 'package:keluargamakan/data/local_cache.dart';
import 'package:keluargamakan/data/repositories/auth_repository.dart';
import 'package:keluargamakan/data/repositories/household_repository.dart';

import '../helpers/api_fixtures.dart';

void main() {
  late List<http.Request> requests;
  late InMemoryTokenStore tokens;

  setUp(() {
    requests = [];
    tokens = InMemoryTokenStore(testTokens);
  });

  Future<ProviderContainer> signedIn(
    FutureOr<http.Response> Function(http.Request) handler, {
    AppDatabase? db,
  }) async {
    final c = testContainer(
      handler: (r) async {
        requests.add(r);
        return handler(r);
      },
      tokens: tokens,
      db: db,
    );
    addTearDown(c.dispose);
    await c.read(sessionManagerProvider).load();
    return c;
  }

  String? bearer(http.Request r) => r.headers['authorization'];

  test('ACC-13 requests carry the bearer token from the token store', () async {
    final c = await signedIn((_) => jsonResponse(accountJson()));
    final result = await c.read(authRepositoryProvider).getAccount();
    expect(result, isA<Ok<Object?>>());
    expect(requests.single.url.toString(), '$testBaseUrl/v1/account');
    expect(bearer(requests.single), 'Bearer access-1');
  });

  test('ACC-01 public sign-in endpoints never send a bearer token', () async {
    final c = await signedIn(
      (_) => jsonResponse({
        'challengeId': '6f1a2b3c-4d5e-4f60-8a7b-9c0d1e2f3a4b',
        'channel': 'phone',
        'codeLength': 6,
        'expiresAt': '2026-11-11T12:10:00Z',
        'resendAvailableAt': '2026-11-11T12:01:00Z',
      }),
    );
    final result = await c
        .read(authRepositoryProvider)
        .requestSignInCode(
          channel: api.SignInChannel.phone,
          destination: '+6281200000000',
          language: api.Language.id,
        );
    expect(result, isA<Ok<Object?>>());
    expect(bearer(requests.single), isNull);
  });

  test('ACC-13 an expired access token is refreshed once, rotated tokens are '
      'stored, and the request is repeated', () async {
    final c = await signedIn((r) {
      if (r.url.path == '/v1/auth/refresh') {
        expect(bearer(r), isNull);
        expect(jsonDecode(r.body), {'refreshToken': 'refresh-1'});
        return jsonResponse(tokensJson('2'));
      }
      return bearer(r) == 'Bearer access-2'
          ? jsonResponse(accountJson())
          : problemResponse('access_token_expired', 401);
    });

    final result = await c.read(authRepositoryProvider).getAccount();

    expect(result, isA<Ok<Object?>>());
    expect(requests.map((r) => r.url.path), [
      '/v1/account',
      '/v1/auth/refresh',
      '/v1/account',
    ]);
    final stored = await tokens.read();
    expect(stored!.accessToken, 'access-2');
    expect(stored.refreshToken, 'refresh-2');
  });

  test('ACC-13 a repeated POST keeps its body and Idempotency-Key', () async {
    final c = await signedIn((r) {
      if (r.url.path == '/v1/auth/refresh') {
        return jsonResponse(tokensJson('2'));
      }
      return bearer(r) == 'Bearer access-2'
          ? jsonResponse(householdJson(), 201)
          : problemResponse('access_token_expired', 401);
    });

    await c
        .read(householdRepositoryProvider)
        .createHousehold(
          api.HouseholdCreate(
            timeZone: 'Asia/Makassar',
            language: api.Language.id,
            managerProfile: api.ManagerProfileCreate(name: 'Ibu'),
          ),
          idempotencyKey: '00000000-0000-4000-8000-000000000001',
        );

    final posts = requests.where((r) => r.url.path == '/v1/household');
    expect(posts, hasLength(2));
    expect(posts.last.body, posts.first.body);
    expect(
      posts.last.headers['idempotency-key'],
      '00000000-0000-4000-8000-000000000001',
    );
  });

  test('ACC-13 requests that fail together share a single refresh (a '
      'refresh token works once)', () async {
    var refreshes = 0;
    final c = await signedIn((r) async {
      if (r.url.path == '/v1/auth/refresh') {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse(tokensJson('2'));
      }
      return bearer(r) == 'Bearer access-2'
          ? jsonResponse(accountJson())
          : problemResponse('access_token_expired', 401);
    });
    final repo = c.read(authRepositoryProvider);

    final results = await Future.wait([
      repo.getAccount(),
      repo.getAccount(),
      repo.getAccount(),
    ]);

    expect(results, everyElement(isA<Ok<Object?>>()));
    expect(refreshes, 1);
  });

  test('ACC-13 refresh_token_invalid ends the session, clears tokens and '
      'cached household data, and reports signed out', () async {
    final db = memoryDatabase();
    final c = await signedIn((r) {
      if (r.url.path == '/v1/auth/refresh') {
        return problemResponse('refresh_token_invalid', 401);
      }
      return problemResponse('access_token_expired', 401);
    }, db: db);
    final cache = c.read(localCacheProvider);
    await cache.saveHousehold(decodeHousehold(householdJson()));
    final ended = <SessionEndReason>[];
    c.read(sessionManagerProvider).ended.listen(ended.add);

    final result = await c.read(authRepositoryProvider).getAccount();

    expect(failureOf(result).problemCode, ApiErrorCode.refreshTokenInvalid);
    expect(failureOf(result).isSignedOut, isTrue);
    expect(await tokens.read(), isNull);
    expect(c.read(sessionManagerProvider).isSignedIn, isFalse);
    expect(await cache.household(), isNull);
    await pumpEventQueue();
    expect(ended, [SessionEndReason.expired]);
  });

  test('ACC-13 a refresh endpoint outage keeps the session', () async {
    final c = await signedIn((r) {
      if (r.url.path == '/v1/auth/refresh') {
        return problemResponse('service_unavailable', 503);
      }
      return problemResponse('access_token_expired', 401);
    });

    final result = await c.read(authRepositoryProvider).getAccount();

    expect(failureOf(result).problemCode, ApiErrorCode.serviceUnavailable);
    expect((await tokens.read())!.refreshToken, 'refresh-1');
  });

  test('ACC-13 a refresh that cannot be reached is a network failure and '
      'keeps the session', () async {
    final c = await signedIn((r) {
      if (r.url.path == '/v1/auth/refresh') {
        throw http.ClientException('offline');
      }
      return problemResponse('access_token_expired', 401);
    });

    final result = await c.read(authRepositoryProvider).getAccount();

    expect(failureOf(result), isA<NetworkFailure>());
    expect((await tokens.read())!.refreshToken, 'refresh-1');
  });

  test('ACC-13 an unreadable 200 from refresh ends the session (the old '
      'refresh token is used up)', () async {
    final c = await signedIn((r) {
      if (r.url.path == '/v1/auth/refresh') {
        return jsonResponse({'accessToken': 'only-half'});
      }
      return problemResponse('access_token_expired', 401);
    });

    final result = await c.read(authRepositoryProvider).getAccount();

    expect(result, isA<Err<Object?>>());
    expect(await tokens.read(), isNull);
  });

  test('ACC-13 other 401 and 403 answers are not retried', () async {
    final c = await signedIn((_) => problemResponse('forbidden', 403));
    final result = await c.read(authRepositoryProvider).getAccount();
    expect(failureOf(result).problemCode, ApiErrorCode.forbidden);
    expect(requests, hasLength(1));
  });

  test('NFR-05 a request that times out is a network failure', () async {
    final c = testContainer(
      handler: (_) => Completer<http.Response>().future,
      tokens: tokens,
      config: {'api.requestTimeoutMs': 1000},
    );
    addTearDown(c.dispose);
    await c.read(sessionManagerProvider).load();

    final result = await c.read(authRepositoryProvider).getAccount();
    expect(failureOf(result), isA<NetworkFailure>());
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('NFR-05 a build without KM_API_BASE_URL sends nothing', () async {
    final c = testContainer(
      handler: (r) async {
        requests.add(r);
        return jsonResponse(accountJson());
      },
      baseUrl: '',
    );
    addTearDown(c.dispose);
    final result = await c.read(authRepositoryProvider).getAccount();
    expect(failureOf(result), isA<NotConfiguredFailure>());
    expect(requests, isEmpty);
  });

  test('ACC-13 sign-in stores the session; sign-out clears it even '
      'offline', () async {
    tokens = InMemoryTokenStore();
    final c = testContainer(
      handler: (r) async {
        requests.add(r);
        if (r.url.path == '/v1/auth/code/verify') {
          return jsonResponse({
            'tokens': tokensJson('9'),
            'account': accountJson(),
            'isNewAccount': false,
          });
        }
        throw http.ClientException('offline');
      },
      tokens: tokens,
    );
    addTearDown(c.dispose);
    final repo = c.read(authRepositoryProvider);

    final signIn = await repo.verifySignInCode(
      challengeId: '6f1a2b3c-4d5e-4f60-8a7b-9c0d1e2f3a4b',
      code: '123456',
    );
    expect(signIn, isA<Ok<SignedIn>>());
    expect((await tokens.read())!.accessToken, 'access-9');
    final device = (jsonDecode(requests.single.body) as Map)['device'] as Map;
    expect(device['platform'], 'android');
    expect(device['installationId'], matches(RegExp(r'^[0-9a-f-]{36}$')));

    await repo.signOut();
    expect(await tokens.read(), isNull);
    expect(repo.isSignedIn, isFalse);
  });

  test('ACC-13 tokens are never printed', () {
    expect(testTokens.toString(), isNot(contains('access-1')));
  });
}
