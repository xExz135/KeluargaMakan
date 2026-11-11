// ACC-13 and security review M2: cached household data never outlives the
// session and is never shown to another account.
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/data/decoders.dart';
import 'package:keluargamakan/data/local_cache.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/data/repositories/auth_repository.dart';
import 'package:keluargamakan/data/repositories/household_repository.dart';
import 'package:keluargamakan/data/repositories/profiles_repository.dart';
import 'package:keluargamakan/data/session_restore.dart';

import '../helpers/api_fixtures.dart';

void main() {
  late AppDatabase db;
  late FutureOr<http.Response> Function(http.Request) respond;

  setUp(() {
    db = memoryDatabase();
    addTearDown(db.close);
    respond = (_) => throw http.ClientException('offline');
  });

  ProviderContainer container(TokenStore tokens) {
    final c = testContainer(
      handler: (r) async => respond(r),
      tokens: tokens,
      db: db,
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Caches a household and two profiles as account acc-1.
  Future<ProviderContainer> cachedAsAcc1() async {
    final c = container(InMemoryTokenStore(testTokens));
    await c.read(sessionManagerProvider).load();
    final cache = c.read(localCacheProvider);
    await cache.saveHousehold(decodeHousehold(householdJson()));
    await cache.saveProfiles(
      decodeProfileList(
        profileListJson([
          profileJson(),
          profileJson(id: 'p-adik', name: 'Adik', ageGroup: 'child'),
        ]),
      ).members,
    );
    expect(await db.select(db.cachedProfiles).get(), hasLength(2));
    return c;
  }

  Map<String, Object?> sessionFor(String accountId) => {
    'tokens': tokensJson(accountId),
    'account': {...accountJson(), 'id': accountId},
    'isNewAccount': false,
  };

  test('ACC-13 at startup without a session, cached household data is '
      'wiped', () async {
    await cachedAsAcc1();

    final fresh = container(InMemoryTokenStore());
    await restoreSession(fresh);

    expect(await db.select(db.cachedHouseholds).get(), isEmpty);
    expect(await db.select(db.cachedProfiles).get(), isEmpty);
  });

  test('ACC-13 at startup with the owning session, the cache stays', () async {
    await cachedAsAcc1();
    final again = container(InMemoryTokenStore(testTokens));
    await restoreSession(again);
    expect(await again.read(localCacheProvider).household(), isNotNull);
  });

  test('ACC-13 a different account signing in never sees the previous '
      'household, even offline', () async {
    await cachedAsAcc1();
    final b = container(InMemoryTokenStore());
    await restoreSession(b);
    respond = (r) => r.url.path == '/v1/auth/code/verify'
        ? jsonResponse(sessionFor('acc-2'))
        : throw http.ClientException('offline');

    final signIn = await b
        .read(authRepositoryProvider)
        .verifySignInCode(
          challengeId: '6f1a2b3c-4d5e-4f60-8a7b-9c0d1e2f3a4b',
          code: '123456',
        );
    expect(signIn, isA<Ok<SignedIn>>());

    final household = await b.read(householdRepositoryProvider).getHousehold();
    final profiles = await b.read(profilesRepositoryProvider).listProfiles();
    expect(failureOf(household), isA<NetworkFailure>());
    expect(failureOf(profiles), isA<NetworkFailure>());
    expect(await db.select(db.cachedProfiles).get(), isEmpty);
  });

  test('ACC-13 a cache left by another account (failed wipe) is not '
      'readable', () async {
    await cachedAsAcc1();
    final other = container(
      InMemoryTokenStore(
        SessionTokens(
          accountId: 'acc-2',
          accessToken: 'a',
          accessTokenExpiresAt: DateTime.utc(2026, 11, 12),
          refreshToken: 'r',
          refreshTokenExpiresAt: DateTime.utc(2026, 12, 12),
        ),
      ),
    );
    await other.read(sessionManagerProvider).load();
    final cache = other.read(localCacheProvider);

    expect(await cache.household(), isNull);
    expect(await cache.profiles(), isNull);
    expect(
      failureOf(await other.read(profilesRepositoryProvider).listProfiles()),
      isA<NetworkFailure>(),
    );
  });

  test('ACC-13 with no session, nothing is read or written', () async {
    await cachedAsAcc1();
    final none = container(InMemoryTokenStore());
    await none.read(sessionManagerProvider).load();
    final cache = none.read(localCacheProvider);

    expect(await cache.household(), isNull);
    expect(await cache.profiles(), isNull);
    await cache.saveProfiles(const <FamilyMember>[]);
    expect(await db.select(db.cachedProfiles).get(), hasLength(2));
  });

  test('ACC-13 sign-out wipes local data before telling the server and '
      'before clearing tokens', () async {
    final c = await cachedAsAcc1();
    final session = c.read(sessionManagerProvider);
    final rowsAtSignOutRequest = <int>[];
    respond = (r) async {
      rowsAtSignOutRequest.add(
        (await db.select(db.cachedProfiles).get()).length,
      );
      expect(session.isSignedIn, isTrue);
      return http.Response('', 204);
    };

    final outcome = await c.read(authRepositoryProvider).signOut();

    expect(outcome, SignOutOutcome.done);
    expect(rowsAtSignOutRequest, [0]);
    expect(session.isSignedIn, isFalse);
  });

  test('ACC-13 a failing wipe is retried, reported and does not keep the '
      'session', () async {
    final tokens = InMemoryTokenStore(testTokens);
    final c = container(tokens);
    final session = c.read(sessionManagerProvider);
    await session.load();
    var attempts = 0;
    var signedInDuringWipe = false;
    session.addEndHandler((_) async {
      attempts++;
      signedInDuringWipe = session.isSignedIn;
      throw StateError('disk full');
    });
    final errors = <Object>[];
    session.ended.listen((_) {}, onError: errors.add);

    final outcome = await c.read(authRepositoryProvider).signOut();

    expect(outcome, SignOutOutcome.localDataNotCleared);
    expect(attempts, greaterThanOrEqualTo(2));
    expect(signedInDuringWipe, isTrue);
    expect(session.isSignedIn, isFalse);
    expect(await tokens.read(), isNull);
    await pumpEventQueue();
    expect(errors.single, isA<SessionDataNotCleared>());
  });

  test('ACC-13 the stored session keeps its account across a token '
      'rotation', () async {
    final tokens = InMemoryTokenStore(testTokens);
    final c = container(tokens);
    await c.read(sessionManagerProvider).load();
    respond = (r) {
      if (r.url.path == '/v1/auth/refresh') {
        return jsonResponse(tokensJson('2'));
      }
      return r.headers['authorization'] == 'Bearer access-2'
          ? jsonResponse(accountJson())
          : problemResponse('access_token_expired', 401);
    };
    await c.read(authRepositoryProvider).getAccount();
    expect((await tokens.read())!.accountId, 'acc-1');
  });

  test('ACC-13 a stored session without an account ID is not '
      'trusted', () {
    final json = testTokens.toJson()..remove('accountId');
    expect(SessionTokens.fromJson(json), isNull);
  });
}
