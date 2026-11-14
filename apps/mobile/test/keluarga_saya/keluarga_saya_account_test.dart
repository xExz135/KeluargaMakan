// Security review T-027 M1 for Keluarga Saya: everything that holds
// household data in memory belongs to one account. After A signs out and B
// signs in on the same run, B never sees A's members or rules, on screen,
// in memory or in the phone's cache. Also DAT-08: no names or rule text in
// the logs.
// TEST FIXTURE: not real safety or nutrition data. Names, contacts and
// rules are invented.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/data/family_profiles_state.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/features/auth/welcome_screen.dart';
import 'package:keluargamakan/features/masak_apa_hari_ini/home_screen.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'family_test_helpers.dart';

const _secretName = 'Nenek Rahasia';
const _emailB = 'budi@contoh.com';

String _familyText(FamilyProfilesState state) => switch (state) {
  FamilyLoaded(:final profiles) => [
    for (final m in profiles.members) ...[
      m.name,
      if (m.rules case RulesSaved(:final items))
        for (final r in items) '${r.allergen} ${r.freeText}',
    ],
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

  void expectNoA(WidgetTester tester) {
    for (final text in visibleTexts(tester)) {
      expect(text, isNot(contains(_secretName)));
      expect(text, isNot(contains('Kacang tanah')));
      expect(text, isNot(contains('rahasia-teks')));
    }
  }

  testWidgets('ACC-13 DAT-02 after A signs out and B signs in on the same run, '
      'Keluarga Saya shows none of A\'s members or rules', (tester) async {
    final a = await openFamily(
      tester,
      server,
      members: [
        ibu(),
        profileJson(
          id: 'p-secret',
          name: _secretName,
          ageGroup: 'elderly',
          isManager: false,
          rules: rulesJson(
            items: [allergyRuleJson(), freeTextRuleJson('rahasia-teks')],
          ),
        ),
      ],
    );
    expect(find.text(_secretName), findsOneWidget);
    await tapText(tester, _secretName);
    expect(find.text('Alergi Kacang tanah'), findsOneWidget);
    expect(find.text('rahasia-teks'), findsOneWidget);
    await systemBack(tester);

    final states = <FamilyProfilesState>[];
    await signOut(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(a.container.read(familyProfilesProvider), isA<FamilyLoading>());
    a.container.listen(
      familyProfilesProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );

    // B first without internet for the family: no cache from A to fall
    // back on, so an error, never A's names.
    server.intercept = (r) => r.url.path.startsWith('/v1/household/profiles')
        ? throw http.ClientException('offline')
        : null;
    await signInB(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tapNav(tester, 'Keluarga');
    expectNoA(tester);
    expect(find.byKey(const Key('family.error')), findsOneWidget);
    final cached = await a.phone.db.select(a.phone.db.cachedProfiles).get();
    expect(cached.map((r) => r.name), isNot(contains(_secretName)));

    // Online: B's own family only.
    server.intercept = null;
    await tapKeyed(tester, 'family.retry');
    expect(find.text('Budi'), findsOneWidget);
    expectNoA(tester);
    // A's member route does not open A's member for B.
    expect(find.byKey(const Key('family.card.p-secret')), findsNothing);

    for (final state in states) {
      expect(_familyText(state), isNot(contains(_secretName)));
      expect(_familyText(state), isNot(contains('peanut')));
      expect(_familyText(state), isNot(contains('rahasia-teks')));
    }
  });

  testWidgets('DAT-08 no names, rule text or consent decisions reach the '
      'logs, even on failures', (tester) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    try {
      await openFamily(
        tester,
        server,
        members: [
          ibu(),
          kakak(consent: 'none'),
        ],
      );
      // A rule answer this app cannot read (logged as a decode failure).
      var broken = true;
      server.intercept = (r) =>
          broken && r.method == 'POST' && r.url.path.endsWith('/hard-rules')
          ? FakeServer.json({
              'id': 'x',
              'type': 'free_text',
              'freeText': 7,
            }, 201)
          : null;
      await tapKeyed(tester, 'family.card.action.p-kakak');
      await tapKeyed(tester, 'rules.other.open');
      await tester.enterText(
        find.byKey(const Key('rules.other.field')),
        'udang rebon rahasia',
      );
      await tapKeyed(tester, 'rules.other.add');
      await tapKeyed(tester, 'rules.save');
      await tapKeyed(tester, 'consent.accept');
      expect(find.textContaining('belum tersimpan'), findsOneWidget);
      broken = false;
      await tapKeyed(tester, 'rules.save');
      await tapText(tester, 'Kakak');
      await tapKeyed(tester, 'member.consent.withdraw');
      await tapKeyed(tester, 'consent.withdraw.confirm');

      expect(logs, isNotEmpty, reason: 'the decode failure is logged');
      for (final line in logs) {
        for (final secret in [
          'Kakak',
          'Ibu',
          'udang rebon',
          'rahasia',
          'free_text',
          'health-adult-1',
        ]) {
          expect(line, isNot(contains(secret)), reason: line);
        }
      }
    } finally {
      debugPrint = original;
    }
  });
}
