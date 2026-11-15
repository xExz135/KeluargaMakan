// Security review T-027 M1 and T-026b M2 for Dapur Saya: the kitchen in
// memory and the phone's copy belong to one account. After A signs out and
// B signs in on the same run, B never sees A's kitchen, on screen, in
// memory or in the phone's cache. Also DAT-08 and KIT-04: no custom names
// or search queries in the logs, and queries never in a URL.
// TEST FIXTURE: not real safety or nutrition data. Names, contacts and
// ingredients are invented.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/data/kitchen_state.dart';
import 'package:keluargamakan/data/local_cache.dart';
import 'package:keluargamakan/data/models/kitchen.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/features/auth/welcome_screen.dart';
import 'package:keluargamakan/features/masak_apa_hari_ini/home_screen.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

const _secretA = 'Sambal rahasia keluarga A';
const _emailB = 'budi.dapur@contoh.com';

String _kitchenText(KitchenState state) => switch (state) {
  KitchenLoaded(:final list) => [
    for (final i in list.items) '${i.customName} ${i.ingredientId}',
  ].join(' '),
  _ => '',
};

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  Future<void> signOut(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tapKeyed(tester, 'settings.signOut');
    await tapKeyed(tester, 'settings.signOut.confirm');
  }

  Future<void> signInB(WidgetTester tester) async {
    await tapKeyed(tester, 'welcome.haveAccount');
    await tapKeyed(tester, 'signIn.email');
    await tester.enterText(find.byKey(const Key('contact.field')), _emailB);
    await tester.pumpAndSettle();
    await tapKeyed(tester, 'contact.send');
    await tester.enterText(find.byKey(const Key('code.field')), fixtureCode);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name.field')), 'Budi');
    await tester.pumpAndSettle();
    await tapKeyed(tester, 'name.continue');
  }

  testWidgets('ACC-13 KIT-01 after A signs out and B signs in on the same '
      'run, Dapur Saya shows none of A\'s kitchen', (tester) async {
    final a = await openKitchen(
      tester,
      server,
      seed: (account) => server
        ..seedKitchenItem(
          account,
          ingredientId: 'fx_kit_kluwek',
          category: 'spices_aromatics',
        )
        ..seedKitchenItem(
          account,
          customName: _secretA,
          category: 'sauces_condiments',
        ),
    );
    expect(find.text(_secretA), findsOneWidget);
    final db = a.phone.db;
    expect(await db.select(db.cachedKitchenItems).get(), hasLength(2));

    final states = <KitchenState>[];
    await signOut(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(a.container.read(kitchenProvider), isA<KitchenLoading>());
    expect(await db.select(db.cachedKitchenItems).get(), isEmpty);
    a.container.listen(
      kitchenProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );

    // B first without internet for the kitchen: no copy from A to fall
    // back on, so an error, never A's items.
    server.intercept = (r) => r.url.path.startsWith('/v1/household/kitchen')
        ? throw http.ClientException('offline')
        : null;
    await signInB(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tapNav(tester, 'Dapur Saya');
    expect(find.byKey(const Key('kitchen.error')), findsOneWidget);
    for (final text in visibleTexts(tester)) {
      expect(text, isNot(contains(_secretA)));
      expect(text, isNot(contains('Kluwek')));
    }

    // Online: B's own (empty) kitchen.
    server.intercept = null;
    await tapKeyed(tester, 'kitchen.retry');
    expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);
    for (final text in visibleTexts(tester)) {
      expect(text, isNot(contains(_secretA)));
    }
    for (final state in states) {
      expect(_kitchenText(state), isNot(contains(_secretA)));
      expect(_kitchenText(state), isNot(contains('fx_kit_kluwek')));
    }
    final rows = await db.select(db.cachedKitchenItems).get();
    expect(rows.map((r) => r.customName), isNot(contains(_secretA)));
    // The public catalog stays on the phone across accounts.
    expect(await db.select(db.cachedCatalogIngredients).get(), isNotEmpty);
  });

  test('ACC-13 KIT-01 an answer for A that arrives after B signed in is never '
      'stored as B\'s kitchen', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    String? current = 'acc-1';
    final cache = LocalCache(db, currentAccountId: () => current);
    final list = KitchenList(
      items: [
        KitchenEntry(
          id: 'k-1',
          ingredientId: null,
          displayName: null,
          customName: _secretA,
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
    current = 'acc-2';
    await cache.saveKitchen(list, accountId: 'acc-1', epoch: 0);
    expect(await db.select(db.cachedKitchenItems).get(), isEmpty);
    expect(await cache.kitchen(), isNull);

    // The owner itself is stored and read back; another account is not.
    await cache.saveKitchen(list, accountId: 'acc-2', epoch: 0);
    expect((await cache.kitchen())!.items.single.customName, _secretA);
    current = 'acc-3';
    expect(await cache.kitchen(), isNull);
  });

  testWidgets('ACC-13 a toggle answered after the session ended changes '
      'nothing for the next account', (tester) async {
    late String id;
    final a = await openKitchen(
      tester,
      server,
      seed: (account) => id =
          server.seedKitchenItem(account, ingredientId: 'fx_kit_tempe')['id']!
              as String,
    );
    server.delays['/v1/household/kitchen/items/$id'] = const Duration(
      seconds: 2,
    );
    await tester.tap(itemToggle(id));
    await tester.pump();
    // The session ends while the change is on its way.
    await a.container
        .read(sessionManagerProvider)
        .end(SessionEndReason.expired);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(a.container.read(kitchenProvider), isA<KitchenLoading>());
    expect(
      await a.phone.db.select(a.phone.db.cachedKitchenItems).get(),
      isEmpty,
    );
  });

  testWidgets('ACC-13 KIT-02 a toggle that meets an ended session (401, '
      'refresh refused) signs out, clears the copy and sends nothing more', (
    tester,
  ) async {
    late String id;
    final a = await openKitchen(
      tester,
      server,
      seed: (account) => id =
          server.seedKitchenItem(account, ingredientId: 'fx_kit_tempe')['id']!
              as String,
    );
    server.intercept = (r) => switch (r.url.path) {
      '/v1/auth/refresh' => FakeServer.problem('refresh_token_invalid', 401),
      final p when p.startsWith('/v1/household/kitchen') => FakeServer.problem(
        'access_token_expired',
        401,
      ),
      _ => null,
    };
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    expect(find.text('Silakan masuk lagi'), findsOneWidget);
    expect(await a.phone.tokens.read(), isNull);
    expect(a.container.read(kitchenProvider), isA<KitchenLoading>());
    expect(
      await a.phone.db.select(a.phone.db.cachedKitchenItems).get(),
      isEmpty,
    );
    final patches = requestsTo(server, 'PATCH', id);
    // The first try and its one retry after the refresh attempt, no more.
    expect(patches.length, lessThanOrEqualTo(2));
  });

  testWidgets('DAT-08 KIT-04 no custom names or search queries reach the logs '
      'or a URL, even on failures', (tester) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    try {
      await openKitchen(tester, server);
      // Answers this app cannot read (logged as decode failures).
      server.intercept = (r) => r.method == 'POST'
          ? FakeServer.json({
              'items': 7,
            }, r.url.path.endsWith('search') ? 200 : 201)
          : null;
      await search(tester, 'kueri-rahasia');
      expect(find.byKey(const Key('kitchen.search.error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('kitchen.search.close')));
      await tester.pumpAndSettle();
      await tapKeyed(tester, 'kitchen.fab');
      await tapKeyed(tester, 'kitchen.menu.custom');
      await tester.enterText(
        find.byKey(const Key('kitchen.custom.name')),
        'Bumbu rahasia nenek',
      );
      await tapKeyed(tester, 'kitchen.custom.category.leftovers');
      await tapKeyed(tester, 'kitchen.custom.add');
      expect(find.byKey(const Key('kitchen.custom.error')), findsOneWidget);

      expect(logs, isNotEmpty, reason: 'the decode failures are logged');
      for (final line in logs) {
        for (final secret in ['kueri', 'rahasia', 'nenek', 'Bumbu']) {
          expect(line, isNot(contains(secret)), reason: line);
        }
      }
      for (final r in server.requests) {
        expect(r.url.toString(), isNot(contains('kueri')));
        expect(r.url.toString(), isNot(contains('rahasia')));
      }
      final searches = requestsTo(server, 'POST', '/ingredients/search');
      expect(searches.single.body, contains('kueri-rahasia'));
    } finally {
      debugPrint = original;
    }
  });

  test('DAT-08 kitchen models never print names', () {
    final entry = KitchenEntry(
      id: 'k-1',
      ingredientId: null,
      displayName: const BilingualName(id: 'Rahasia', en: 'Secret'),
      customName: _secretA,
      category: kitchenCategoryOrder.first,
      state: KitchenItemState.out,
      isDefaultStaple: false,
      usageRank: null,
      changedAt: DateTime.utc(2026, 11, 15),
      createdAt: DateTime.utc(2026, 11, 15),
    );
    for (final text in [
      '$entry',
      '${entry.key}',
      '${entry.displayName}',
      '${KitchenNotice(entry, const NetworkFailure())}',
    ]) {
      expect(text, isNot(contains('Sambal')));
      expect(text, isNot(contains('Rahasia')));
    }
  });

  testWidgets('NFR-08 a session token is never sent for another account\'s '
      'kitchen after sign-in on the same phone', (tester) async {
    // A's phone copy exists; B signs in on a fresh run with A's leftovers in
    // the database (a failed wipe): B's reads never use them.
    final a = await openKitchen(
      tester,
      server,
      seed: (account) => server.seedKitchenItem(
        account,
        customName: _secretA,
        category: 'leftovers',
      ),
    );
    await closeApp(tester);
    final tokensB = server.seedSignedIn('+6281200000099');
    final phoneB = TestPhone(
      tokens: InMemoryTokenStore(tokensB),
      store: a.phone.store,
    );
    addTearDown(phoneB.db.close);
    // Copy A's rows into B's database without the owner check, as a failed
    // wipe would leave them.
    final rows = await a.phone.db.select(a.phone.db.cachedKitchenItems).get();
    final metas = await a.phone.db.select(a.phone.db.cachedKitchens).get();
    final owner = await a.phone.db.select(a.phone.db.settings).get();
    expect(rows, isNotEmpty);
    await phoneB.db.batch((b) {
      b.insertAll(phoneB.db.cachedKitchenItems, rows);
      b.insertAll(phoneB.db.cachedKitchens, metas);
      b.insertAll(phoneB.db.settings, owner);
    });
    server.intercept = (r) => r.url.path.startsWith('/v1/household/kitchen')
        ? throw http.ClientException('offline')
        : null;
    final container = await pumpPhone(tester, server: server, phone: phoneB);
    await tapNav(tester, 'Dapur Saya');
    expect(find.text(_secretA), findsNothing);
    expect(container.read(kitchenProvider), isA<KitchenLoadFailed>());
  });
}
