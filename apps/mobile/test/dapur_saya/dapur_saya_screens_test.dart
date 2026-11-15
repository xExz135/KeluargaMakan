// KIT-01 to KIT-05 Dapur Saya screen states: loading, empty, filter empty,
// English labels, a missing reference name, the add menu, and Android back.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'kitchen_test_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  testWidgets('KIT-01 the first open shows skeleton chips, then the list', (
    tester,
  ) async {
    server.delays[syncPath] = const Duration(seconds: 1);
    await openKitchen(
      tester,
      server,
      openTab: false,
      seed: (a) => server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe'),
    );
    // The answer is held back; nothing else keeps frames coming.
    await tapNav(tester, 'Dapur Saya');
    expect(find.byKey(const Key('kitchen.loading')), findsOneWidget);
    expect(find.text('Tempe'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Tempe'), findsOneWidget);
  });

  testWidgets('KIT-01 an empty kitchen invites to pick from the list', (
    tester,
  ) async {
    await openKitchen(tester, server);
    expect(find.text('Dapur Anda masih kosong'), findsOneWidget);
    expect(
      find.text(
        'Tambahkan bahan yang ada sekarang. Cukup sekali, nanti tinggal ketuk.',
      ),
      findsOneWidget,
    );
    await tapKeyed(tester, 'kitchen.empty.list');
    expect(
      find.text('Ketik nama bahan, misalnya tempe atau kemangi.'),
      findsOneWidget,
    );
    await systemBack(tester);
    expect(find.byKey(const Key('kitchen.empty')), findsOneWidget);
  });

  testWidgets('KIT-02 the filter says when nothing has run out', (
    tester,
  ) async {
    await openKitchen(
      tester,
      server,
      seed: (a) => server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe'),
    );
    await tapKeyed(tester, 'kitchen.filter.out');
    expect(find.text('Tidak ada bahan yang habis.'), findsOneWidget);
  });

  testWidgets('KIT-03 NFR-16 English labels come from the API codes; '
      'reference names follow the app language', (tester) async {
    await openKitchen(
      tester,
      server,
      language: 'en',
      seed: (a) => server
        ..seedKitchenItem(a, ingredientId: 'fx_kit_tempe')
        ..seedKitchenItem(a, ingredientId: 'fx_kit_kecap_manis', state: 'out'),
    );
    expect(find.text('Dapur Saya'), findsWidgets);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Sauces and condiments'), findsOneWidget);
    expect(find.text('Tempeh'), findsOneWidget);
    expect(find.text('Sweet soy sauce · Out'), findsOneWidget);
    expect(find.text('Have'), findsOneWidget);
    expect(find.text('1 have · 0 out'), findsOneWidget);
  });

  testWidgets('KIT-01 a reference item without a name from the server shows '
      'a placeholder, never an empty chip', (tester) async {
    server.kitchen.referenceAvailable = false;
    late String id;
    await openKitchen(
      tester,
      server,
      seed: (a) => id =
          server.seedKitchenItem(a, ingredientId: 'fx_kit_tempe')['id']!
              as String,
    );
    expect(find.text('Nama bahan belum bisa dimuat'), findsOneWidget);
    expect(toggleLabel(tester, id), startsWith('Nama bahan belum bisa dimuat'));
  });

  testWidgets('KIT-04 KIT-05 the add menu offers search and a new '
      'ingredient (photo setup comes with T-039)', (tester) async {
    await openKitchen(tester, server);
    await tapKeyed(tester, 'kitchen.fab');
    expect(find.text('Cari dari daftar'), findsOneWidget);
    expect(find.text('Bahan baru'), findsOneWidget);
    expect(find.text('Foto dapur'), findsNothing);
    await tapKeyed(tester, 'kitchen.menu.search');
    expect(find.byKey(const Key('kitchen.search.field')), findsOneWidget);
    await tapKeyed(tester, 'kitchen.search.close');
    await tapKeyed(tester, 'kitchen.fab');
    await tapKeyed(tester, 'kitchen.menu.custom');
    expect(find.byKey(const Key('kitchen.custom.name')), findsOneWidget);
    // INT-02 Android back closes K3 without adding anything.
    await systemBack(tester);
    expect(find.byKey(const Key('kitchen.custom.name')), findsNothing);
    expect(requestsTo(server, 'POST', '/kitchen/items'), isEmpty);
  });

  testWidgets('KIT-04 the search field keeps the keyboard from learning '
      'what is typed', (tester) async {
    await openKitchen(tester, server);
    await tapKeyed(tester, 'kitchen.search.open');
    final field = tester.widget<TextField>(
      find.byKey(const Key('kitchen.search.field')),
    );
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.autocorrect, isFalse);
    expect(field.maxLength, 60);
  });
}
