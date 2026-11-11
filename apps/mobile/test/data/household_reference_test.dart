// ACC-03, NFR-16 (F4), PRF-04, NFR-05: the household, its time zone, and the
// standard allergen list, with their on-device caches.
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/core/time/household_time.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/data/repositories/household_repository.dart';
import 'package:keluargamakan/data/repositories/reference_repository.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../helpers/api_fixtures.dart';

void main() {
  late AppDatabase db;
  late FutureOr<http.Response> Function(http.Request) respond;

  setUp(() {
    db = memoryDatabase();
    addTearDown(db.close);
  });

  Future<ProviderContainer> container() async {
    final c = testContainer(
      handler: (r) async => respond(r),
      tokens: InMemoryTokenStore(testTokens),
      db: db,
    );
    addTearDown(c.dispose);
    await c.read(sessionManagerProvider).load();
    return c;
  }

  group('household', () {
    test('NFR-16 loading the household sets the date zone from '
        'timeZone', () async {
      respond = (_) => jsonResponse(householdJson(timeZone: 'Asia/Jayapura'));
      final c = await container();
      final h = valueOf(
        await c.read(householdRepositoryProvider).getHousehold(),
      );
      expect(h.timeZone, HouseholdTimeZone.wit);
      expect(c.read(householdTimeZoneProvider), HouseholdTimeZone.wit);
    });

    test(
      'NFR-05 offline, the cached household is used, with its zone',
      () async {
        respond = (_) => jsonResponse(householdJson(timeZone: 'Asia/Makassar'));
        final c = await container();
        final repo = c.read(householdRepositoryProvider);
        await repo.getHousehold();
        respond = (_) => throw http.ClientException('offline');

        final cached = valueOf(await repo.getHousehold());

        expect(cached.source, isA<FromCache>());
        expect(cached.name, 'Keluarga Contoh');
        expect(cached.language, api.Language.id);
        expect(cached.timeZone, HouseholdTimeZone.wita);
      },
    );

    test('ACC-04 household_required is a problem, not an empty '
        'household', () async {
      respond = (_) => problemResponse('household_required', 409);
      final c = await container();
      final result = await c.read(householdRepositoryProvider).getHousehold();
      expect(failureOf(result).problemCode, ApiErrorCode.householdRequired);
    });

    test('ACC-13 signing out forgets the household zone and cache', () async {
      respond = (_) => jsonResponse(householdJson(timeZone: 'Asia/Jayapura'));
      final c = await container();
      await c.read(householdRepositoryProvider).getHousehold();
      await c.read(sessionManagerProvider).end(SessionEndReason.signedOut);
      expect(c.read(knownHouseholdTimeZoneProvider), isNull);
      expect(await db.select(db.cachedHouseholds).get(), isEmpty);
    });
  });

  group('standard allergens', () {
    test('PRF-04 the list keeps the API order and leaves out unknown '
        'codes', () async {
      respond = (_) => jsonResponse({
        'ruleSetVersion': '1.1.0',
        'items': ['shrimp', 'mustard', 'shellfish', 'peanut'],
      });
      final c = await container();
      final list = valueOf(
        await c.read(referenceRepositoryProvider).listStandardAllergens(),
      );
      expect(list.items, [
        api.StandardAllergen.shrimp,
        api.StandardAllergen.shellfish,
        api.StandardAllergen.peanut,
      ]);
      expect(list.ruleSetVersion, '1.1.0');
    });

    test('NFR-05 offline, the cached list is used in the same order', () async {
      respond = (_) => jsonResponse({
        'ruleSetVersion': '1.1.0',
        'items': ['wheat', 'gluten', 'egg'],
      });
      final c = await container();
      final repo = c.read(referenceRepositoryProvider);
      await repo.listStandardAllergens();
      respond = (_) => throw http.ClientException('offline');

      final cached = valueOf(await repo.listStandardAllergens());

      expect(cached.source, isA<FromCache>());
      expect(cached.items, [
        api.StandardAllergen.wheat,
        api.StandardAllergen.gluten,
        api.StandardAllergen.egg,
      ]);
    });

    test('PRF-04 a list without items is a decode failure, not an empty '
        'picker', () async {
      respond = (_) => jsonResponse({'ruleSetVersion': '1.1.0'});
      final c = await container();
      final result = await c
          .read(referenceRepositoryProvider)
          .listStandardAllergens();
      expect(failureOf(result), isA<DecodeFailure>());
    });

    test('ACC-13 the public allergen list survives sign-out', () async {
      respond = (_) => jsonResponse({
        'ruleSetVersion': '1.1.0',
        'items': ['egg'],
      });
      final c = await container();
      await c.read(referenceRepositoryProvider).listStandardAllergens();
      await c.read(sessionManagerProvider).end(SessionEndReason.signedOut);
      expect(await db.select(db.cachedAllergens).get(), hasLength(1));
    });
  });
}
