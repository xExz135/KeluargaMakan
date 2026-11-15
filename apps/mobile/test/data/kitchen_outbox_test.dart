// KIT-16 ACC-13 the kitchen outbox on the phone: bound to one account,
// written only under the session epoch it was made in, never while a
// session ends, collapsed in one transaction, and unreadable rows dropped.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/data/local_cache.dart';
import 'package:keluargamakan/data/models/kitchen.dart';
import 'package:keluargamakan/sync/device_clock.dart';
import 'package:keluargamakan/sync/kitchen_change.dart';

import '../helpers/api_fixtures.dart';

QueuedChange _change(String id, {String name = 'Sambal rahasia Ibu'}) =>
    QueuedChange(
      seq: 0,
      changeId: id,
      ingredient: CustomIngredient(name),
      op: KitchenChangeOp.upsert,
      patch: const KitchenPatch(state: KitchenItemState.out),
      stamp: const ClockReading(
        timeline: 'boot:1',
        elapsedMs: 100,
        wallMs: 1763190000000,
      ),
    );

void main() {
  late AppDatabase db;
  String? account = 'acc-1';
  var epoch = 1;
  var ending = false;
  late LocalCache cache;

  setUp(() {
    db = memoryDatabase();
    account = 'acc-1';
    epoch = 1;
    ending = false;
    cache = LocalCache(
      db,
      currentAccountId: () => account,
      currentEpoch: () => epoch,
      sessionEnding: () => ending,
    );
  });
  tearDown(() => db.close());

  test('KIT-16 a queued change is stored for its account and read back in '
      'order', () async {
    expect(
      await cache.queueKitchenChange(
        _change('c-1'),
        replacing: const {},
        accountId: 'acc-1',
        epoch: 1,
      ),
      isTrue,
    );
    await cache.queueKitchenChange(
      _change('c-2', name: 'Kerupuk'),
      replacing: const {},
      accountId: 'acc-1',
      epoch: 1,
    );
    final queue = await cache.outbox();
    expect(queue!.map((c) => c.changeId), ['c-1', 'c-2']);
    expect(queue.first.patch, const KitchenPatch(state: KitchenItemState.out));
    expect(queue.first.stamp.timeline, 'boot:1');
    expect(await cache.outboxCount('acc-1'), 2);
  });

  test('KIT-16 collapsing drops the replaced rows in the same write', () async {
    await cache.queueKitchenChange(
      _change('c-1'),
      replacing: const {},
      accountId: 'acc-1',
      epoch: 1,
    );
    await cache.queueKitchenChange(
      _change('c-2'),
      replacing: {'c-1'},
      accountId: 'acc-1',
      epoch: 1,
    );
    expect((await cache.outbox())!.map((c) => c.changeId), ['c-2']);
    await cache.unqueueKitchenChanges(['c-2']);
    expect(await cache.outbox(), isEmpty);
  });

  test('KIT-16 ACC-13 another account never reads the queue, and its first '
      'write removes it', () async {
    await cache.queueKitchenChange(
      _change('c-1'),
      replacing: const {},
      accountId: 'acc-1',
      epoch: 1,
    );
    account = 'acc-2';
    expect(await cache.outbox(), isNull);
    // A late write for A after B signed in is refused.
    expect(
      await cache.queueKitchenChange(
        _change('c-2'),
        replacing: const {},
        accountId: 'acc-1',
        epoch: 1,
      ),
      isFalse,
    );
    await cache.queueKitchenChange(
      _change('c-3', name: 'Tempe'),
      replacing: const {},
      accountId: 'acc-2',
      epoch: 1,
    );
    final rows = await db.select(db.kitchenOutbox).get();
    expect(rows.map((r) => r.accountId), ['acc-2']);
    expect(
      rows.map((r) => r.customName),
      isNot(contains('Sambal rahasia Ibu')),
    );
  });

  test('KIT-16 ACC-13 a write from an older session epoch, or while the '
      'session ends, is dropped', () async {
    epoch = 2;
    expect(
      await cache.queueKitchenChange(
        _change('c-1'),
        replacing: const {},
        accountId: 'acc-1',
        epoch: 1,
      ),
      isFalse,
    );
    ending = true;
    expect(
      await cache.queueKitchenChange(
        _change('c-2'),
        replacing: const {},
        accountId: 'acc-1',
        epoch: 2,
      ),
      isFalse,
    );
    expect(await db.select(db.kitchenOutbox).get(), isEmpty);
  });

  test(
    'KIT-16 a row this app version cannot read is dropped, never sent',
    () async {
      await cache.queueKitchenChange(
        _change('c-1'),
        replacing: const {},
        accountId: 'acc-1',
        epoch: 1,
      );
      await db
          .into(db.kitchenOutbox)
          .insert(
            KitchenOutboxCompanion.insert(
              accountId: 'acc-1',
              changeId: 'c-bad',
              ingredientId: const Value('fx_kit_tempe'),
              operation: 'merge',
              patch: '{}',
              timeline: 'boot:1',
              elapsedMs: 0,
              wallMs: 0,
            ),
          );
      expect((await cache.outbox())!.map((c) => c.changeId), ['c-1']);
      expect((await db.select(db.kitchenOutbox).get()).map((r) => r.changeId), [
        'c-1',
      ]);
    },
  );
}
