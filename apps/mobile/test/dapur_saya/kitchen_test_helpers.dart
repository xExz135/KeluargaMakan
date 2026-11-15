// TEST FIXTURE: not real safety or nutrition data. Names and contacts are
// invented; the catalog holds names and categories only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
  // The server dates seeded items on the test's clock, like the phone.
  server.now ??= () => tester.binding.clock.now();
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

/// The kitchen sync endpoint (KIT-16).
const syncPath = '/v1/household/kitchen/sync';

/// Every queued change the phone sent, in order (contract `KitchenChange`).
List<Map<String, Object?>> sentChanges(FakeServer server) => [
  for (final body in server.kitchen.syncBodies)
    for (final change in body['changes']! as List)
      change as Map<String, Object?>,
];

/// A sent change without its random ID and its age, for comparing.
Map<String, Object?> withoutIdAndAge(Map<String, Object?> change) => {
  for (final e in change.entries)
    if (e.key != 'changeId' && e.key != 'ageMs') e.key: e.value,
};

/// No answer from the kitchen sync and the reference endpoints.
void goOffline(FakeServer server) =>
    server.intercept = (r) =>
        r.url.path == syncPath || r.url.path.startsWith('/v1/reference')
        ? throw http.ClientException('offline')
        : null;

/// The sync caption under the Dapur Saya title.
String syncCaption(WidgetTester tester) =>
    tester.getSemantics(find.byKey(const Key('kitchen.sync.caption'))).label;

/// Opens K4 for the item [id]: centres it on screen (clear of the FAB),
/// then long-presses it.
Future<void> openItemSheet(WidgetTester tester, String id) async {
  await Scrollable.ensureVisible(
    tester.element(itemToggle(id)),
    alignment: 0.4,
  );
  await tester.pumpAndSettle();
  await tester.longPress(itemToggle(id));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('kitchen.sheet')), findsOneWidget);
}
