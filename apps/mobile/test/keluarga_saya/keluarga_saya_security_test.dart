// Security review T-028 follow-ups (docs/reviews/2026-11-14-t028-security.md):
// M1 the keyboard does not learn rule text or member names, L1 no rule is
// sent after the session ends mid-save, I6 the household time zone resets
// on an account change.
// TEST FIXTURE: not real safety or nutrition data. Names and rules are
// invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/time/household_time.dart';
import 'package:keluargamakan/data/family_profiles_state.dart';
import 'package:keluargamakan/features/auth/sign_in_screen.dart';
import 'package:keluargamakan/features/keluarga_saya/rules_picker_screen.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'family_test_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  testWidgets('DAT-02 PRF-03 M1 the rule text field is not learned, suggested '
      'or corrected by the keyboard', (tester) async {
    await openFamily(tester, server, members: [ibu(), kakak()]);
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.rules.add');
    await tapKeyed(tester, 'rules.other.open');
    final field = tester.widget<TextField>(
      find.byKey(const Key('rules.other.field')),
    );
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
  });

  testWidgets('PRF-01 PRF-18 M1 member names are not learned by the '
      'keyboard', (tester) async {
    await openFamily(tester, server);
    await tapKeyed(tester, 'family.add');
    final field = tester.widget<TextField>(
      find.byKey(const Key('profile.name')),
    );
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.autocorrect, isFalse);
  });

  testWidgets('ACC-13 DAT-02 L1 when the session ends while rules are being '
      'saved, no further rule is sent', (tester) async {
    final a = await openFamily(tester, server, members: [ibu(), kakak()]);
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.rules.add');
    for (final text in ['rahasia-satu', 'rahasia-dua', 'rahasia-tiga']) {
      await tapKeyed(tester, 'rules.other.open');
      await tester.enterText(find.byKey(const Key('rules.other.field')), text);
      await tapKeyed(tester, 'rules.other.add');
    }
    server.delays['/v1/household/profiles/p-kakak/hard-rules'] = const Duration(
      seconds: 2,
    );
    await tester.tap(find.byKey(const Key('rules.save')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(requestsTo(server, 'POST', '/hard-rules'), hasLength(1));

    // The session ends (for example the refresh token is rejected).
    await a.container
        .read(sessionManagerProvider)
        .end(SessionEndReason.expired);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    final posts = requestsTo(server, 'POST', '/hard-rules');
    expect(posts, hasLength(1), reason: 'nothing sent after the session end');
    expect(posts.single.headers['authorization'], isNotNull);
    expect(find.byType(RulesPickerScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(a.container.read(familyProfilesProvider), isA<FamilyLoading>());
    for (final text in visibleTexts(tester)) {
      expect(text, isNot(contains('rahasia')));
      expect(text, isNot(contains('Kakak')));
    }
  });

  test('ACC-13 I6 the known household time zone resets when another account '
      'signs in', () async {
    final container = testContainer(
      handler: (_) async => throw StateError('no requests expected'),
    );
    addTearDown(container.dispose);
    final session = container.read(sessionManagerProvider);
    await session.start(testTokens);
    container.listen(currentAccountIdProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentAccountIdProvider), 'acc-1');

    container
        .read(knownHouseholdTimeZoneProvider.notifier)
        .set(HouseholdTimeZone.wit);
    expect(
      container.read(knownHouseholdTimeZoneProvider),
      HouseholdTimeZone.wit,
    );

    // Another account on the same run, without the session ending first.
    await session.start(
      SessionTokens(
        accountId: 'acc-2',
        accessToken: 'access-2',
        accessTokenExpiresAt: DateTime.utc(2026, 11, 11, 12),
        refreshToken: 'refresh-2',
        refreshTokenExpiresAt: DateTime.utc(2026, 12, 11),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentAccountIdProvider), 'acc-2');
    expect(container.read(knownHouseholdTimeZoneProvider), isNull);

    // The new account's household still sets its own zone.
    container
        .read(knownHouseholdTimeZoneProvider.notifier)
        .set(HouseholdTimeZone.wita);
    expect(
      container.read(knownHouseholdTimeZoneProvider),
      HouseholdTimeZone.wita,
    );
  });

  testWidgets('ACC-13 I6 the household zone set at startup resets when the '
      'session ends', (tester) async {
    final a = await openFamily(tester, server, openTab: false);
    a.container.listen(knownHouseholdTimeZoneProvider, (_, _) {});
    expect(
      a.container.read(knownHouseholdTimeZoneProvider),
      HouseholdTimeZone.wib,
    );
    await a.container
        .read(sessionManagerProvider)
        .end(SessionEndReason.signedOut);
    await tester.pumpAndSettle();
    expect(a.container.read(knownHouseholdTimeZoneProvider), isNull);
  });
}
