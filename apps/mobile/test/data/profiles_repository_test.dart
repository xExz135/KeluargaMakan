// PRF-01, PRF-03, ACC-08, QUESTIONS #39 and PR #6 review F2: profiles and
// rules fail closed. A failure is never an empty rule list, and nothing here
// can produce "Aman".
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/data/family_profiles_state.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/data/repositories/hard_rules_repository.dart';
import 'package:keluargamakan/data/repositories/profiles_repository.dart';

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

  Future<ApiResult<FamilyProfiles>> list() async =>
      (await container()).read(profilesRepositoryProvider).listProfiles();

  group('consent states (contract-alignment.md 1)', () {
    test('PRF-03 consent given with rules gives RulesSaved', () async {
      respond = (_) => jsonResponse(
        profileListJson([
          profileJson(rules: rulesJson(items: [allergyRuleJson()])),
        ]),
      );
      final rules = valueOf(await list()).members.single.rules as RulesSaved;
      expect(rules.items.single.allergen.toString(), 'peanut');
      expect(rules.checkedByCekAman, isTrue);
    });

    test('PRF-03 consent given with no rules is "no food rules", which '
        'only consent can say', () async {
      respond = (_) => jsonResponse(profileListJson([profileJson()]));
      final rules = valueOf(await list()).members.single.rules;
      expect((rules as RulesSaved).hasNoRules, isTrue);
    });

    for (final (status, chip) in [
      ('none', RulesChip.rulesNotSet),
      ('declined', RulesChip.rulesNotSaved),
      ('withdrawn', RulesChip.rulesNotSaved),
    ]) {
      test('ACC-08 consent $status is RulesNotSaved with the neutral '
          '${chip.name} chip, never checked by Cek Aman', () async {
        respond = (_) => jsonResponse(
          profileListJson([profileJson(rules: rulesJson(consent: status))]),
        );
        final rules = valueOf(await list()).members.single.rules;
        expect(rules, isA<RulesNotSaved>());
        expect((rules as RulesNotSaved).chip, chip);
        expect(rules.checkedByCekAman, isFalse);
        if (status == 'withdrawn') {
          expect(rules.deletionDueBy, DateTime.utc(2026, 12));
        }
      });
    }
  });

  group('fail closed (Q39, F2)', () {
    test('SAF-12 rules_unavailable is an explicit state, not an empty '
        'list', () async {
      respond = (_) => problemResponse('rules_unavailable', 503);
      final result = await list();
      expect(failureOf(result).isRulesUnavailable, isTrue);
      expect(familyStateFrom(result), isA<FamilyRulesUnavailable>());
    });

    final malformed = <String, Object? Function()>{
      'missing rules.items': () {
        final p = profileJson();
        (p['rules']! as Map).remove('items');
        return profileListJson([p]);
      },
      'null rules': () => profileListJson([profileJson()..['rules'] = null]),
      'unknown consent status': () =>
          profileListJson([profileJson(rules: rulesJson(consent: 'maybe'))]),
      'unknown age group': () =>
          profileListJson([profileJson(ageGroup: 'toddler')]),
      'unknown hard rule type': () => profileListJson([
        profileJson(
          rules: rulesJson(
            items: [
              {...allergyRuleJson(), 'type': 'religious_fast'},
            ],
          ),
        ),
      ]),
      'a rule row that is not an object': () => profileListJson([
        profileJson(rules: rulesJson(items: [allergyRuleJson(), 'peanut'])),
      ]),
      'rules next to declined consent': () => profileListJson([
        profileJson(
          rules: rulesJson(consent: 'declined', items: [allergyRuleJson()]),
        ),
      ]),
      'a profile row that is not an object': () => {
        'items': [profileJson(), 7],
        'maxProfiles': 12,
      },
      'missing maxProfiles': () => {
        'items': [profileJson()],
      },
      'missing profile name': () =>
          profileListJson([profileJson()..remove('name')]),
    };
    for (final MapEntry(key: name, value: body) in malformed.entries) {
      test('SAF-12 $name fails the whole list (DecodeFailure)', () async {
        respond = (_) => jsonResponse(body());
        final result = await list();
        expect(failureOf(result), isA<DecodeFailure>());
        expect(familyStateFrom(result), isA<FamilyLoadFailed>());
      });
    }

    test('SAF-12 an empty 200 body is a decode failure, not "no '
        'profiles"', () async {
      respond = (_) => http.Response('', 200);
      expect(failureOf(await list()), isA<DecodeFailure>());
    });

    test('SAF-12 invalid JSON is a decode failure', () async {
      respond = (_) => http.Response('{"items": [', 200);
      expect(failureOf(await list()), isA<DecodeFailure>());
    });

    test('SAF-12 a decode failure never falls back to the cache', () async {
      respond = (_) => jsonResponse(profileListJson([profileJson()]));
      await list();
      respond = (_) => jsonResponse({'items': 'oops', 'maxProfiles': 12});
      expect(failureOf(await list()), isA<DecodeFailure>());
    });

    test('SAF-12 an unknown allergen code in a rule shows as "other '
        'allergy", the rule is not dropped', () async {
      respond = (_) => jsonResponse(
        profileListJson([
          profileJson(
            rules: rulesJson(items: [allergyRuleJson(allergen: 'mustard')]),
          ),
        ]),
      );
      final rules = valueOf(await list()).members.single.rules as RulesSaved;
      expect(rules.items, hasLength(1));
      expect(rules.items.single.allergen, isNull);
    });
  });

  group('offline cache (NFR-05, DAT-02)', () {
    test('NFR-05 offline, cached profiles come back with rules not '
        'loaded', () async {
      respond = (_) => jsonResponse(
        profileListJson([
          profileJson(rules: rulesJson(items: [allergyRuleJson()])),
          profileJson(
            id: 'p-adik',
            name: 'Adik',
            ageGroup: 'child',
            isManager: false,
          ),
        ]),
      );
      await list();
      respond = (_) => throw http.ClientException('offline');

      final cached = valueOf(await list());

      expect(cached.source, isA<FromCache>());
      expect(cached.maxProfiles, isNull);
      expect(cached.members.map((m) => m.name), ['Ibu', 'Adik']);
      expect(cached.members[1].isChild, isTrue);
      for (final m in cached.members) {
        expect(m.rules, isA<RulesNotLoaded>());
        expect(m.rules.checkedByCekAman, isFalse);
        expect(m.details, isNull);
      }
    });

    test('NFR-05 offline with nothing cached is a network failure', () async {
      respond = (_) => throw http.ClientException('offline');
      expect(failureOf(await list()), isA<NetworkFailure>());
    });

    test('DAT-02 hard rules and consent never reach the database', () async {
      const secret = 'TEST FIXTURE rule text';
      respond = (_) => jsonResponse(
        profileListJson([
          profileJson(
            rules: rulesJson(
              items: [allergyRuleJson(), freeTextRuleJson(secret)],
            ),
          ),
        ]),
      );
      expect(await list(), isA<Ok<FamilyProfiles>>());
      final dump = jsonEncode([
        for (final table in db.allTables)
          for (final row in await db.select(table).get())
            (row as dynamic).toJson(),
      ]);
      expect(dump, contains('Ibu'));
      expect(dump, isNot(contains(secret)));
      expect(dump, isNot(contains('peanut')));
      expect(dump, isNot(contains('given')));
    });

    test('PRF-01 a fresh list replaces the cache (members removed on '
        'another phone disappear)', () async {
      respond = (_) => jsonResponse(
        profileListJson([
          profileJson(),
          profileJson(id: 'p-2', name: 'Kakak', isManager: false),
        ]),
      );
      await list();
      respond = (_) => jsonResponse(profileListJson([profileJson()]));
      await list();
      expect(await db.select(db.cachedProfiles).get(), hasLength(1));
    });
  });

  group('writes', () {
    test('PRF-01 createProfile sends the Idempotency-Key', () async {
      final seen = <http.Request>[];
      respond = (r) {
        seen.add(r);
        return jsonResponse(
          profileJson(id: 'p-2', name: 'Kakak', isManager: false),
          201,
        );
      };
      final c = await container();
      final result = await c
          .read(profilesRepositoryProvider)
          .createProfile(
            apiProfileCreate('Kakak'),
            idempotencyKey: '00000000-0000-4000-8000-000000000001',
          );
      expect(valueOf(result).name, 'Kakak');
      expect(
        seen.single.headers['idempotency-key'],
        '00000000-0000-4000-8000-000000000001',
      );
    });

    test('PRF-02 profile_limit_reached is a problem the screen can '
        'name', () async {
      respond = (_) => problemResponse('profile_limit_reached', 409);
      final c = await container();
      final result = await c
          .read(profilesRepositoryProvider)
          .createProfile(apiProfileCreate('X'), idempotencyKey: 'k');
      expect(failureOf(result).problemCode, ApiErrorCode.profileLimitReached);
    });

    test('PRF-01 deleting a profile removes it from the cache', () async {
      respond = (r) => r.method == 'DELETE'
          ? http.Response('', 204)
          : jsonResponse(
              profileListJson([
                profileJson(),
                profileJson(id: 'p-2', name: 'Kakak', isManager: false),
              ]),
            );
      final c = await container();
      final repo = c.read(profilesRepositoryProvider);
      await repo.listProfiles();
      expect(await repo.deleteProfile('p-2'), isA<Ok<void>>());
      final rows = await db.select(db.cachedProfiles).get();
      expect(rows.map((r) => r.id), ['p-ibu']);
    });
  });

  group('hard rules (online only)', () {
    test('PRF-03 listHardRules rules_unavailable is a failure, never an '
        'empty list', () async {
      respond = (_) => problemResponse('rules_unavailable', 503);
      final c = await container();
      final result = await c
          .read(hardRulesRepositoryProvider)
          .listHardRules('p-ibu');
      expect(failureOf(result).isRulesUnavailable, isTrue);
    });

    test('PRF-03 listHardRules with consent none gives the rulesNotSet '
        'chip', () async {
      respond = (_) => jsonResponse(rulesJson(consent: 'none'));
      final c = await container();
      final rules = valueOf(
        await c.read(hardRulesRepositoryProvider).listHardRules('p-ibu'),
      );
      expect((rules as RulesNotSaved).chip, RulesChip.rulesNotSet);
    });

    test(
      'ACC-08 createHardRule without consent returns consent_required',
      () async {
        respond = (_) => problemResponse('consent_required', 409);
        final c = await container();
        final result = await c
            .read(hardRulesRepositoryProvider)
            .createHardRule('p-ibu', apiAllergyRule(), idempotencyKey: 'k-1');
        expect(failureOf(result).problemCode, ApiErrorCode.consentRequired);
      },
    );

    test('PRF-03 a rule without a confirmed match is sent without '
        'mappedIngredientIds (saved as unmapped)', () async {
      final seen = <http.Request>[];
      respond = (r) {
        seen.add(r);
        return jsonResponse(allergyRuleJson(), 201);
      };
      final c = await container();
      await c
          .read(hardRulesRepositoryProvider)
          .createHardRule('p-ibu', apiAllergyRule(), idempotencyKey: 'k-2');
      expect(jsonDecode(seen.single.body), {
        'type': 'allergy',
        'allergen': 'peanut',
      });
      expect(seen.single.headers['idempotency-key'], 'k-2');
    });
  });

  group('FamilyProfilesController', () {
    test('SAF-12 the controller exposes rules_unavailable as its own '
        'state', () async {
      respond = (_) => problemResponse('rules_unavailable', 503);
      final c = await container();
      expect(c.read(familyProfilesProvider), isA<FamilyLoading>());
      await c.read(familyProfilesProvider.notifier).reload();
      expect(c.read(familyProfilesProvider), isA<FamilyRulesUnavailable>());
    });

    test('PRF-01 the controller loads profiles', () async {
      respond = (_) => jsonResponse(profileListJson([profileJson()]));
      final c = await container();
      await c.read(familyProfilesProvider.notifier).reload();
      final state = c.read(familyProfilesProvider) as FamilyLoaded;
      expect(state.profiles.members.single.name, 'Ibu');
    });
  });
}
