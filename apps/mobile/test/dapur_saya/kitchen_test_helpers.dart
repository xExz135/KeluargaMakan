// TEST FIXTURE: not real safety or nutrition data. Names and contacts are
// invented; the catalog holds names and categories only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import '../keluarga_saya/family_test_helpers.dart' show tapKeyed;

export '../keluarga_saya/family_test_helpers.dart'
    show
        bodiesOf,
        requestsTo,
        visibleTexts,
        expectNoSafetyVerdict,
        tapText,
        tapKeyed,
        systemBack;

const kitchenContact = '+6281200000002';

final class KitchenPhone {
  KitchenPhone(this.container, this.phone, this.account);

  final ProviderContainer container;
  final TestPhone phone;
  final String account;
}

/// Signs a household in, lets [seed] fill its kitchen on the server, pumps
/// the app and opens Dapur Saya.
Future<KitchenPhone> openKitchen(
  WidgetTester tester,
  FakeServer server, {
  void Function(String account)? seed,
  double textScale = 1.0,
  Size size = TestWindows.phone,
  Brightness brightness = Brightness.light,
  String language = 'id',
  TestPhone? phone,
  String contact = kitchenContact,
  Map<String, Object?> config = const {},
  bool openTab = true,
}) async {
  final tokens = server.seedSignedIn(contact);
  seed?.call(tokens.accountId);
  final usedPhone =
      phone ??
      TestPhone(
        tokens: InMemoryTokenStore(tokens),
        store: InMemoryKeyValueStore({
          if (language != 'id') PreferenceKeys.locale: language,
        }),
      );
  if (phone == null) addTearDown(usedPhone.db.close);
  final container = await pumpPhone(
    tester,
    server: server,
    phone: usedPhone,
    textScale: textScale,
    size: size,
    platformBrightness: brightness,
    config: config,
  );
  if (openTab) await tapNav(tester, 'Dapur Saya');
  return KitchenPhone(container, usedPhone, tokens.accountId);
}

/// The item toggle with the server item [id].
Finder itemToggle(String id) => find.byKey(Key('kitchen.item.$id'));

/// The accessibility label of the toggle [id].
String toggleLabel(WidgetTester tester, String id) =>
    tester.getSemantics(itemToggle(id)).label;

/// Opens K2 and types [query], waiting for the answer.
Future<void> search(WidgetTester tester, String query) async {
  await tapKeyed(tester, 'kitchen.search.open');
  await tester.enterText(find.byKey(const Key('kitchen.search.field')), query);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
