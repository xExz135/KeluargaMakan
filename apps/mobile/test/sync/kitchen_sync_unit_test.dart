// KIT-16 offline queue building blocks: the age of a change on a monotonic
// clock, backoff with jitter from config, the collapse rules, the stored
// form of a change, the strict sync answer decoder and the account binding
// of a sync request.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/auth_http_client.dart';
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/config/app_config.dart';
import 'package:keluargamakan/data/kitchen_decoders.dart';
import 'package:keluargamakan/data/models/kitchen.dart';
import 'package:keluargamakan/data/repositories/kitchen_repository.dart';
import 'package:keluargamakan/data/text_rules.dart';
import 'package:keluargamakan/sync/backoff.dart';
import 'package:keluargamakan/sync/device_clock.dart';
import 'package:keluargamakan/sync/kitchen_change.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../helpers/api_fixtures.dart';

const _boot = ClockReading(timeline: 'boot:3', elapsedMs: 0, wallMs: 0);

ClockReading _at(String timeline, int elapsedMs, int wallMs) =>
    ClockReading(timeline: timeline, elapsedMs: elapsedMs, wallMs: wallMs);

QueuedChange _change(
  int seq,
  IngredientKey ingredient, {
  KitchenChangeOp op = KitchenChangeOp.upsert,
  KitchenPatch patch = const KitchenPatch(),
}) => QueuedChange(
  seq: seq,
  changeId: 'id-$seq',
  ingredient: ingredient,
  op: op,
  patch: patch,
  stamp: _boot,
);

void main() {
  group('KIT-16 the age of a queued change', () {
    test('KIT-16 on the same boot the monotonic clock decides; a changed '
        'phone clock does not move the age', () {
      final then = _at('boot:3', 10000, 1763190000000);
      // The user set the phone's clock back a day meanwhile.
      final now = _at('boot:3', 70000, 1763190000000 - 86400000);
      expect(ageBetween(then, now), 60000);
      // Set forward a week: still one minute.
      final later = _at('boot:3', 70000, 1763190000000 + 7 * 86400000);
      expect(ageBetween(then, later), 60000);
    });

    test('KIT-16 after a restart the wall clock is used, but the change is '
        'never younger than the current boot', () {
      final then = _at('boot:3', 10000, 1763190000000);
      expect(
        ageBetween(then, _at('boot:4', 5000, 1763190000000 + 3600000)),
        3600000,
      );
      // The clock was set back before the change: at least since boot.
      expect(ageBetween(then, _at('boot:4', 5000, 1763100000000)), 5000);
    });

    test('KIT-16 L2 elapsed time going back on the same timeline label is a '
        'new timeline: the wall clock decides, never age 0', () {
      // The label repeated after a restart (a boot counter that did not
      // move): the change is ten days old, not new.
      const then = ClockReading(
        timeline: 'boot:5',
        elapsedMs: 9000000,
        wallMs: 1000,
      );
      const now = ClockReading(
        timeline: 'boot:5',
        elapsedMs: 60000,
        wallMs: 1000 + 10 * 86400000,
      );
      expect(ageBetween(then, now), 10 * 86400000);
      // Still never younger than the new timeline.
      expect(
        ageBetween(
          then,
          const ClockReading(timeline: 'boot:5', elapsedMs: 60000, wallMs: 0),
        ),
        60000,
      );
    });

    test('KIT-16 L1 an unstamped change is marked so, and a stamped one is '
        'not', () {
      final draft = QueuedChange(
        seq: 1,
        changeId: 'd',
        ingredient: const ReferenceIngredient('fx_kit_tempe'),
        op: KitchenChangeOp.upsert,
        patch: const KitchenPatch(state: KitchenItemState.out),
        stamp: const ClockReading(
          timeline: QueuedChange.pendingTimeline,
          elapsedMs: 0,
          wallMs: 0,
        ),
      );
      expect(draft.isStamped, isFalse);
      expect(_change(2, const ReferenceIngredient('x')).isStamped, isTrue);
    });

    test('KIT-16 an age is never negative', () {
      // The wall clock was set back: never below zero, and never below the
      // time on the current timeline.
      expect(ageBetween(_at('boot:1', 1000, 5000), _at('boot:2', 0, 0)), 0);
      expect(ageBetween(_at('boot:1', 9000, 0), _at('boot:1', 1000, 0)), 1000);
    });

    test('KIT-16 without the Android channel the clock falls back to a '
        'stopwatch for this run, never throws', () async {
      final clock = PlatformDeviceClock(random: Random(1));
      final a = await clock.read();
      final b = await clock.read();
      expect(a.timeline, startsWith('process:'));
      expect(b.timeline, a.timeline);
      expect(b.elapsedMs, greaterThanOrEqualTo(a.elapsedMs));
    });
  });

  group('KIT-16 SRS 19.4 backoff with jitter from config', () {
    test('KIT-16 the wait doubles up to the ceiling', () {
      final b = Backoff(baseMs: 1000, maxMs: 8000, jitterPercent: 0);
      expect(
        [for (var i = 1; i <= 6; i++) b.delayFor(i).inMilliseconds],
        [1000, 2000, 4000, 8000, 8000, 8000],
      );
      // A very long outage never overflows.
      expect(b.delayFor(1000).inMilliseconds, 8000);
    });

    test('KIT-16 jitter takes off at most the configured share', () {
      final b = Backoff(
        baseMs: 1000,
        maxMs: 60000,
        jitterPercent: 50,
        random: Random(7),
      );
      for (var i = 0; i < 200; i++) {
        final ms = b.delayFor(3).inMilliseconds;
        expect(ms, inInclusiveRange(2000, 4000));
      }
    });

    test('KIT-16 the values come from config, not constants', () {
      const config = AppConfig([
        MapConfigSource({
          'sync.retryBaseMs': 500,
          'sync.retryMaxMs': 1500,
          'sync.retryJitterPercent': 0,
        }),
      ]);
      final b = Backoff.fromConfig(config);
      expect(b.delayFor(1).inMilliseconds, 500);
      expect(b.delayFor(5).inMilliseconds, 1500);
    });
  });

  group('KIT-16 the queue collapses per ingredient only where safe', () {
    const tempe = ReferenceIngredient('fx_kit_tempe');
    const tahu = ReferenceIngredient('fx_kit_tahu');

    test('KIT-16 a later tap replaces an earlier tap on the same '
        'ingredient, and never one on another ingredient', () {
      final first = _change(
        1,
        tempe,
        patch: const KitchenPatch(state: KitchenItemState.out),
      );
      final other = _change(
        2,
        tahu,
        patch: const KitchenPatch(state: KitchenItemState.out),
      );
      final next = _change(
        3,
        tempe,
        patch: const KitchenPatch(state: KitchenItemState.available),
      );
      expect(changesReplacedBy(next, [first, other]), {'id-1'});
    });

    test('KIT-16 a change on its way is never replaced', () {
      final first = _change(
        1,
        tempe,
        patch: const KitchenPatch(state: KitchenItemState.out),
      );
      final next = _change(
        2,
        tempe,
        patch: const KitchenPatch(state: KitchenItemState.available),
      );
      expect(changesReplacedBy(next, [first], inFlight: {'id-1'}), isEmpty);
    });

    test('KIT-16 a tap does not replace an add that also set the category '
        '(the server would lose what the add needs)', () {
      final add = _change(
        1,
        const CustomIngredient('Sambal roa'),
        patch: const KitchenPatch(
          category: api.KitchenCategory.saucesCondiments,
          state: KitchenItemState.available,
        ),
      );
      final tap = _change(
        2,
        const CustomIngredient('sambal  ROA'),
        patch: const KitchenPatch(state: KitchenItemState.out),
      );
      expect(add.key, tap.key);
      expect(changesReplacedBy(tap, [add]), isEmpty);
    });

    test('KIT-16 a removal replaces every earlier change; Undo with the '
        'whole item replaces the removal', () {
      final tap = _change(
        1,
        tempe,
        patch: const KitchenPatch(state: KitchenItemState.out),
      );
      final remove = _change(2, tempe, op: KitchenChangeOp.remove);
      expect(changesReplacedBy(remove, [tap]), {'id-1'});
      final item = KitchenEntry(
        id: 'k-1',
        ingredientId: 'fx_kit_tempe',
        displayName: null,
        customName: null,
        category: api.KitchenCategory.protein,
        state: KitchenItemState.out,
        isDefaultStaple: false,
        usageRank: null,
        changedAt: DateTime.utc(2026, 11, 15),
        createdAt: DateTime.utc(2026, 11, 15),
      );
      final undo = _change(3, tempe, patch: KitchenPatch.snapshotOf(item));
      expect(changesReplacedBy(undo, [remove]), {'id-2'});
      // A plain tap after a removal keeps the removal.
      final later = _change(
        4,
        tempe,
        patch: const KitchenPatch(state: KitchenItemState.available),
      );
      expect(changesReplacedBy(later, [remove]), isEmpty);
    });
  });

  group('KIT-16 KIT-09 the stored form of a change', () {
    test('KIT-09 SAF-07 amount and brand survive storage; a typed brand '
        'stays typed text', () {
      for (final patch in [
        const KitchenPatch(state: KitchenItemState.out),
        const KitchenPatch(quantity: SetTo(KitchenAmount.little)),
        const KitchenPatch(quantity: SetTo(null), brand: SetTo(null)),
        const KitchenPatch(
          brand: SetTo(ReferenceBrand('fx_brand_contoh_a', 'Merek Contoh A')),
        ),
        const KitchenPatch(brand: SetTo(TypedBrand('Merek Rumah'))),
      ]) {
        final back = KitchenPatch.fromJson(
          jsonDecode(jsonEncode(patch.toJson())),
        );
        expect(back, patch);
      }
    });

    test('KIT-16 a stored change this app cannot read is refused, never '
        'half understood', () {
      for (final bad in [
        {'state': 'hampir_habis'},
        {'quantity': 'banyak sekali'},
        {
          'brand': {'brandId': 7},
        },
        {'category': 'snacks'},
      ]) {
        expect(() => KitchenPatch.fromJson(bad), throwsFormatException);
      }
    });

    test('KIT-09 SAF-07 on the wire a typed brand is `customName`, a listed '
        'one `brandId`, and a removal carries no fields', () {
      final typed = _change(
        1,
        const ReferenceIngredient('fx_kit_kecap_manis'),
        patch: const KitchenPatch(brand: SetTo(TypedBrand('Merek Rumah'))),
      ).toApi(ageMs: 5).toJson();
      expect(jsonDecode(jsonEncode(typed)), {
        'changeId': 'id-1',
        'ingredient': {'ingredientId': 'fx_kit_kecap_manis'},
        'operation': 'upsert',
        'ageMs': 5,
        'brand': {'customName': 'Merek Rumah'},
      });
      final listed = _change(
        2,
        const ReferenceIngredient('fx_kit_kecap_manis'),
        patch: const KitchenPatch(
          brand: SetTo(ReferenceBrand('fx_brand_contoh_a', 'Merek Contoh A')),
        ),
      ).toApi(ageMs: 0).toJson();
      expect(jsonDecode(jsonEncode(listed))['brand'], {
        'brandId': 'fx_brand_contoh_a',
      });
      final removal = _change(
        3,
        const ReferenceIngredient('fx_kit_tempe'),
        op: KitchenChangeOp.remove,
      ).toApi(ageMs: 0).toJson();
      expect(
        (jsonDecode(jsonEncode(removal)) as Map).keys,
        unorderedEquals(['changeId', 'ingredient', 'operation', 'ageMs']),
      );
    });

    test('DAT-08 a queued change never prints a name or a typed brand', () {
      final change = _change(
        1,
        const CustomIngredient('Sambal rahasia Nenek'),
        patch: const KitchenPatch(brand: SetTo(TypedBrand('Merek Rahasia'))),
      );
      for (final text in [
        '$change',
        '${change.patch}',
        '${change.ingredient}',
      ]) {
        expect(text, isNot(contains('Nenek')));
        expect(text, isNot(contains('Rahasia')));
      }
    });
  });

  group('KIT-16 the sync answer is decoded strictly', () {
    Map<String, Object?> answer({
      List<Map<String, Object?>> results = const [],
    }) => {
      'cursor': 'fx.acc.1',
      'full': false,
      'items': <Object?>[],
      'removedItemIds': <Object?>[],
      'results': results,
      'maxItems': 300,
      'referenceVersion': null,
    };
    Map<String, Object?> result(String id, String outcome, [String? code]) => {
      'changeId': id,
      'outcome': outcome,
      'itemId': null,
      'errorCode': code,
    };

    test('KIT-16 one result per change, in order', () {
      final decoded = decodeSyncAnswer(
        answer(
          results: [
            result('a', 'applied'),
            result('b', 'rejected', 'validation_failed'),
          ],
        ),
        sent: ['a', 'b'],
      );
      expect(decoded.results.map((r) => r.outcome), [
        KitchenSyncOutcome.applied,
        KitchenSyncOutcome.rejected,
      ]);
      expect(
        () => decodeSyncAnswer(
          answer(results: [result('b', 'applied'), result('a', 'applied')]),
          sent: ['a', 'b'],
        ),
        throwsFormatException,
      );
      expect(
        () => decodeSyncAnswer(answer(), sent: ['a']),
        throwsFormatException,
      );
    });

    test('KIT-16 a sync sent without a cursor must get the whole kitchen', () {
      expect(
        () => decodeSyncAnswer(answer(), sent: const [], cursorSent: false),
        throwsFormatException,
      );
      expect(
        decodeSyncAnswer(
          {...answer(), 'full': true},
          sent: const [],
          cursorSent: false,
        ).full,
        isTrue,
      );
    });

    test('KIT-16 an outcome this app does not know fails the whole answer '
        'closed', () {
      expect(
        () => decodeSyncAnswer(
          answer(results: [result('a', 'merged')]),
          sent: ['a'],
        ),
        throwsFormatException,
      );
      expect(
        () => decodeSyncAnswer(
          answer(results: [result('a', 'rejected')]),
          sent: ['a'],
        ),
        throwsFormatException,
      );
    });
  });

  group('KIT-05 KIT-08 KIT-09 text is checked before it is queued', () {
    test('KIT-05 hidden, control and private-use characters are refused', () {
      expect(textProblem('Sambal roa', maxLength: 60), isNull);
      expect(textProblem('  ', maxLength: 60), TextProblem.empty);
      expect(textProblem('a' * 61, maxLength: 60), TextProblem.tooLong);
      for (final hidden in ['\u200b', '\u202e', '\u0007', '\ue000', '\ud800']) {
        expect(
          textProblem('Sambal${hidden}roa', maxLength: 60),
          TextProblem.hiddenCharacters,
          reason: hidden.codeUnits.toString(),
        );
      }
    });
  });

  test('KIT-16 NFR-08 a sync for one account is never sent with another '
      "account's session", () async {
    final requests = <http.BaseRequest>[];
    final c = testContainer(
      handler: (r) async {
        requests.add(r);
        return http.Response('{}', 200);
      },
      tokens: InMemoryTokenStore(testTokens),
    );
    addTearDown(c.dispose);
    await c.read(sessionManagerProvider).load();
    final repo = c.read(kitchenRepositoryProvider);
    final result = await repo.sync(
      accountId: 'someone-else',
      cursor: null,
      changes: const [],
    );
    expect(result, isA<Err<KitchenSyncAnswer>>());
    expect((result as Err).failure, isA<NetworkFailure>());
    expect(requests, isEmpty);
    // The authenticating client refuses any request bound to another
    // account, and sends one bound to the signed-in account.
    final client = c.read(apiClientProvider).client;
    await expectLater(
      runAsAccount(
        'someone-else',
        () => client.get(Uri.parse('$testBaseUrl/x')),
      ),
      throwsA(isA<http.ClientException>()),
    );
    expect(requests, isEmpty);
    await runAsAccount(
      testTokens.accountId,
      () => client.get(Uri.parse('$testBaseUrl/x')),
    );
    expect(requests, hasLength(1));
  });
}
