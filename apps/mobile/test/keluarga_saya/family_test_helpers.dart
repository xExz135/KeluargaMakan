// TEST FIXTURE: not real safety or nutrition data. Names, contacts and
// rules are invented.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';

const managerContact = '+6281200000001';

/// An adult member "Kakak" with the given consent and rules.
Map<String, Object?> kakak({
  String consent = 'given',
  bool renewalRequired = false,
  List<Object?> rules = const [],
  String ageGroup = 'adult',
}) => profileJson(
  id: 'p-kakak',
  name: 'Kakak',
  ageGroup: ageGroup,
  isManager: false,
  rules: rulesJson(
    consent: consent,
    renewalRequired: renewalRequired,
    items: [...rules],
  ),
);

/// The manager "Ibu" (consent given, no rules).
Map<String, Object?> ibu() => profileJson(id: 'p-ibu', name: 'Ibu');

final class FamilyPhone {
  FamilyPhone(this.container, this.phone, this.account);

  final ProviderContainer container;
  final TestPhone phone;
  final String account;
}

/// Pumps the app signed in to a household, with [members] as its profiles
/// (manager first; default: the manager only), and opens Keluarga.
Future<FamilyPhone> openFamily(
  WidgetTester tester,
  FakeServer server, {
  List<Map<String, Object?>>? members,
  double textScale = 1.0,
  Size size = TestWindows.phone,
  Brightness brightness = Brightness.light,
  String language = 'id',
  bool openTab = true,
}) async {
  final tokens = server.seedSignedIn(managerContact);
  if (members != null) server.profilesByAccount[tokens.accountId] = members;
  final phone = TestPhone(
    tokens: InMemoryTokenStore(tokens),
    store: InMemoryKeyValueStore({
      if (language != 'id') PreferenceKeys.locale: language,
    }),
  );
  addTearDown(phone.db.close);
  final container = await pumpPhone(
    tester,
    server: server,
    phone: phone,
    textScale: textScale,
    size: size,
    platformBrightness: brightness,
  );
  if (openTab) {
    // "Keluarga" in both languages (copy deck nav.family).
    await tapNav(tester, 'Keluarga');
  }
  return FamilyPhone(container, phone, tokens.accountId);
}

/// The JSON bodies of requests with [method] whose path ends with [suffix].
List<Map<String, Object?>> bodiesOf(
  FakeServer server,
  String method,
  String suffix,
) => [
  for (final r in requestsTo(server, method, suffix))
    jsonDecode(r.body) as Map<String, Object?>,
];

List<http.Request> requestsTo(
  FakeServer server,
  String method,
  String suffix,
) => [
  for (final r in server.requests)
    if (r.method == method && r.url.path.endsWith(suffix)) r,
];

/// The index of the first request with [method] and path ending [suffix].
int indexOfRequest(FakeServer server, String method, String suffix) => server
    .requests
    .indexWhere((r) => r.method == method && r.url.path.endsWith(suffix));

/// Every text on screen.
Iterable<String> visibleTexts(WidgetTester tester) sync* {
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget as Text;
    yield w.data ?? w.textSpan?.toPlainText() ?? '';
  }
  for (final e in find.byType(RichText).evaluate()) {
    yield (e.widget as RichText).text.toPlainText();
  }
}

/// No text calls a person or a food "aman"/"safe" (the feature name
/// "Cek Aman" and "tanda Aman"/"Safe badge" naming the badge are fine).
void expectNoSafetyVerdict(WidgetTester tester) {
  final verdict = RegExp(
    r'(?<!cek |tanda )\baman\b|\bsafe\b(?! badge)',
    caseSensitive: false,
  );
  for (final text in visibleTexts(tester)) {
    expect(verdict.hasMatch(text), isFalse, reason: text);
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls [key] into view and taps it.
Future<void> tapKeyed(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Android system back.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
