// Security review T-033 follow-ups: best-effort cache writes that never
// leak names (M1), release-safe error hooks, a server state that differs
// from the one sent (L3), kept Idempotency-Keys after a refresh or removal
// (L4), and the session epoch that stops a late save during sign-out.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/errors/error_hooks.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/data/kitchen_state.dart';
import 'package:keluargamakan/data/local_cache.dart';
import 'package:keluargamakan/data/models/kitchen.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/data/repositories/kitchen_repository.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

const _secret = 'Obat herbal Nenek Rahasia';

/// Makes every insert into [table] fail, as a full disk or a constraint
/// would. SQLite's error text then holds the statement's parameters.
Future<void> _failInserts(AppDatabase db, String table) => db.customStatement(
  'CREATE TRIGGER fail_$table BEFORE INSERT ON $table '
  "BEGIN SELECT RAISE(ABORT, 'disk full'); END",
);

KitchenList _listWith(String customName) => KitchenList(
  items: [
    KitchenEntry(
      id: 'k-1',
      ingredientId: null,
      displayName: null,
      customName: customName,
      category: kitchenCategoryOrder.last,
      state: KitchenItemState.available,
      isDefaultStaple: false,
      usageRank: null,
      changedAt: DateTime.utc(2026, 11, 15),
      createdAt: DateTime.utc(2026, 11, 15),
    ),
  ],
  maxItems: 300,
  referenceVersion: null,
  source: const FromNetwork(),
);

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  testWidgets('M1 DAT-08 a failing cache insert keeps the network result on '
      'screen, keeps "Tambah" usable and puts no name in any log', (
    tester,
  ) async {
    final logs = <String>[];
    final hookErrors = <Object>[];
    final originalPrint = debugPrint;
    final originalPlatform = PlatformDispatcher.instance.onError;
    final originalFlutter = FlutterError.onError;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    PlatformDispatcher.instance.onError = (e, _) {
      hookErrors.add(e);
      return true;
    };
    FlutterError.onError = (details) {
      hookErrors.add(details.exception);
      originalFlutter?.call(details);
    };
    try {
      final tokens = server.seedSignedIn(kitchenContact);
      server.seedKitchenItem(
        tokens.accountId,
        customName: _secret,
        category: 'leftovers',
      );
      final phone = TestPhone(tokens: InMemoryTokenStore(tokens));
      addTearDown(phone.db.close);
      await _failInserts(phone.db, 'cached_kitchen_items');
      await _failInserts(phone.db, 'cached_catalog_ingredients');
      await pumpPhone(tester, server: server, phone: phone);
      await tapNav(tester, 'Dapur Saya');

      // The list from the API, not the skeleton.
      expect(find.text(_secret), findsOneWidget);
      expect(find.byKey(const Key('kitchen.loading')), findsNothing);

      // Adding still works, and the row shows its state afterwards.
      await search(tester, 'tempe');
      await tapKeyed(tester, 'kitchen.search.add.fx_kit_tempe');
      expect(
        find.byKey(const Key('kitchen.search.state.fx_kit_tempe')),
        findsOneWidget,
      );

      expect(
        logs,
        contains('Cache write failed: saveKitchen (SqliteException)'),
      );
      for (final line in logs) {
        expect(line, isNot(contains('Nenek')), reason: line);
        expect(line, isNot(contains('Tempe')), reason: line);
      }
      expect(hookErrors, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      debugPrint = originalPrint;
      PlatformDispatcher.instance.onError = originalPlatform;
      FlutterError.onError = originalFlutter;
    }
  });

  test('M1 DAT-08 outside debug builds the error hooks log only the error '
      'type', () {
    final logs = <String>[];
    final originalPrint = debugPrint;
    final originalPlatform = PlatformDispatcher.instance.onError;
    final originalFlutter = FlutterError.onError;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    try {
      installErrorHooks(verbose: false);
      final error = StateError('INSERT … parameters: k-1, $_secret');
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: error,
          stack: StackTrace.current,
          informationCollector: () => [DiagnosticsNode.message(_secret)],
        ),
      );
      final handled = PlatformDispatcher.instance.onError!(
        error,
        StackTrace.current,
      );
      expect(handled, isTrue);
      expect(logs, [
        'Flutter error: StateError',
        'Unhandled error: StateError',
      ]);
    } finally {
      debugPrint = originalPrint;
      PlatformDispatcher.instance.onError = originalPlatform;
      FlutterError.onError = originalFlutter;
    }
  });

  test('M1 a failing cache read counts as no copy', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final cache = LocalCache(db, currentAccountId: () => 'acc-1');
    await cache.saveKitchen(_listWith('x'), accountId: 'acc-1', epoch: 0);
    await db.customStatement('DROP TABLE cached_kitchen_items');
    expect(await cache.kitchen(), isNull);
    expect(await cache.catalog(), isNull);
  });

  testWidgets('L3 KIT-02 a state this app does not know shows as Habis, '
      'never Ada, and is not sent back', (tester) async {
    late String id;
    final phone = await openKitchen(
      tester,
      server,
      seed: (a) => id =
          server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
              as String,
    );
    final sent = sentChanges(server).length;
    server.editKitchenItemElsewhere(phone.account, id, state: 'hampir_habis');
    await phone.container.read(kitchenProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(toggleLabel(tester, id), 'Tempe, habis. Ketuk untuk tandai ada.');
    expect(find.byKey(const Key('kitchen.item.pendingDot')), findsNothing);
    expect(sentChanges(server), hasLength(sent));
  });

  testWidgets('L4 KIT-16 a sync whose answer is lost is sent again with the '
      'same change IDs, and the server applies it once', (tester) async {
    late String id;
    final phone = await openKitchen(
      tester,
      server,
      seed: (a) => id =
          server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
              as String,
    );
    server.kitchen.loseNextSyncAnswer = true;
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    // The server applied it, but the phone never heard.
    expect(server.kitchenOf(phone.account).single['state'], 'out');
    expect(syncCaption(tester), 'Belum terkirim · 1 perubahan');

    // Another phone changes it back in the meantime.
    await tester.pump(const Duration(seconds: 1));
    server.editKitchenItemElsewhere(phone.account, id, state: 'available');
    phone.phone.sync.timers.fireAll();
    await tester.pumpAndSettle();

    final ids = [for (final c in sentChanges(server)) c['changeId']];
    expect(ids, hasLength(2));
    expect(ids.toSet(), hasLength(1));
    // The replay returned the first result and was not applied again: the
    // other phone's later change stays.
    expect(server.kitchenOf(phone.account).single['state'], 'available');
    expect(toggleLabel(tester, id), 'Tempe, ada. Ketuk untuk tandai habis.');
    expect(syncCaption(tester), 'Tersimpan');
  });

  test('ACC-13 a save that started before sign-out began is dropped, even '
      'while the account is still signed in', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    var epoch = 1;
    var ending = false;
    final cache = LocalCache(
      db,
      currentAccountId: () => 'acc-1',
      currentEpoch: () => epoch,
      sessionEnding: () => ending,
    );
    final startedUnder = cache.epoch;
    // Sign-out begins: the wipe runs, the tokens are not cleared yet.
    epoch++;
    ending = true;
    await db.clearUserData();
    await cache.saveKitchen(
      _listWith(_secret),
      accountId: 'acc-1',
      epoch: startedUnder,
    );
    await cache.saveProfiles(const []);
    expect(await db.select(db.cachedKitchenItems).get(), isEmpty);
    expect(await db.select(db.cachedKitchens).get(), isEmpty);

    // Not ending, but still the old epoch: dropped too.
    ending = false;
    await cache.saveKitchen(
      _listWith(_secret),
      accountId: 'acc-1',
      epoch: startedUnder,
    );
    expect(await db.select(db.cachedKitchenItems).get(), isEmpty);
    // The current epoch is stored.
    await cache.saveKitchen(
      _listWith(_secret),
      accountId: 'acc-1',
      epoch: cache.epoch,
    );
    expect(await db.select(db.cachedKitchenItems).get(), hasLength(1));
  });

  test('ACC-13 the session manager moves the epoch and flags the end before '
      'the wipe runs', () async {
    final c = testContainer(
      handler: (_) async => http.Response('', 204),
      tokens: InMemoryTokenStore(testTokens),
    );
    addTearDown(c.dispose);
    final session = c.read(sessionManagerProvider);
    await session.load();
    final before = session.epoch;
    final seen = <(int, bool, bool)>[];
    session.addEndHandler((_) async {
      seen.add((session.epoch, session.isEnding, session.isSignedIn));
    });
    final repo = c.read(kitchenRepositoryProvider);
    final stamped = repo.sessionEpoch;
    await session.end(SessionEndReason.signedOut);
    expect(seen.first.$1, greaterThan(before));
    expect(seen.first.$2, isTrue);
    expect(seen.first.$3, isTrue, reason: 'tokens are cleared after');
    expect(session.isEnding, isFalse);
    expect(stamped, before);
  });
}
