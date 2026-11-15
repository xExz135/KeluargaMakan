// KIT-01 to KIT-07 and KIT-16 Dapur Saya flows against the fake API:
// one-tap toggles from local state through the sync, search and add,
// custom items, default staples, the catalog download with ETag / 304,
// reference data unavailable and the item limit.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/data/kitchen_state.dart';
import 'package:keluargamakan/data/models/kitchen.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

const _catalog = '/v1/reference/ingredients';
const _search = '/v1/reference/ingredients/search';

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  group('KIT-02 one tap toggles from local state', () {
    testWidgets('KIT-02 NFR-02 KIT-16 the tap shows the new state before the '
        'server answers, then the sync confirms it', (tester) async {
      late String id;
      await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String,
      );
      expect(toggleLabel(tester, id), 'Tempe, ada. Ketuk untuk tandai habis.');
      expect(syncCaption(tester), 'Tersimpan');
      server.delays[syncPath] = const Duration(seconds: 2);

      await tester.tap(itemToggle(id));
      await tester.pump();
      // On screen at once, marked as not sent yet.
      expect(toggleLabel(tester, id), contains('Tempe, habis.'));
      expect(toggleLabel(tester, id), contains('Belum terkirim.'));
      expect(find.text('Tempe · Habis'), findsOneWidget);
      expect(syncCaption(tester), 'Mengirim perubahan…');

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(toggleLabel(tester, id), 'Tempe, habis. Ketuk untuk tandai ada.');
      expect(syncCaption(tester), 'Tersimpan');
      expect(sentChanges(server).map(withoutIdAndAge), [
        {
          'ingredient': {'ingredientId': 'fx_kit_tempe'},
          'operation': 'upsert',
          'state': 'out',
        },
      ]);
      expect(
        server.kitchenOf(server.accountFor(kitchenContact)!).single['state'],
        'out',
      );
    });

    testWidgets('KIT-02 KIT-16 taps while a sync is on its way end on the '
        'last tap, one sync at a time, collapsed per ingredient', (
      tester,
    ) async {
      late String id;
      await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String,
      );
      server.delays[syncPath] = const Duration(milliseconds: 500);
      final before = server.kitchen.syncBodies.length;
      for (var i = 0; i < 3; i++) {
        await tester.tap(itemToggle(id));
        await tester.pump();
      }
      expect(toggleLabel(tester, id), contains('Tempe, habis.'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The first tap went out; the second and third were collapsed into
      // one change while it was on its way.
      final states = [for (final c in sentChanges(server)) c['state']];
      expect(states, ['out', 'out']);
      expect(server.kitchen.syncBodies.length - before, 2);
      expect(toggleLabel(tester, id), 'Tempe, habis. Ketuk untuk tandai ada.');
    });

    testWidgets('KIT-16 a change the server refuses for good goes back with '
        'a clear message', (tester) async {
      late String id;
      await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String,
      );
      server.kitchen.syncRejections['r:fx_kit_tempe'] = 'validation_failed';
      await tester.tap(itemToggle(id));
      await tester.pumpAndSettle();
      expect(toggleLabel(tester, id), 'Tempe, ada. Ketuk untuk tandai habis.');
      expect(
        find.text(
          'Tempe: perubahan ini tidak bisa disimpan, jadi dikembalikan seperti '
          'semula.',
        ),
        findsOneWidget,
      );
      expect(syncCaption(tester), 'Tersimpan');
    });

    testWidgets('KIT-16 NFR-02 without internet the tap stays, is queued, '
        'says "Belum terkirim" and is sent when the connection returns', (
      tester,
    ) async {
      late String id;
      final phone = await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String,
      );
      goOffline(server);
      await tester.tap(itemToggle(id));
      await tester.pumpAndSettle();
      expect(toggleLabel(tester, id), contains('Tempe, habis.'));
      expect(toggleLabel(tester, id), contains('Belum terkirim.'));
      expect(syncCaption(tester), 'Belum terkirim · 1 perubahan');
      expect(find.byKey(const Key('kitchen.offline')), findsOneWidget);
      expect(find.byKey(const Key('kitchen.sync.retry')), findsOneWidget);
      // Nothing reverted and no "needs internet" message.
      expect(find.byType(SnackBar), findsNothing);
      expect(phone.phone.sync.timers.pending, hasLength(1));

      server.intercept = null;
      phone.phone.sync.connectivity.goOnline();
      await tester.pumpAndSettle();
      expect(syncCaption(tester), 'Tersimpan');
      expect(find.byKey(const Key('kitchen.offline')), findsNothing);
      expect(toggleLabel(tester, id), 'Tempe, habis. Ketuk untuk tandai ada.');
      expect(server.kitchenOf(phone.account).single['state'], 'out');
    });

    testWidgets('KIT-16 an item removed on another phone disappears at the '
        'next sync', (tester) async {
      late String id;
      final phone = await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String,
      );
      server.removeKitchenItemElsewhere(phone.account, id);
      await phone.container.read(kitchenProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(itemToggle(id), findsNothing);
    });
  });

  testWidgets('KIT-03 KIT-06 items appear in the nine categories in order, '
      'empty ones hidden; ranked items first, then "Lainnya" A to Z', (
    tester,
  ) async {
    await openKitchen(
      tester,
      server,
      config: {'kitchen.frequentCount': 1},
      seed: (a) {
        server
          ..seedKitchenItem(a, ingredientId: 'fx_kit_tempe')
          ..seedKitchenItem(a, ingredientId: 'fx_kit_tahu', usageRank: 1)
          ..seedKitchenItem(a, ingredientId: 'fx_kit_beras')
          ..seedKitchenItem(a, ingredientId: 'fx_kit_kemangi')
          ..seedKitchenItem(a, ingredientId: 'fx_kit_bawang_merah');
      },
    );
    final headers = [
      for (final e
          in find
              .byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.endsWith('.header'),
              )
              .evaluate())
        (e.widget.key! as ValueKey<String>).value,
    ];
    expect(headers, [
      'kitchen.category.protein.header',
      'kitchen.category.spices_aromatics.header',
      'kitchen.category.staples.header',
    ]);
    expect(find.text('Bumbu dan rempah'), findsOneWidget);
    expect(find.text('Sayuran'), findsNothing);
    // Protein: Tahu (rank 1) first, then "Lainnya", then Tempe.
    final tahu = tester.getTopLeft(find.text('Tahu'));
    final other = tester.getTopLeft(find.text('Lainnya'));
    final tempe = tester.getTopLeft(find.text('Tempe'));
    expect(tahu.dy, lessThan(other.dy));
    expect(other.dy, lessThan(tempe.dy));
    // Spices without ranks: A to Z, no divider.
    final bawang = tester.getTopLeft(find.text('Bawang merah'));
    final kemangi = tester.getTopLeft(find.text('Kemangi'));
    expect(
      bawang.dy < kemangi.dy ||
          (bawang.dy == kemangi.dy && bawang.dx < kemangi.dx),
      isTrue,
    );
    expect(find.text('Lainnya'), findsOneWidget);
    expect(find.text('2 ada · 0 habis'), findsNWidgets(2));
  });

  testWidgets('KIT-03 the filter shows only out items, with its own empty '
      'message', (tester) async {
    await openKitchen(
      tester,
      server,
      seed: (a) => server
        ..seedKitchenItem(a, ingredientId: 'fx_kit_tempe')
        ..seedKitchenItem(a, ingredientId: 'fx_kit_beras', state: 'out'),
    );
    await tapKeyed(tester, 'kitchen.filter.out');
    expect(find.text('Beras · Habis'), findsOneWidget);
    expect(find.text('Tempe'), findsNothing);
    await tapKeyed(tester, 'kitchen.filter.available');
    expect(find.text('Tempe'), findsOneWidget);
    expect(find.text('Beras · Habis'), findsNothing);
  });

  testWidgets('KIT-03 a category collapses and says so to TalkBack', (
    tester,
  ) async {
    await openKitchen(
      tester,
      server,
      seed: (a) => server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe'),
    );
    final header = find.byKey(const Key('kitchen.category.protein.header'));
    expect(
      tester.getSemantics(header).label,
      'Protein, 1 ada · 0 habis, dibentangkan',
    );
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(find.text('Tempe'), findsNothing);
    expect(
      tester.getSemantics(header).label,
      'Protein, 1 ada · 0 habis, diciutkan',
    );
  });

  testWidgets('KIT-04 KIT-02 KIT-01 KIT-16 search, add, toggle in the '
      'sheet, then remove with Undo', (tester) async {
    await openKitchen(tester, server);
    expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);

    await search(tester, 'selasih');
    // The local name that matched is shown next to the name.
    expect(find.text('Kemangi · selasih'), findsOneWidget);
    expect(find.text('Bumbu dan rempah'), findsOneWidget);
    await tapKeyed(tester, 'kitchen.search.add.fx_kit_kemangi');
    expect(withoutIdAndAge(sentChanges(server).single), {
      'ingredient': {'ingredientId': 'fx_kit_kemangi'},
      'operation': 'upsert',
      'category': 'spices_aromatics',
      'state': 'available',
    });
    // The sheet stays open and the row shows the state; a tap toggles.
    final state = find.byKey(const Key('kitchen.search.state.fx_kit_kemangi'));
    expect(state, findsOneWidget);
    expect(
      tester.getSemantics(state).label,
      'Kemangi, ada. Ketuk untuk tandai habis.',
    );
    await tester.tap(state);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(state).label,
      'Kemangi, habis. Ketuk untuk tandai ada.',
    );
    await tapKeyed(tester, 'kitchen.search.close');

    final account = server.accountFor(kitchenContact)!;
    final id = server.kitchenOf(account).single['id']! as String;
    expect(find.text('Kemangi · Habis'), findsOneWidget);

    // K4: long press, remove, Undo.
    await tester.longPress(itemToggle(id));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kitchen.sheet')), findsOneWidget);
    await tapKeyed(tester, 'kitchen.sheet.remove');
    expect(withoutIdAndAge(sentChanges(server).last), {
      'ingredient': {'ingredientId': 'fx_kit_kemangi'},
      'operation': 'remove',
    });
    expect(itemToggle(id), findsNothing);
    expect(server.kitchenOf(account), isEmpty);
    expect(find.text('Kemangi dihapus dari Dapur Saya.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('kitchen.removed.undo')));
    await tester.pumpAndSettle();
    expect(find.text('Kemangi · Habis'), findsOneWidget);
    // Undo puts it back as it was: category, state, amount and brand.
    expect(withoutIdAndAge(sentChanges(server).last), {
      'ingredient': {'ingredientId': 'fx_kit_kemangi'},
      'operation': 'upsert',
      'category': 'spices_aromatics',
      'state': 'out',
      'quantity': null,
      'brand': null,
    });
    expect(server.kitchenOf(account).single['state'], 'out');
    expectNoSafetyVerdict(tester);
  });

  testWidgets('KIT-04 an ingredient without a category asks for one', (
    tester,
  ) async {
    await openKitchen(tester, server);
    await search(tester, 'kluwek');
    await tapKeyed(tester, 'kitchen.search.add.fx_kit_kluwek');
    expect(find.text('Masuk kategori apa?'), findsOneWidget);
    await tapKeyed(tester, 'kitchen.category.pick.spices_aromatics');
    expect(withoutIdAndAge(sentChanges(server).single), {
      'ingredient': {'ingredientId': 'fx_kit_kluwek'},
      'operation': 'upsert',
      'category': 'spices_aromatics',
      'state': 'available',
    });
  });

  testWidgets('KIT-05 SAF-09 a custom item is added with its category, is '
      'flagged "Belum dikenal", and explains Cek label', (tester) async {
    await openKitchen(tester, server);
    await search(tester, 'sambal roa');
    expect(find.text('Tidak ada "sambal roa" di daftar kami.'), findsOneWidget);
    await tapKeyed(tester, 'kitchen.search.addCustom');

    // K3 prefilled from the search, with the info note.
    expect(find.text('sambal roa'), findsOneWidget);
    expect(
      find.text(
        'Bahan ini belum dikenal Cek Aman. Untuk anggota yang punya aturan '
        'wajib, resep yang memakai bahan ini akan diberi tanda Cek label.',
      ),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(
      find.byKey(const Key('kitchen.custom.name')),
    );
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.autocorrect, isFalse);

    // A category is required.
    await tapKeyed(tester, 'kitchen.custom.add');
    expect(
      find.byKey(const Key('kitchen.custom.categoryMissing')),
      findsOneWidget,
    );
    expect(sentChanges(server), isEmpty);
    await tapKeyed(tester, 'kitchen.custom.category.sauces_condiments');
    await tapKeyed(tester, 'kitchen.custom.add');

    expect(withoutIdAndAge(sentChanges(server).single), {
      'ingredient': {'customName': 'sambal roa'},
      'operation': 'upsert',
      'category': 'sauces_condiments',
      'state': 'available',
    });
    // Back on K1, flagged.
    final account = server.accountFor(kitchenContact)!;
    final id = server.kitchenOf(account).single['id']! as String;
    expect(find.text('Belum dikenal'), findsOneWidget);
    expect(
      toggleLabel(tester, id),
      'sambal roa, ada. Ketuk untuk tandai habis. Bahan buatan sendiri. '
      'Cek Aman akan meminta cek label.',
    );
    // K4 repeats the note.
    await tester.longPress(itemToggle(id));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kitchen.sheet.customNote')), findsOneWidget);
    expectNoSafetyVerdict(tester);
  });

  testWidgets('KIT-05 a name with hidden characters shows the field error, '
      'keeps the input and queues nothing', (tester) async {
    await openKitchen(tester, server);
    await tapKeyed(tester, 'kitchen.fab');
    await tapKeyed(tester, 'kitchen.menu.custom');
    await tester.enterText(
      find.byKey(const Key('kitchen.custom.name')),
      'Tanda\u200baneh',
    );
    await tapKeyed(tester, 'kitchen.custom.category.leftovers');
    await tapKeyed(tester, 'kitchen.custom.add');
    expect(find.text('Isinya belum benar.'), findsOneWidget);
    expect(find.byKey(const Key('kitchen.custom.name')), findsOneWidget);
    expect(sentChanges(server), isEmpty);
  });

  testWidgets('KIT-05 KIT-16 a custom name the server refuses is taken back '
      'with a message on Dapur Saya', (tester) async {
    server.kitchen.refusedCustomNames = {'Tanda aneh'};
    await openKitchen(tester, server);
    await tapKeyed(tester, 'kitchen.fab');
    await tapKeyed(tester, 'kitchen.menu.custom');
    await tester.enterText(
      find.byKey(const Key('kitchen.custom.name')),
      'Tanda aneh',
    );
    await tapKeyed(tester, 'kitchen.custom.category.leftovers');
    await tapKeyed(tester, 'kitchen.custom.add');
    expect(
      find.text(
        'Tanda aneh: perubahan ini tidak bisa disimpan, jadi dikembalikan '
        'seperti semula.',
      ),
      findsOneWidget,
    );
    expect(find.text('Belum dikenal'), findsNothing);
    expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);
  });

  testWidgets('KIT-05 "did you mean" offers the known ingredient first, so '
      'Cek Aman can check it', (tester) async {
    await openKitchen(tester, server);
    await tapKeyed(tester, 'kitchen.fab');
    await tapKeyed(tester, 'kitchen.menu.custom');
    await tester.enterText(
      find.byKey(const Key('kitchen.custom.name')),
      'temp',
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Mungkin maksud Anda Tempe? Bahan dari daftar bisa diperiksa Cek Aman.',
      ),
      findsOneWidget,
    );
    await tapKeyed(tester, 'kitchen.custom.useKnown');
    expect(withoutIdAndAge(sentChanges(server).single), {
      'ingredient': {'ingredientId': 'fx_kit_tempe'},
      'operation': 'upsert',
      'category': 'protein',
      'state': 'available',
    });
    expect(find.text('Tempe'), findsOneWidget);
    expect(find.text('Belum dikenal'), findsNothing);
  });

  testWidgets('KIT-07 ACC-05 default staples show and toggle like any item', (
    tester,
  ) async {
    server.kitchen.defaultStaples = ['fx_kit_beras', 'fx_kit_bawang_merah'];
    await openKitchen(tester, server);
    expect(find.text('Beras'), findsOneWidget);
    expect(find.text('Bawang merah'), findsOneWidget);
    final account = server.accountFor(kitchenContact)!;
    final beras = server
        .kitchenOf(account)
        .firstWhere((i) => i['ingredientId'] == 'fx_kit_beras');
    expect(beras['isDefaultStaple'], isTrue);
    await tapKeyed(tester, 'kitchen.item.${beras['id']}');
    expect(beras['state'], 'out');
    expect(find.text('Beras · Habis'), findsOneWidget);
  });

  testWidgets('KIT-04 the catalog is kept on the phone: the next start sends '
      'If-None-Match and gets 304; offline search uses the copy', (
    tester,
  ) async {
    final first = await openKitchen(tester, server);
    final downloads = requestsTo(server, 'GET', _catalog);
    expect(downloads, hasLength(1));
    expect(downloads.single.headers['if-none-match'], isNull);
    expect(
      await first.phone.db
          .select(first.phone.db.cachedCatalogIngredients)
          .get(),
      hasLength(9),
    );
    await closeApp(tester);

    // The same phone again: a conditional request, answered with 304.
    final container = await pumpPhone(
      tester,
      server: server,
      phone: first.phone,
    );
    await tapNav(tester, 'Dapur Saya');
    final conditional = requestsTo(server, 'GET', _catalog).last;
    expect(conditional.headers['if-none-match'], server.kitchen.etag);
    expect(container.read(catalogProvider), isA<CatalogReady>());

    // Without internet the search runs on the copy and says so.
    server.intercept = (r) =>
        r.url.path == _search ? throw http.ClientException('offline') : null;
    await search(tester, 'kemangi');
    expect(find.byKey(const Key('kitchen.search.fromPhone')), findsOneWidget);
    expect(find.text('Kemangi'), findsOneWidget);
  });

  testWidgets('KIT-04 without internet and without a copy the search says '
      'kitchen.search.offlineNoCache', (tester) async {
    server.intercept = (r) => r.url.path.startsWith('/v1/reference/')
        ? throw http.ClientException('offline')
        : null;
    await openKitchen(tester, server);
    await search(tester, 'tempe');
    expect(
      find.text(
        'Daftar bahan belum tersimpan di HP. Sambungkan internet untuk mencari.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('kitchen.search.noMatch')), findsNothing);
  });

  testWidgets('KIT-04 AI-08 503 reference_data_unavailable is a clear state, '
      'never "no results"; custom items still work', (tester) async {
    server.kitchen.referenceAvailable = false;
    final phone = await openKitchen(tester, server);
    expect(phone.container.read(catalogProvider), isA<CatalogUnavailable>());
    await search(tester, 'tempe');
    expect(find.byKey(const Key('kitchen.search.unavailable')), findsOneWidget);
    expect(
      find.text(
        'Daftar bahan sedang tidak bisa dibuka. Anda tetap bisa menambah bahan '
        'baru.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('kitchen.search.noMatch')), findsNothing);
    await tapKeyed(tester, 'kitchen.search.addCustom');
    await tapKeyed(tester, 'kitchen.custom.category.protein');
    await tapKeyed(tester, 'kitchen.custom.add');
    expect(find.text('Belum dikenal'), findsOneWidget);
  });

  testWidgets('KIT-01 the kitchen limit refuses the add with '
      'kitchen_item_limit_reached', (tester) async {
    server.kitchen.maxItems = 1;
    await openKitchen(
      tester,
      server,
      seed: (a) => server.seedKitchenItem(a, ingredientId: 'fx_kit_beras'),
    );
    expect(find.byKey(const Key('kitchen.limit')), findsOneWidget);
    await search(tester, 'tempe');
    await tapKeyed(tester, 'kitchen.search.add.fx_kit_tempe');
    expect(
      find.text(
        'Dapur Saya sudah penuh: 1 bahan. Hapus bahan yang tidak dipakai lagi '
        'untuk menambah yang baru.',
      ),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('kitchen.search.state.fx_kit_tempe')),
      findsNothing,
    );
    expect(sentChanges(server), isEmpty);
  });

  testWidgets('KIT-16 an add without internet shows at once and is sent '
      'later with the same change ID', (tester) async {
    final phone = await openKitchen(tester, server);
    var offline = true;
    server.intercept = (r) => offline && r.url.path == syncPath
        ? throw http.ClientException('offline')
        : null;
    await search(tester, 'tempe');
    await tapKeyed(tester, 'kitchen.search.add.fx_kit_tempe');
    expect(
      find.byKey(const Key('kitchen.search.state.fx_kit_tempe')),
      findsOneWidget,
    );
    await tapKeyed(tester, 'kitchen.search.close');
    expect(find.text('Tempe'), findsOneWidget);
    expect(syncCaption(tester), 'Belum terkirim · 1 perubahan');
    final tried = server.kitchen.syncBodies.length;

    offline = false;
    phone.phone.sync.timers.fireAll();
    await tester.pumpAndSettle();
    expect(syncCaption(tester), 'Tersimpan');
    final ids = {
      for (final body in server.kitchen.syncBodies.skip(1))
        for (final c in body['changes']! as List)
          (c as Map<String, Object?>)['changeId'],
    };
    expect(server.kitchen.syncBodies.length, greaterThan(tried));
    expect(ids, hasLength(1));
    expect(
      server.kitchenOf(phone.account).single['ingredientId'],
      'fx_kit_tempe',
    );
  });

  testWidgets('KIT-01 NFR-05 without internet the phone\'s copy of the '
      'kitchen is shown with a note', (tester) async {
    final first = await openKitchen(
      tester,
      server,
      seed: (a) => server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe'),
    );
    await closeApp(tester);
    goOffline(server);
    final container = await pumpPhone(
      tester,
      server: server,
      phone: first.phone,
    );
    await tapNav(tester, 'Dapur Saya');
    expect(find.text('Tempe'), findsOneWidget);
    expect(find.byKey(const Key('kitchen.offline')), findsOneWidget);
    final state = container.read(kitchenProvider) as KitchenLoaded;
    expect(state.list.items.single.state, KitchenItemState.available);
  });

  testWidgets('KIT-01 a load failure shows the error with retry, never an '
      'empty kitchen', (tester) async {
    var fail = true;
    server.intercept = (r) => fail && r.url.path == syncPath
        ? FakeServer.problem('internal_error', 500)
        : null;
    await openKitchen(tester, server);
    expect(find.byKey(const Key('kitchen.error')), findsOneWidget);
    expect(find.byKey(const Key('kitchen.empty')), findsNothing);
    fail = false;
    await tapKeyed(tester, 'kitchen.retry');
    expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);
  });
}
