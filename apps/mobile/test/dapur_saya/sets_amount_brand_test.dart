// KIT-08 ingredient sets (K5, the K1 sets row, "Masukkan ke set"), KIT-09
// amount and brand on the item sheet (K4) with SAF-07 brand notes, and their
// accessibility at 200% text in both languages, light and dark (NFR-15,
// INT-05).
// TEST FIXTURE: not real safety or nutrition data. Names, sets and brands
// are invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/data/kitchen_state.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

const _sets = '/v1/household/kitchen/sets';

Future<void> _guidelines(WidgetTester tester, String where) async {
  expect(tester.takeException(), isNull, reason: where);
  final handle = tester.ensureSemantics();
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: where,
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: where,
  );
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: where,
  );
  handle.dispose();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    if (state.position.axis == Axis.vertical) state.position.jumpTo(0);
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  /// Tempe (out), Tahu (out) and Beras (out); a set with Tempe and Tahu.
  Future<(KitchenPhone, Map<String, String>, String)> withSet(
    WidgetTester tester, {
    double textScale = 1.0,
    String language = 'id',
    Brightness brightness = Brightness.light,
  }) async {
    final ids = <String, String>{};
    late String setId;
    final phone = await openKitchen(
      tester,
      server,
      textScale: textScale,
      language: language,
      brightness: brightness,
      seed: (a) {
        for (final name in ['tempe', 'tahu', 'beras']) {
          ids[name] =
              server.seedKitchenItem(
                    a,
                    ingredientId: 'fx_kit_$name',
                    state: 'out',
                  )['id']!
                  as String;
        }
        setId =
            server.seedSet(a, 'Belanja mingguan', [
                  ids['tempe']!,
                  ids['tahu']!,
                ])['id']!
                as String;
      },
    );
    return (phone, ids, setId);
  }

  group('KIT-08 ingredient sets', () {
    testWidgets('KIT-08 KIT-16 "Tandai semua ada" marks only the set\'s items '
        'available, without internet too, and Undo puts them back', (
      tester,
    ) async {
      final (phone, ids, setId) = await withSet(tester);
      expect(find.text('Belanja mingguan'), findsOneWidget);
      expect(find.text('2 bahan'), findsOneWidget);

      goOffline(server);
      await tapKeyed(tester, 'kitchen.set.$setId.markAll');
      expect(find.text('2 bahan ditandai ada'), findsOneWidget);
      expect(toggleLabel(tester, ids['tempe']!), startsWith('Tempe, ada.'));
      expect(toggleLabel(tester, ids['tahu']!), startsWith('Tahu, ada.'));
      // Nothing else changes, and nothing becomes out.
      expect(toggleLabel(tester, ids['beras']!), startsWith('Beras, habis.'));
      expect(syncCaption(tester), 'Belum terkirim · 2 perubahan');

      await tester.tap(find.byKey(const Key('kitchen.sets.undo')));
      await tester.pumpAndSettle();
      expect(toggleLabel(tester, ids['tempe']!), startsWith('Tempe, habis.'));
      expect(toggleLabel(tester, ids['tahu']!), startsWith('Tahu, habis.'));

      await tapKeyed(tester, 'kitchen.set.$setId.markAll');
      server.intercept = null;
      phone.phone.sync.connectivity.goOnline();
      await tester.pumpAndSettle();
      final items = {
        for (final i in server.kitchenOf(phone.account))
          i['ingredientId']: i['state'],
      };
      expect(items, {
        'fx_kit_tempe': 'available',
        'fx_kit_tahu': 'available',
        'fx_kit_beras': 'out',
      });

      // Everything is already available now.
      await tapKeyed(tester, 'kitchen.set.$setId.markAll');
      expect(find.text('Semua bahan di set ini sudah ada.'), findsOneWidget);
    });

    testWidgets('KIT-08 a set is created with a name and items; a create '
        'without internet keeps the input and is sent once', (tester) async {
      final (phone, ids, _) = await withSet(tester);
      await tapKeyed(tester, 'kitchen.sets.manage');
      expect(find.byKey(const Key('kitchen.sets.screen')), findsOneWidget);
      await tapKeyed(tester, 'kitchen.sets.create');

      // Hidden characters in the name are refused before anything is sent.
      await tester.enterText(
        find.byKey(const Key('kitchen.setEditor.name')),
        'Pasar\u202eSabtu',
      );
      await tapKeyed(tester, 'kitchen.setEditor.save');
      expect(find.text('Isinya belum benar.'), findsOneWidget);
      expect(requestsTo(server, 'POST', _sets), isEmpty);

      await tester.enterText(
        find.byKey(const Key('kitchen.setEditor.name')),
        'Pasar Sabtu',
      );
      final field = tester.widget<TextField>(
        find.byKey(const Key('kitchen.setEditor.name')),
      );
      expect(field.enableIMEPersonalizedLearning, isFalse);
      await tapKeyed(tester, 'kitchen.setEditor.item.${ids['beras']}');
      var offline = true;
      server.intercept = (r) => offline && r.url.path == _sets
          ? throw http.ClientException('offline')
          : null;
      await tapKeyed(tester, 'kitchen.setEditor.save');
      expect(
        find.text(
          'Mengubah set butuh internet. Tombol Tandai semua ada bisa dipakai '
          'tanpa internet.',
        ),
        findsOneWidget,
      );
      expect(find.text('Pasar Sabtu'), findsOneWidget);

      offline = false;
      await tapKeyed(tester, 'kitchen.setEditor.save');
      expect(find.byKey(const Key('kitchen.setEditor')), findsNothing);
      expect(find.text('Pasar Sabtu'), findsOneWidget);
      final keys = {
        for (final r in requestsTo(server, 'POST', _sets))
          r.headers['idempotency-key'],
      };
      expect(keys, hasLength(1));
      final created = server.kitchen.setsByAccount[phone.account]!.last;
      expect(created['name'], 'Pasar Sabtu');
      expect(created['itemIds'], [ids['beras']]);
    });

    testWidgets('KIT-08 a set is renamed, then deleted; its items stay', (
      tester,
    ) async {
      final (phone, ids, setId) = await withSet(tester);
      await tapKeyed(tester, 'kitchen.sets.manage');
      await tapKeyed(tester, 'kitchen.sets.menu.$setId');
      await tapKeyed(tester, 'kitchen.sets.menu.edit');
      await tester.enterText(
        find.byKey(const Key('kitchen.setEditor.name')),
        'Belanja bulanan',
      );
      await tapKeyed(tester, 'kitchen.setEditor.item.${ids['tahu']}');
      await tapKeyed(tester, 'kitchen.setEditor.save');
      expect(find.text('Belanja bulanan'), findsOneWidget);
      expect(find.text('1 bahan'), findsOneWidget);
      expect(bodiesOf(server, 'PUT', '$_sets/$setId').single, {
        'name': 'Belanja bulanan',
        'itemIds': [ids['tempe']],
      });

      await tapKeyed(tester, 'kitchen.sets.menu.$setId');
      await tapKeyed(tester, 'kitchen.sets.menu.delete');
      expect(find.text('Hapus set "Belanja bulanan"?'), findsOneWidget);
      expect(
        find.text('Bahan di dalamnya tetap ada di Dapur Saya.'),
        findsOneWidget,
      );
      await tapKeyed(tester, 'kitchen.sets.delete.confirm');
      expect(find.byKey(const Key('kitchen.sets.empty')), findsOneWidget);
      expect(server.kitchen.setsByAccount[phone.account], isEmpty);
      expect(server.kitchenOf(phone.account), hasLength(3));
    });

    testWidgets('KIT-08 "Masukkan ke set" from the item sheet; an item added '
        'without internet waits until it is sent', (tester) async {
      final (phone, ids, setId) = await withSet(tester);
      await openItemSheet(tester, ids['beras']!);
      await tapKeyed(tester, 'kitchen.sheet.addToSet');
      await tapKeyed(tester, 'kitchen.addToSet.$setId');
      expect(server.kitchen.setsByAccount[phone.account]!.single['itemIds'], [
        ids['tempe'],
        ids['tahu'],
        ids['beras'],
      ]);
      await tapKeyed(tester, 'kitchen.addToSet.close');
      Navigator.of(tester.element(find.byKey(const Key('kitchen.sheet'))))
          .pop();
      await tester.pumpAndSettle();
      expect(find.text('3 bahan'), findsOneWidget);

      goOffline(server);
      await search(tester, 'kemangi');
      await tapKeyed(tester, 'kitchen.search.add.fx_kit_kemangi');
      await tapKeyed(tester, 'kitchen.search.close');
      final state = phone.container.read(kitchenProvider) as KitchenLoaded;
      final kemangi = state.list.items.firstWhere(
        (i) => i.ingredientId == 'fx_kit_kemangi',
      );
      expect(kemangi.isLocalOnly, isTrue);
      await openItemSheet(tester, kemangi.id);
      expect(find.byKey(const Key('kitchen.sheet.setLater')), findsOneWidget);
      expect(find.byKey(const Key('kitchen.sheet.addToSet')), findsNothing);
    });
  });

  group('KIT-09 amount and brand on the item sheet', () {
    testWidgets('KIT-09 an amount is set and cleared, shown on the item, '
        'without internet too', (tester) async {
      final (phone, ids, _) = await withSet(tester);
      goOffline(server);
      await openItemSheet(tester, ids['tempe']!);
      await tapKeyed(tester, 'kitchen.sheet.amount.a_little');
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('kitchen.sheet.amount.a_little')),
            )
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const Key('kitchen.sheet.pendingNote')),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.byKey(const Key('kitchen.sheet'))))
          .pop();
      await tester.pumpAndSettle();
      expect(find.text('Sedikit'), findsOneWidget);
      expect(toggleLabel(tester, ids['tempe']!), contains('Sedikit.'));

      server.intercept = null;
      phone.phone.sync.connectivity.goOnline();
      await tester.pumpAndSettle();
      final tempe = server
          .kitchenOf(phone.account)
          .firstWhere((i) => i['id'] == ids['tempe']);
      expect(tempe['quantity'], 'a_little');

      await openItemSheet(tester, ids['tempe']!);
      await tapKeyed(tester, 'kitchen.sheet.amount.clear');
      expect(tempe['quantity'], isNull);
      expect(withoutIdAndAge(sentChanges(server).last), {
        'ingredient': {'ingredientId': 'fx_kit_tempe'},
        'operation': 'upsert',
        'quantity': null,
      });
    });

    testWidgets('KIT-09 SAF-07 the brand picker offers only the ingredient\'s '
        'listed brands; a listed brand is sent by ID with no note', (
      tester,
    ) async {
      late String id;
      final phone = await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_kecap_manis')['id']!
                as String,
      );
      await openItemSheet(tester, id);
      expect(
        find.text(
          'Isi bahan saus dan kaldu bisa beda tiap merek. Mencatat merek '
          'membantu Cek Aman.',
        ),
        findsOneWidget,
      );
      await tapKeyed(tester, 'kitchen.sheet.brand.pick');
      expect(
        find.byKey(const Key('kitchen.brand.option.fx_brand_contoh_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kitchen.brand.option.fx_brand_contoh_b')),
        findsOneWidget,
      );
      // A typed name that matches a listed one does not become it: the
      // listed row is there to pick, and no "use typed" row.
      await tester.enterText(
        find.byKey(const Key('kitchen.brand.field')),
        'merek contoh a',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kitchen.brand.useTyped')), findsNothing);
      await tapKeyed(tester, 'kitchen.brand.option.fx_brand_contoh_a');
      expect(withoutIdAndAge(sentChanges(server).last), {
        'ingredient': {'ingredientId': 'fx_kit_kecap_manis'},
        'operation': 'upsert',
        'brand': {'brandId': 'fx_brand_contoh_a'},
      });
      expect(find.byKey(const Key('kitchen.sheet.brand.name')), findsOneWidget);
      expect(
        find.byKey(const Key('kitchen.sheet.brand.typedNote')),
        findsNothing,
      );
      expect(find.byKey(const Key('kitchen.sheet.brand.why')), findsNothing);
      expectNoSafetyVerdict(tester);
      for (final text in visibleTexts(tester)) {
        expect(text.toLowerCase(), isNot(contains('terverifikasi')));
      }
      expect(server.kitchenOf(phone.account).single['brand'], {
        'brandId': 'fx_brand_contoh_a',
        'name': 'Merek Contoh A',
      });
    });

    testWidgets('KIT-09 SAF-07 a typed brand is kept as text and always shows '
        'that Cek Aman marks it Cek label', (tester) async {
      late String id;
      final phone = await openKitchen(
        tester,
        server,
        seed: (a) => id =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_kecap_manis')['id']!
                as String,
      );
      await openItemSheet(tester, id);
      await tapKeyed(tester, 'kitchen.sheet.brand.pick');
      final field = tester.widget<TextField>(
        find.byKey(const Key('kitchen.brand.field')),
      );
      expect(field.enableIMEPersonalizedLearning, isFalse);
      await tester.enterText(
        find.byKey(const Key('kitchen.brand.field')),
        'Merek Warung',
      );
      await tester.pumpAndSettle();
      const note =
          'Merek ini belum ada di daftar kami. Cek Aman akan memberi tanda Cek '
          'label untuk bahan ini.';
      expect(find.text(note), findsOneWidget);
      await tapKeyed(tester, 'kitchen.brand.useTyped');
      expect(withoutIdAndAge(sentChanges(server).last)['brand'], {
        'customName': 'Merek Warung',
      });
      expect(find.text(note), findsOneWidget);
      expect(server.kitchenOf(phone.account).single['brand'], {
        'brandId': null,
        'name': 'Merek Warung',
      });
      expectNoSafetyVerdict(tester);

      await tapKeyed(tester, 'kitchen.sheet.brand.clear');
      expect(server.kitchenOf(phone.account).single['brand'], isNull);
    });

    testWidgets(
      'KIT-09 SAF-07 SAF-09 a custom sauce takes a typed brand only',
      (tester) async {
        late String id;
        await openKitchen(
          tester,
          server,
          seed: (a) => id =
              server.seedKitchenItem(
                    a,
                    customName: 'Sambal Nenek',
                    category: 'sauces_condiments',
                  )['id']!
                  as String,
        );
        await openItemSheet(tester, id);
        await tapKeyed(tester, 'kitchen.sheet.brand.pick');
        expect(
          find.byKey(const Key('kitchen.brand.listMissing')),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'kitchen.brand.option.',
                ),
          ),
          findsNothing,
        );
      },
    );
  });

  for (final (language, brightness) in [
    ('id', Brightness.light),
    ('en', Brightness.dark),
  ]) {
    testWidgets('NFR-15 INT-05 sets, amount and brand at 200% text '
        '($language, ${brightness.name})', (tester) async {
      final (_, ids, setId) = await withSet(
        tester,
        textScale: 2.0,
        language: language,
        brightness: brightness,
      );
      // K1 at 200%: the sets row is a vertical list.
      expect(find.byKey(Key('kitchen.set.$setId')), findsOneWidget);
      // Checked clear of the extended FAB, which content scrolls under.
      await Scrollable.ensureVisible(
        tester.element(find.byKey(Key('kitchen.set.$setId'))),
      );
      await tester.pumpAndSettle();
      await _guidelines(tester, 'K1 $language');

      await openItemSheet(tester, ids['beras']!);
      await tapKeyed(tester, 'kitchen.sheet.amount.plenty');
      await _scrollToTop(tester);
      await _guidelines(tester, 'K4 $language');
      Navigator.of(tester.element(find.byKey(const Key('kitchen.sheet'))))
          .pop();
      await tester.pumpAndSettle();

      await tapKeyed(tester, 'kitchen.sets.manage');
      await _guidelines(tester, 'K5 $language');
      await tapKeyed(tester, 'kitchen.sets.create');
      await _guidelines(tester, 'set editor $language');
    });
  }

  testWidgets('NFR-15 the sync caption is a live region read with its text', (
    tester,
  ) async {
    final (_, ids, _) = await withSet(tester);
    final handle = tester.ensureSemantics();
    final caption = tester.getSemantics(
      find.byKey(const Key('kitchen.sync.caption')),
    );
    expect(caption.label, 'Tersimpan');
    expect(caption.flagsCollection.isLiveRegion, isTrue);
    goOffline(server);
    await tapKeyed(tester, 'kitchen.item.${ids['tempe']}');
    expect(syncCaption(tester), 'Belum terkirim · 1 perubahan');
    handle.dispose();
  });
}
