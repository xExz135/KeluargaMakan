// SET-03, SET-04, SET-10, ACC-08 (contract 0.1.2, security review T-019 M1,
// QUESTIONS #46 and #62): consent writes carry the state the manager was
// shown, answer consent_changed as its own failure, and are never queued
// offline. renewalRequired keeps stored rules but blocks new health data.
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
import 'package:keluargamakan/data/decoders.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/data/repositories/consent_repository.dart';
import 'package:keluargamakan/data/repositories/profiles_repository.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../helpers/api_fixtures.dart';

Map<String, Object?> _recordJson({
  String id = 'consent-2',
  String decision = 'given',
}) => {
  'id': id,
  'profileId': 'p-adik',
  'purpose': 'health_data',
  'decision': decision,
  'textVersion': 'v2',
  'language': 'id',
  'decidedAt': '2026-11-14T03:00:00Z',
  'recordedByAccountId': 'acc-1',
  'withdrawnAt': null,
  'deletionDueBy': null,
};

ConsentSnapshot _snapshot(String status) =>
    decodeRules(rulesJson(consent: status)).consentSnapshot!;

void main() {
  late AppDatabase db;
  late FutureOr<http.Response> Function(http.Request) respond;
  late List<http.Request> seen;

  setUp(() {
    db = memoryDatabase();
    addTearDown(db.close);
    seen = [];
  });

  Future<ProviderContainer> container() async {
    final c = testContainer(
      handler: (r) async {
        seen.add(r);
        return respond(r);
      },
      tokens: InMemoryTokenStore(testTokens),
      db: db,
    );
    addTearDown(c.dispose);
    await c.read(sessionManagerProvider).load();
    return c;
  }

  Future<ConsentRepository> repo() async =>
      (await container()).read(consentRepositoryProvider);

  Future<ApiResult<api.ConsentRecord>> record(
    ConsentRepository r,
    ConsentSnapshot snapshot, {
    String key = 'k-1',
  }) => r.recordHealthDataConsent(
    'p-adik',
    decision: api.ConsentDecision.given,
    textVersion: 'v2',
    language: api.Language.id,
    seen: snapshot,
    idempotencyKey: key,
  );

  group('precondition (security review T-019 M1)', () {
    test('SET-03 recordHealthDataConsent sends expectedConsent from the '
        'latest rules the API returned', () async {
      respond = (_) => jsonResponse(_recordJson(), 201);
      final r = await repo();

      final result = await record(r, _snapshot('withdrawn'));

      expect(valueOf(result).id, 'consent-2');
      expect(seen.single.method, 'POST');
      expect(jsonDecode(seen.single.body), {
        'decision': 'given',
        'textVersion': 'v2',
        'language': 'id',
        'expectedConsent': {
          'status': 'withdrawn',
          'consentRecordId': 'consent-1',
        },
      });
      expect(seen.single.headers['idempotency-key'], 'k-1');
    });

    test('SET-03 a member with no decision yet sends {status: none, '
        'consentRecordId: null}', () async {
      respond = (_) => jsonResponse(_recordJson(), 201);
      await record(await repo(), _snapshot('none'));
      expect(jsonDecode(seen.single.body)['expectedConsent'], {
        'status': 'none',
        'consentRecordId': null,
      });
    });

    test('SET-03 the snapshot comes from a profile read as well as a rules '
        'read', () async {
      respond = (_) => jsonResponse(
        profileListJson([profileJson(rules: rulesJson(consent: 'declined'))]),
      );
      final c = await container();
      final profiles = valueOf(
        await c.read(profilesRepositoryProvider).listProfiles(),
      );
      final snapshot = profiles.members.single.rules.consentSnapshot;
      expect(snapshot, _snapshot('declined'));
      expect(snapshot!.toApi().status, api.RulesConsentStatus.declined);
      expect(snapshot.consentRecordId, 'consent-1');
    });

    test('SET-04 withdrawHealthDataConsent sends the withdrawal body with '
        'expectedConsent', () async {
      respond = (_) => jsonResponse({
        ..._recordJson(id: 'consent-1'),
        'withdrawnAt': '2026-11-14T03:00:00Z',
        'deletionDueBy': '2026-12-14T03:00:00Z',
      });
      final r = await repo();

      final result = await r.withdrawHealthDataConsent(
        'p-adik',
        seen: _snapshot('given'),
      );

      expect(valueOf(result).deletionDueBy, DateTime.utc(2026, 12, 14, 3));
      expect(seen.single.method, 'POST');
      expect(seen.single.url.path, endsWith('/consents/health-data/withdraw'));
      expect(seen.single.headers['content-type'], contains('application/json'));
      expect(jsonDecode(seen.single.body), {
        'expectedConsent': {'status': 'given', 'consentRecordId': 'consent-1'},
      });
    });

    test('SET-03 rules from the cache give no snapshot, so no consent write '
        'can be built from them', () {
      const cached = RulesNotLoaded();
      expect(cached.consentSnapshot, isNull);
      expect(cached.allowsNewHealthData, isFalse);
    });
  });

  group('409 failures', () {
    test('SET-03 consent_changed on a decision is a ConsentChangedFailure '
        'and is not resent', () async {
      respond = (_) => problemResponse('consent_changed', 409);
      final result = await record(await repo(), _snapshot('given'));
      final failure = failureOf(result);
      expect(failure, isA<ConsentChangedFailure>());
      expect(failure.problemCode, ApiErrorCode.consentChanged);
      expect(seen, hasLength(1));
    });

    test('SET-04 consent_changed on a withdrawal is a '
        'ConsentChangedFailure', () async {
      respond = (_) => problemResponse('consent_changed', 409);
      final r = await repo();
      final result = await r.withdrawHealthDataConsent(
        'p-adik',
        seen: _snapshot('given'),
      );
      expect(failureOf(result), isA<ConsentChangedFailure>());
      expect(seen, hasLength(1));
    });

    test('PRF-18 manager_profile_must_be_adult is its own failure '
        '(QUESTIONS #46)', () async {
      respond = (_) => problemResponse('manager_profile_must_be_adult', 409);
      final c = await container();
      final result = await c
          .read(profilesRepositoryProvider)
          .updateProfile(
            'p-ibu',
            api.ProfileUpdate(
              ageGroup: const api.Optional.present(api.AgeGroup.teen),
            ),
          );
      final failure = failureOf(result);
      expect(failure, isA<ManagerProfileMustBeAdultFailure>());
      expect(failure, isNot(isA<ConsentChangedFailure>()));
      expect(failure.problemCode, ApiErrorCode.managerProfileMustBeAdult);
    });

    test('SET-03 other consent codes stay plain problem failures', () async {
      respond = (_) => problemResponse('consent_text_outdated', 409);
      final failure = failureOf(await record(await repo(), _snapshot('none')));
      expect(failure, isA<ProblemFailure>());
      expect(failure, isNot(isA<ConsentChangedFailure>()));
      expect(failure.problemCode, ApiErrorCode.consentTextOutdated);
    });
  });

  group('fail closed (SAF-12)', () {
    test('SAF-12 a consent record with an unknown decision is a decode '
        'failure', () async {
      respond = (_) => jsonResponse(_recordJson(decision: 'maybe'), 201);
      final result = await record(await repo(), _snapshot('none'));
      expect(failureOf(result), isA<DecodeFailure>());
    });

    test('SAF-12 an empty 200 answer to a withdrawal is a decode '
        'failure', () async {
      respond = (_) => http.Response('', 200);
      final r = await repo();
      final result = await r.withdrawHealthDataConsent(
        'p-adik',
        seen: _snapshot('given'),
      );
      expect(failureOf(result), isA<DecodeFailure>());
    });
  });

  group('online only (never queued offline)', () {
    test('SET-03 an offline decision fails at once, is stored nowhere and is '
        'not replayed when the phone is back online', () async {
      respond = (_) => throw http.ClientException('offline');
      final c = await container();
      final consent = c.read(consentRepositoryProvider);

      final offline = await record(consent, _snapshot('none'));
      final offlineWithdraw = await consent.withdrawHealthDataConsent(
        'p-adik',
        seen: _snapshot('given'),
      );

      expect(failureOf(offline), isA<NetworkFailure>());
      expect(failureOf(offlineWithdraw), isA<NetworkFailure>());
      for (final table in db.allTables) {
        expect(
          await db.select(table).get(),
          isEmpty,
          reason:
              '${table.actualTableName} holds nothing after a failed '
              'consent write',
        );
      }

      seen.clear();
      respond = (_) => jsonResponse(profileListJson([profileJson()]));
      await c.read(profilesRepositoryProvider).listProfiles();
      expect(seen.map((r) => r.url.path), ['/v1/household/profiles']);
    });
  });

  group('renewalRequired (QUESTIONS #62)', () {
    test('SET-10 renewalRequired keeps the stored rules, still checked by '
        'Cek Aman, but blocks new health data', () async {
      respond = (_) => jsonResponse(
        profileListJson([
          profileJson(
            id: 'p-adik',
            name: 'Adik',
            ageGroup: 'child',
            isManager: false,
            rules: rulesJson(renewalRequired: true, items: [allergyRuleJson()]),
          ),
        ]),
      );
      final c = await container();
      final member = valueOf(
        await c.read(profilesRepositoryProvider).listProfiles(),
      ).members.single;
      final rules = member.rules as RulesSaved;

      expect(rules.renewalRequired, isTrue);
      expect(rules.items, hasLength(1));
      expect(rules.checkedByCekAman, isTrue);
      expect(rules.allowsNewHealthData, isFalse);
      expect(rules.consentSnapshot, _snapshot('given'));
      expect(member.healthDataConsentAudience, api.ConsentAudience.child);
    });

    test('SET-03 a given consent without renewal allows new health '
        'data', () {
      final rules = decodeRules(rulesJson()) as RulesSaved;
      expect(rules.renewalRequired, isFalse);
      expect(rules.allowsNewHealthData, isTrue);
    });

    for (final status in ['none', 'declined', 'withdrawn']) {
      test('ACC-08 consent $status never allows new health data', () {
        expect(
          decodeRules(rulesJson(consent: status)).allowsNewHealthData,
          isFalse,
        );
      });
    }

    final malformed = <String, Map<String, Object?> Function()>{
      'missing renewalRequired': () =>
          rulesJson()
            ..['consent'] = (consentJson('given')..remove('renewalRequired')),
      'a non-bool renewalRequired': () =>
          rulesJson()
            ..['consent'] = {...consentJson('given'), 'renewalRequired': 'no'},
      'renewalRequired next to a declined consent': () =>
          rulesJson(consent: 'declined', renewalRequired: true),
      'a given consent without a record ID': () =>
          rulesJson()
            ..['consent'] = {...consentJson('given'), 'consentRecordId': null},
      'a non-string record ID': () =>
          rulesJson()
            ..['consent'] = {...consentJson('given'), 'consentRecordId': 7},
    };
    for (final MapEntry(key: name, value: body) in malformed.entries) {
      test('SAF-12 $name fails decoding', () {
        expect(() => decodeRules(body()), throwsFormatException);
      });

      test('SAF-12 $name fails the profile list (DecodeFailure)', () async {
        respond = (_) =>
            jsonResponse(profileListJson([profileJson(rules: body())]));
        final c = await container();
        final result = await c.read(profilesRepositoryProvider).listProfiles();
        expect(failureOf(result), isA<DecodeFailure>());
      });
    }
  });

  group('consent text audience (SET-10)', () {
    test('SET-10 the health-data text is asked for the member\'s '
        'audience', () async {
      respond = (_) => problemResponse('not_found', 404);
      final r = await repo();
      await r.getConsentText(
        api.ConsentPurpose.healthData,
        api.Language.id,
        audience: api.ConsentAudience.child,
      );
      await r.getConsentText(
        api.ConsentPurpose.guardianConfirmation,
        api.Language.en,
      );
      expect(seen[0].url.path, '/v1/consent-texts/health_data');
      expect(seen[0].url.queryParameters, {
        'language': 'id',
        'audience': 'child',
      });
      expect(seen[1].url.queryParameters, {'language': 'en'});
    });

    test('SET-10 adults get the adult text', () {
      final adult = decodeProfile(profileJson());
      expect(adult.healthDataConsentAudience, api.ConsentAudience.adult);
    });
  });
}
