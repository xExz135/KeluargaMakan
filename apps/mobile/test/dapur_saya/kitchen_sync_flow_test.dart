// KIT-16 (SRS 19.4, NFR-05, NFR-02) Dapur Saya offline queue and sync
// against the fake API: the queue survives a restart, belongs to one
// account, is retried with backoff, drops changes older than the server
// accepts, tells temporary from permanent rejections, sends and honours the
// cursor (full resync included), and lets the server's newer change win.
// TEST FIXTURE: not real safety or nutrition data. Names and contacts are
// invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/data/kitchen_state.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

const _emailB = 'budi.dapur@contoh.com';

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  Future<(KitchenPhone, String)> withTempe(
    WidgetTester tester, {
    Map<String, Object?> config = const {},
  }) async {
    late String id;
    final phone = await openKitchen(
      tester,
      server,
      config: config,
      seed: (a) => id =
          server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
              as String,
    );
    return (phone, id);
  }

  testWidgets('KIT-16 NFR-05 the queue survives a restart without internet '
      'and is sent with the same change ID once online', (tester) async {
    final (phone, id) = await withTempe(tester);
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    final stored = await phone.phone.db
        .select(phone.phone.db.kitchenOutbox)
        .get();
    expect(stored, hasLength(1));
    expect(stored.single.accountId, phone.account);
    await closeApp(tester);

    // The app starts again, still offline: the change is still shown.
    final container = await pumpPhone(
      tester,
      server: server,
      phone: phone.phone,
    );
    await tapNav(tester, 'Dapur Saya');
    expect(toggleLabel(tester, id), contains('Tempe, habis.'));
    expect(toggleLabel(tester, id), contains('Belum terkirim.'));
    expect(syncCaption(tester), 'Belum terkirim · 1 perubahan');
    expect(find.byKey(const Key('kitchen.offline')), findsOneWidget);

    server.intercept = null;
    await tapKeyed(tester, 'kitchen.sync.retry');
    expect(syncCaption(tester), 'Tersimpan');
    final sent = sentChanges(server).where((c) => c['state'] == 'out');
    expect(sent.map((c) => c['changeId']).toSet(), {stored.single.changeId});
    expect(server.kitchenOf(phone.account).single['state'], 'out');
    expect(
      await phone.phone.db.select(phone.phone.db.kitchenOutbox).get(),
      isEmpty,
    );
    expect(container.read(kitchenProvider), isA<KitchenLoaded>());
  });

  testWidgets('KIT-16 changes queued in an earlier run are sent at start, '
      'without opening Dapur Saya', (tester) async {
    final (phone, id) = await withTempe(tester);
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    await closeApp(tester);
    server.intercept = null;
    await pumpPhone(tester, server: server, phone: phone.phone);
    // Home is shown; the kitchen tab was never opened.
    await tester.pumpAndSettle();
    expect(server.kitchenOf(phone.account).single['state'], 'out');
  });

  testWidgets('KIT-16 ACC-13 sign-out removes the queue; the next account '
      'never sees or sends it', (tester) async {
    final (phone, id) = await withTempe(tester);
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    expect(
      await phone.phone.db.select(phone.phone.db.kitchenOutbox).get(),
      hasLength(1),
    );

    server.intercept = null;
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tapKeyed(tester, 'settings.signOut');
    await tapKeyed(tester, 'settings.signOut.confirm');
    expect(
      await phone.phone.db.select(phone.phone.db.kitchenOutbox).get(),
      isEmpty,
    );

    final before = server.kitchen.syncBodies.length;
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
    await tapNav(tester, 'Dapur Saya');
    expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);
    for (final body in server.kitchen.syncBodies.skip(before)) {
      expect(body['changes'], isEmpty);
    }
    // A never got the change: it was dropped with A's session.
    expect(server.kitchenOf(phone.account).single['state'], 'available');
  });

  testWidgets('KIT-16 SRS 19.4 retries back off exponentially (values from '
      'config) and the connection coming back sends at once', (tester) async {
    final (phone, id) = await withTempe(
      tester,
      config: {
        'sync.retryBaseMs': 1000,
        'sync.retryMaxMs': 4000,
        'sync.retryJitterPercent': 0,
      },
    );
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    final timers = phone.phone.sync.timers;
    for (var i = 0; i < 4; i++) {
      timers.fireAll();
      await tester.pumpAndSettle();
    }
    expect(
      [for (final t in timers.started) t.delay.inMilliseconds],
      [1000, 2000, 4000, 4000, 4000],
    );
    // Taps while waiting do not send extra requests; the backoff decides.
    final requests = server.requests.length;
    await tapKeyed(tester, 'kitchen.item.$id');
    expect(server.requests.length, requests);

    server.intercept = null;
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(syncCaption(tester), 'Tersimpan');
    expect(timers.pending, isEmpty);
    // The second tap went back to "Ada": latest wins.
    expect(server.kitchenOf(phone.account).single['state'], 'available');
  });

  testWidgets('KIT-16 the app resuming also sends the queue', (tester) async {
    final (phone, id) = await withTempe(tester);
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    server.intercept = null;
    phone.phone.sync.resume.resume();
    await tester.pumpAndSettle();
    expect(syncCaption(tester), 'Tersimpan');
  });

  testWidgets('KIT-16 a change older than the server accepts is dropped with '
      'a message, never sent', (tester) async {
    final (phone, id) = await withTempe(
      tester,
      config: {'kitchen.sync.maxChangeAgeHours': 24},
    );
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    // A day and an hour without internet.
    await tester.pump(const Duration(hours: 25));
    server.intercept = null;
    final sent = sentChanges(server).length;
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(
      find.text(
        '1 perubahan yang lebih lama dari 1 hari tidak terkirim dan dibatalkan.',
      ),
      findsOneWidget,
    );
    expect(sentChanges(server), hasLength(sent));
    expect(toggleLabel(tester, id), 'Tempe, ada. Ketuk untuk tandai habis.');
    expect(syncCaption(tester), 'Tersimpan');
    expect(
      await phone.phone.db.select(phone.phone.db.kitchenOutbox).get(),
      isEmpty,
    );
  });

  testWidgets('KIT-16 a change the server finds too old is rejected on its '
      'own and taken back; the rest still applies', (tester) async {
    late String tempe;
    late String tahu;
    final phone = await openKitchen(
      tester,
      server,
      seed: (a) {
        tempe =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String;
        tahu =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tahu')['id']!
                as String;
      },
    );
    server.kitchen.maxChangeAge = const Duration(minutes: 30);
    goOffline(server);
    await tapKeyed(tester, 'kitchen.item.$tempe');
    await tester.pump(const Duration(hours: 1));
    await tapKeyed(tester, 'kitchen.item.$tahu');
    server.intercept = null;
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(toggleLabel(tester, tempe), 'Tempe, ada. Ketuk untuk tandai habis.');
    expect(toggleLabel(tester, tahu), 'Tahu, habis. Ketuk untuk tandai ada.');
    expect(
      find.text(
        'Tempe: perubahan ini tidak bisa disimpan, jadi dikembalikan seperti '
        'semula.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('KIT-16 a temporary rejection keeps the change queued and '
      'sends it again later with the same change ID', (tester) async {
    final (phone, id) = await withTempe(tester);
    server.kitchen.syncRejections['r:fx_kit_tempe'] =
        'reference_data_unavailable';
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    expect(toggleLabel(tester, id), contains('Tempe, habis.'));
    expect(syncCaption(tester), 'Belum terkirim · 1 perubahan');
    expect(find.byKey(const Key('kitchen.sync.failed')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    server.kitchen.syncRejections.clear();
    phone.phone.sync.timers.fireAll();
    await tester.pumpAndSettle();
    expect(syncCaption(tester), 'Tersimpan');
    final ids = {
      for (final c in sentChanges(server))
        if (c['state'] == 'out') c['changeId'],
    };
    expect(ids, hasLength(1));
    expect(server.kitchenOf(phone.account).single['state'], 'out');
  });

  testWidgets('KIT-16 KIT-01 a full kitchen refuses a queued add: it goes '
      'back with the limit message', (tester) async {
    final phone = await openKitchen(tester, server);
    goOffline(server);
    await search(tester, 'tempe');
    await tapKeyed(tester, 'kitchen.search.add.fx_kit_tempe');
    await tapKeyed(tester, 'kitchen.search.close');
    // Meanwhile another phone filled the kitchen.
    server.kitchen.maxItems = 1;
    server.seedKitchenItem(phone.account, ingredientId: 'fx_kit_beras');
    server.intercept = null;
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(find.textContaining('Dapur Saya sudah penuh'), findsWidgets);
    expect(find.text('Tempe'), findsNothing);
    expect(find.text('Beras'), findsOneWidget);
  });

  testWidgets("KIT-16 the server's newer change wins over an older queued "
      'one, and the screen says so', (tester) async {
    final (phone, id) = await withTempe(tester);
    goOffline(server);
    await tester.tap(itemToggle(id)); // out, made now
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 5));
    // Another phone set an amount later.
    server.editKitchenItemElsewhere(phone.account, id, quantity: 'plenty');
    server.intercept = null;
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(find.text('Tempe diperbarui dari HP lain.'), findsOneWidget);
    expect(toggleLabel(tester, id), startsWith('Tempe, ada.'));
    expect(find.text('Banyak'), findsOneWidget);
    expect(server.kitchenOf(phone.account).single['state'], 'available');
  });

  testWidgets('KIT-16 a queued change newer than the other phone\'s wins', (
    tester,
  ) async {
    final (phone, id) = await withTempe(tester);
    server.editKitchenItemElsewhere(phone.account, id, quantity: 'some');
    await tester.pump(const Duration(minutes: 1));
    goOffline(server);
    await tester.tap(itemToggle(id));
    await tester.pumpAndSettle();
    server.intercept = null;
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(find.text('Tempe diperbarui dari HP lain.'), findsNothing);
    final item = server.kitchenOf(phone.account).single;
    expect(item['state'], 'out');
    // Per ingredient: the earlier amount from the other phone stays.
    expect(item['quantity'], 'some');
  });

  testWidgets('KIT-16 the cursor is kept and sent; an unknown cursor brings '
      'the whole kitchen (full resync) and replaces the copy', (tester) async {
    late String tempe;
    final phone = await openKitchen(
      tester,
      server,
      seed: (a) {
        tempe =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String;
        server.seedKitchenItem(a, ingredientId: 'fx_kit_tahu');
      },
    );
    expect(server.kitchen.syncBodies.first['cursor'], isNull);
    final kitchen = phone.container.read(kitchenProvider.notifier);
    await kitchen.refresh();
    await tester.pumpAndSettle();
    final cursor = server.kitchen.syncBodies.last['cursor'];
    expect(cursor, startsWith('fx.${phone.account}.'));
    final cached = await phone.phone.db
        .select(phone.phone.db.cachedKitchens)
        .getSingle();
    expect(cached.syncCursor, isNotNull);

    // Incremental: a change from another phone arrives.
    server.editKitchenItemElsewhere(phone.account, tempe, state: 'out');
    await kitchen.refresh();
    await tester.pumpAndSettle();
    expect(toggleLabel(tester, tempe), startsWith('Tempe, habis.'));

    // The server cannot continue from the cursor: the whole kitchen comes
    // back, and an item that went meanwhile is gone from the phone too.
    server.kitchen.acceptCursors = false;
    server
        .kitchenOf(phone.account)
        .removeWhere((i) => i['ingredientId'] == 'fx_kit_tahu');
    await kitchen.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Tahu'), findsNothing);
    expect(find.text('Tempe · Habis'), findsOneWidget);
    final rows = await phone.phone.db
        .select(phone.phone.db.cachedKitchenItems)
        .get();
    expect(rows.map((r) => r.ingredientId), ['fx_kit_tempe']);
  });

  testWidgets('KIT-16 a request the server refuses whole (400) is split, so '
      'only the change it cannot read is taken back', (tester) async {
    late String tempe;
    late String tahu;
    final phone = await openKitchen(
      tester,
      server,
      seed: (a) {
        tempe =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String;
        tahu =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tahu')['id']!
                as String;
      },
    );
    goOffline(server);
    await tapKeyed(tester, 'kitchen.item.$tempe');
    await tapKeyed(tester, 'kitchen.item.$tahu');
    // A stand-in for a change the schema refuses: anything with two
    // changes, and the tempe change alone.
    server.intercept = (r) {
      if (r.url.path != syncPath) return null;
      final body = r.body;
      final many = RegExp('changeId').allMatches(body).length > 1;
      return many || body.contains('fx_kit_tempe')
          ? FakeServer.problem('validation_failed', 400)
          : null;
    };
    phone.phone.sync.connectivity.goOnline();
    await tester.pumpAndSettle();
    expect(toggleLabel(tester, tempe), 'Tempe, ada. Ketuk untuk tandai habis.');
    expect(toggleLabel(tester, tahu), 'Tahu, habis. Ketuk untuk tandai ada.');
    expect(syncCaption(tester), 'Tersimpan');
  });

  testWidgets('KIT-16 an answer for the previous session is dropped and the '
      'queue goes with the session', (tester) async {
    final (phone, id) = await withTempe(tester);
    server.delays[syncPath] = const Duration(seconds: 2);
    await tester.tap(itemToggle(id));
    await tester.pump();
    server.intercept = (r) =>
        r.url.path == '/v1/auth/sign-out' ? http.Response('', 204) : null;
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tapKeyed(tester, 'settings.signOut');
    await tapKeyed(tester, 'settings.signOut.confirm');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(phone.container.read(kitchenProvider), isA<KitchenLoading>());
    expect(
      await phone.phone.db.select(phone.phone.db.cachedKitchenItems).get(),
      isEmpty,
    );
    expect(
      await phone.phone.db.select(phone.phone.db.kitchenOutbox).get(),
      isEmpty,
    );
  });

  testWidgets('KIT-16 L1 a tap made while a sync reads the clock is neither '
      'expired nor sent with the uptime as its age', (tester) async {
    final (phone, id) = await withTempe(
      tester,
      config: {'kitchen.sync.maxChangeAgeHours': 24},
    );
    final clock = phone.phone.sync.clock;
    // The phone has been on for 40 days.
    clock.setUptime(const Duration(days: 40));
    clock.hold = true;
    final kitchen = phone.container.read(kitchenProvider.notifier);
    final refresh = kitchen.refresh();
    await tester.pump();
    expect(clock.heldReads, 1, reason: 'the pass waits for the clock');
    // The tap's own clock read waits too: the change is still unstamped.
    await tester.tap(itemToggle(id));
    await tester.pump();
    expect(clock.heldReads, 2);
    clock.releaseNext(); // the pass goes on with an unstamped change
    await tester.pump();
    clock.hold = false;
    clock.releaseNext(); // the change gets its stamp
    await refresh;
    await tester.pumpAndSettle();

    expect(find.textContaining('tidak terkirim dan dibatalkan'), findsNothing);
    expect(server.kitchenOf(phone.account).single['state'], 'out');
    final sent = sentChanges(server).single;
    expect(sent['ageMs'], lessThan(60000));
    expect(syncCaption(tester), 'Tersimpan');
  });
}
