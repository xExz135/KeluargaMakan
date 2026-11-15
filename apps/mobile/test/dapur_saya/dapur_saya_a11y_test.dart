// NFR-15 INT-05 INT-03 Dapur Saya at 200% text: every new screen (K1 list,
// K2 search, K3 new ingredient, K4 item sheet, the add menu) in both
// languages, on a phone and a tablet, light and dark, without overflow,
// with 48 dp targets and labeled controls; Android back closes each one.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

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

Future<void> _scrollToEnd(WidgetTester tester, String where) async {
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.axis == Axis.vertical) {
      position.jumpTo(position.maxScrollExtent);
    }
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: where);
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

  for (final language in ['id', 'en']) {
    for (final size in [TestWindows.phone, TestWindows.tablet]) {
      for (final brightness in Brightness.values) {
        final label = '$language, ${size.width.toInt()}dp, ${brightness.name}';
        testWidgets('NFR-15 INT-05 Dapur Saya screens at 200% ($label)', (
          tester,
        ) async {
          final server = FakeServer()
            ..kitchen.defaultStaples = ['fx_kit_beras'];
          late String customId;
          await openKitchen(
            tester,
            server,
            textScale: 2.0,
            size: size,
            brightness: brightness,
            language: language,
            seed: (a) {
              server
                ..seedKitchenItem(a, ingredientId: 'fx_kit_tempe', usageRank: 1)
                ..seedKitchenItem(a, ingredientId: 'fx_kit_tahu', state: 'out')
                ..seedKitchenItem(a, ingredientId: 'fx_kit_kecap_manis');
              customId =
                  server.seedKitchenItem(
                        a,
                        customName:
                            'Sambal terasi buatan Nenek dari kampung halaman',
                        category: 'sauces_condiments',
                        state: 'out',
                      )['id']!
                      as String;
            },
          );
          await _guidelines(tester, 'K1 $label');
          await _scrollToEnd(tester, 'K1 end $label');
          await _scrollToTop(tester);

          // Out filter.
          await tapKeyed(tester, 'kitchen.filter.out');
          await _guidelines(tester, 'K1 out $label');
          await tapKeyed(tester, 'kitchen.filter.all');

          // K4 for the custom item, then back.
          await tester.ensureVisible(itemToggle(customId));
          await tester.pumpAndSettle();
          await tester.longPress(itemToggle(customId));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('kitchen.sheet.customNote')),
            findsOneWidget,
          );
          await _guidelines(tester, 'K4 $label');
          await _scrollToEnd(tester, 'K4 end $label');
          await systemBack(tester);
          expect(find.byKey(const Key('kitchen.sheet')), findsNothing);

          // Add menu, then back.
          await tapKeyed(tester, 'kitchen.fab');
          expect(find.byKey(const Key('kitchen.menu.custom')), findsOneWidget);
          await _guidelines(tester, 'menu $label');
          await systemBack(tester);

          // K2 with results (one in the kitchen, others not), then back.
          await search(tester, 'ta');
          // Tahu is in the kitchen, so its row shows the state chip.
          expect(
            find.byKey(const Key('kitchen.search.state.fx_kit_tahu')),
            findsOneWidget,
          );
          await _guidelines(tester, 'K2 $label');
          await _scrollToEnd(tester, 'K2 end $label');
          await systemBack(tester);
          expect(find.byKey(const Key('kitchen.search.field')), findsNothing);

          // K3 with an error, then back.
          await tapKeyed(tester, 'kitchen.fab');
          await tapKeyed(tester, 'kitchen.menu.custom');
          await tester.enterText(
            find.byKey(const Key('kitchen.custom.name')),
            'temp',
          );
          await tester.pumpAndSettle();
          await tapKeyed(tester, 'kitchen.custom.add');
          expect(
            find.byKey(const Key('kitchen.custom.categoryMissing')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('kitchen.custom.didYouMean')),
            findsOneWidget,
          );
          await _scrollToTop(tester);
          await _guidelines(tester, 'K3 $label');
          await _scrollToEnd(tester, 'K3 end $label');
          await systemBack(tester);
          expect(find.byKey(const Key('kitchen.custom.name')), findsNothing);
          expect(find.byKey(const Key('kitchen.fab')), findsOneWidget);
        });
      }
    }
  }

  for (final language in ['id', 'en']) {
    testWidgets('NFR-15 Dapur Saya empty, error and search states at 200% '
        '($language)', (tester) async {
      final server = FakeServer();
      var fail = true;
      server.intercept = (r) => fail && r.url.path == syncPath
          ? FakeServer.problem('internal_error', 500)
          : null;
      await openKitchen(tester, server, textScale: 2.0, language: language);
      expect(find.byKey(const Key('kitchen.error')), findsOneWidget);
      await _guidelines(tester, 'error $language');
      fail = false;
      await tapKeyed(tester, 'kitchen.retry');
      expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);
      await _guidelines(tester, 'empty $language');

      await tapKeyed(tester, 'kitchen.empty.list');
      expect(find.byKey(const Key('kitchen.search.empty')), findsOneWidget);
      await _guidelines(tester, 'K2 empty $language');
      await tester.enterText(
        find.byKey(const Key('kitchen.search.field')),
        'tidak ada di daftar sama sekali',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kitchen.search.noMatch')), findsOneWidget);
      await _guidelines(tester, 'K2 no match $language');
      server.kitchen.referenceAvailable = false;
      await tester.enterText(
        find.byKey(const Key('kitchen.search.field')),
        'tempe',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('kitchen.search.unavailable')),
        findsOneWidget,
      );
      await _guidelines(tester, 'K2 unavailable $language');
    });
  }

  testWidgets('INT-03 Ada and Habis differ by icon and word, not only by '
      'color', (tester) async {
    final server = FakeServer();
    late String ada;
    late String habis;
    await openKitchen(
      tester,
      server,
      seed: (a) {
        ada =
            server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
                as String;
        habis =
            server.seedKitchenItem(
                  a,
                  ingredientId: 'fx_kit_tahu',
                  state: 'out',
                )['id']!
                as String;
      },
    );
    expect(
      find.descendant(of: itemToggle(ada), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: itemToggle(habis),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: itemToggle(habis),
        matching: find.text('Tahu · Habis'),
      ),
      findsOneWidget,
    );
    // Toggles meet the configured minimum height (kitchen.toggleMinHeightDp).
    expect(tester.getSize(itemToggle(ada)).height, greaterThanOrEqualTo(56));
  });
}
