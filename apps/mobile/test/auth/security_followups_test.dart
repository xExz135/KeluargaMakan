// Security review T-027 follow-ups (docs/reviews/2026-11-14-t027-security.md):
// M1 in-memory household state resets on an account change, L1 a sign-in
// completes even if the code screen is left, L2 the contact field is not
// learned by the keyboard, L3 429 waits are capped, L4 a token store that
// cannot be cleared still signs out and is not trusted at the next start.
// TEST FIXTURE: not real safety or nutrition data. Names, contacts and
// rules are invented.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';
import 'package:keluargamakan/data/family_profiles_state.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/features/auth/app_entry.dart';
import 'package:keluargamakan/features/auth/code_entry_screen.dart';
import 'package:keluargamakan/features/auth/contact_entry_screen.dart';
import 'package:keluargamakan/features/auth/name_screen.dart';
import 'package:keluargamakan/features/auth/sign_in_draft.dart';
import 'package:keluargamakan/features/auth/sign_in_failure.dart';
import 'package:keluargamakan/features/auth/sign_in_screen.dart';
import 'package:keluargamakan/features/auth/welcome_screen.dart';
import 'package:keluargamakan/features/masak_apa_hari_ini/home_screen.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';

const _phoneA = '0812 3456 7890';
const _phoneAE164 = '+6281234567890';
const _emailB = 'budi@contoh.com';
const _secretName = 'Nenek Rahasia';

Future<void> _signIn(
  WidgetTester tester, {
  bool email = false,
  String contact = _phoneA,
}) async {
  await tapKey(tester, 'welcome.haveAccount');
  await tapKey(tester, email ? 'signIn.email' : 'signIn.phone');
  await enterText(tester, 'contact.field', contact);
  await tapKey(tester, 'contact.send');
  await enterText(tester, 'code.field', fixtureCode);
}

Future<void> _createHousehold(WidgetTester tester, String name) async {
  await enterText(tester, 'name.field', name);
  await tapKey(tester, 'name.continue');
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Pengaturan'));
  await tester.pumpAndSettle();
  await tapKey(tester, 'settings.signOut');
  await tapKey(tester, 'settings.signOut.confirm');
}

/// Everything a family state shows: names and hard-rule allergens.
String _familyText(FamilyProfilesState state) => switch (state) {
  FamilyLoaded(:final profiles) => [
    for (final m in profiles.members) ...[
      m.name,
      if (m.rules case RulesSaved(:final items))
        for (final rule in items) '${rule.allergen}',
    ],
  ].join(' '),
  _ => '',
};

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  final phones = <TestPhone>[];

  TestPhone newPhone({TokenStore? tokens}) {
    final phone = TestPhone(tokens: tokens);
    phones.add(phone);
    return phone;
  }

  setUp(() => server = FakeServer());
  tearDown(() async {
    for (final p in phones) {
      await p.db.close();
    }
    phones.clear();
  });

  group('M1 in-memory household state belongs to one account', () {
    testWidgets('ACC-13 DAT-02 after A signs out and B signs in on the same '
        'run, B sees none of A\'s names or rules, from memory or cache', (
      tester,
    ) async {
      final phone = newPhone();
      final container = await pumpPhone(tester, server: server, phone: phone);
      final states = <FamilyProfilesState>[];
      container.listen(
        familyProfilesProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      // A: family with a hard rule.
      await _signIn(tester);
      await _createHousehold(tester, 'Ibu');
      final accountA = server.accountFor(_phoneAE164)!;
      server.profilesByAccount[accountA] = [
        profileJson(
          id: 'p-a',
          name: _secretName,
          rules: rulesJson(items: [allergyRuleJson(allergen: 'peanut')]),
        ),
      ];
      await container.read(familyProfilesProvider.notifier).reload();
      await tester.pumpAndSettle();
      expect(
        _familyText(container.read(familyProfilesProvider)),
        contains(_secretName),
      );
      expect(
        _familyText(container.read(familyProfilesProvider)),
        contains('peanut'),
      );

      // A signs out: the family is gone from memory at once.
      await _signOut(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(container.read(familyProfilesProvider), isA<FamilyLoading>());
      states.clear();

      // B signs in by email on the same run, offline for the family first.
      server.intercept = (r) => r.url.path == '/v1/household/profiles'
          ? throw http.ClientException('offline')
          : null;
      await _signIn(tester, email: true, contact: _emailB);
      await _createHousehold(tester, 'Budi');
      expect(find.byType(HomeScreen), findsOneWidget);
      await container.read(familyProfilesProvider.notifier).reload();
      await tester.pumpAndSettle();
      expect(container.read(familyProfilesProvider), isA<FamilyLoadFailed>());

      // Online: only B's family.
      server.intercept = null;
      await container.read(familyProfilesProvider.notifier).reload();
      await tester.pumpAndSettle();
      expect(_familyText(container.read(familyProfilesProvider)), 'Budi');

      for (final state in states) {
        expect(_familyText(state), isNot(contains(_secretName)));
        expect(_familyText(state), isNot(contains('peanut')));
      }
    });

    testWidgets('ACC-13 an answer for A that arrives after A signed out is '
        'dropped', (tester) async {
      final phone = newPhone();
      final container = await pumpPhone(tester, server: server, phone: phone);
      container.listen(familyProfilesProvider, (_, _) {});
      await _signIn(tester);
      await _createHousehold(tester, 'Ibu');
      server.profilesByAccount[server.accountFor(_phoneAE164)!] = [
        profileJson(id: 'p-a', name: _secretName),
      ];

      server.delays['/v1/household/profiles'] = const Duration(seconds: 2);
      unawaited(container.read(familyProfilesProvider.notifier).reload());
      await tester.pump(const Duration(milliseconds: 100));
      await _signOut(tester);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(container.read(familyProfilesProvider), isA<FamilyLoading>());
    });
  });

  group('L1 a sign-in that completes is never hidden', () {
    testWidgets('ACC-01 while the code is checked, Android back and "Ganti '
        'nomor" are blocked', (tester) async {
      await pumpPhone(tester, server: server, phone: newPhone());
      await tapKey(tester, 'welcome.haveAccount');
      await tapKey(tester, 'signIn.phone');
      await enterText(tester, 'contact.field', _phoneA);
      await tapKey(tester, 'contact.send');

      server.delays['/v1/auth/code/verify'] = const Duration(seconds: 2);
      await tester.enterText(find.byKey(const Key('code.field')), fixtureCode);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CodeEntryScreen), findsOneWidget);
      final change = tester.widget<TextButton>(
        find.descendant(
          of: find.byKey(const Key('code.change')),
          matching: find.byType(TextButton),
        ),
      );
      expect(change.onPressed, isNull);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(NameScreen), findsOneWidget);
    });

    testWidgets('ACC-01 ACC-13 if the screen is gone when the answer comes, '
        'the app still moves on and drops the draft', (tester) async {
      final phone = newPhone();
      final container = await pumpPhone(tester, server: server, phone: phone);
      await tapKey(tester, 'welcome.haveAccount');
      await tapKey(tester, 'signIn.phone');
      await enterText(tester, 'contact.field', _phoneA);
      await tapKey(tester, 'contact.send');

      server.delays['/v1/auth/code/verify'] = const Duration(seconds: 2);
      await tester.enterText(find.byKey(const Key('code.field')), fixtureCode);
      await tester.pump(const Duration(milliseconds: 100));
      // The whole screen tree goes away (for example the activity is
      // recreated); the providers stay.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));

      expect(await phone.tokens.read(), isNotNull);
      expect(container.read(appEntryProvider), isA<EntryNeedsHousehold>());
      expect(container.read(signInDraftProvider), isNull);
    });

    testWidgets('ACC-01 leaving O2a without signing in drops the number from '
        'memory', (tester) async {
      final container = await pumpPhone(
        tester,
        server: server,
        phone: newPhone(),
      );
      await tapKey(tester, 'welcome.haveAccount');
      await tapKey(tester, 'signIn.phone');
      await enterText(tester, 'contact.field', _phoneA);
      await tapKey(tester, 'contact.send');
      expect(container.read(signInDraftProvider), isNotNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ContactEntryScreen), findsOneWidget);
      expect(container.read(signInDraftProvider), isNotNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(container.read(signInDraftProvider), isNull);
    });
  });

  testWidgets('L2 DAT-08 the number and email fields opt out of keyboard '
      'learning', (tester) async {
    await pumpPhone(tester, server: server, phone: newPhone());
    await tapKey(tester, 'welcome.haveAccount');
    for (final channel in ['signIn.phone', 'signIn.email']) {
      await tapKey(tester, channel);
      final field = tester.widget<TextField>(
        find.byKey(const Key('contact.field')),
      );
      expect(field.enableIMEPersonalizedLearning, isFalse, reason: channel);
      expect(field.enableSuggestions, isFalse, reason: channel);
      expect(field.autocorrect, isFalse, reason: channel);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });

  group('L3 429 waits are capped (auth.maxRetryWaitSeconds)', () {
    ProblemFailure tooMany({int? body, String? header}) => ProblemFailure.of(
      ApiProblem.parse(
        429,
        '{"code":"rate_limited"${body == null ? '' : ',"retryAfterSeconds":$body'}}',
        retryAfterHeader: header,
      ),
    );
    const day = Duration(hours: 24);

    test('ACC-01 huge, negative, missing and normal waits', () {
      expect(retryWait(tooMany(header: '99999999999999'), day), day);
      expect(retryWait(tooMany(body: 99999999999999), day), day);
      expect(
        retryWait(tooMany(header: '99999999999999999999999'), day),
        const Duration(seconds: 60),
      );
      expect(
        retryWait(tooMany(header: '-5'), day),
        const Duration(seconds: 60),
      );
      expect(retryWait(tooMany(), day), const Duration(seconds: 60));
      expect(
        retryWait(tooMany(header: '90'), day),
        const Duration(seconds: 90),
      );
      expect(
        retryWait(const NetworkFailure(), day),
        const Duration(seconds: 60),
      );
    });

    testWidgets('ACC-01 a huge Retry-After on the code request shows the '
        'capped wait without an error', (tester) async {
      server.intercept = (r) => r.url.path == '/v1/auth/code/request'
          ? FakeServer.problem(
              'rate_limited',
              429,
              headers: {'retry-after': '99999999999999'},
            )
          : null;
      await pumpPhone(tester, server: server, phone: newPhone());
      await tapKey(tester, 'welcome.haveAccount');
      await tapKey(tester, 'signIn.phone');
      await enterText(tester, 'contact.field', _phoneA);
      await tapKey(tester, 'contact.send');
      expect(tester.takeException(), isNull);
      expect(
        find.text('Terlalu banyak percobaan. Coba lagi dalam 1440 menit.'),
        findsOneWidget,
      );
    });

    testWidgets('ACC-01 a huge retryAfterSeconds on verify is capped too, '
        'and the cap comes from config', (tester) async {
      await pumpPhone(
        tester,
        server: server,
        phone: newPhone(),
        config: {'auth.maxRetryWaitSeconds': 3600},
      );
      await tapKey(tester, 'welcome.haveAccount');
      await tapKey(tester, 'signIn.phone');
      await enterText(tester, 'contact.field', _phoneA);
      await tapKey(tester, 'contact.send');
      server.intercept = (r) => r.url.path == '/v1/auth/code/verify'
          ? FakeServer.problem(
              'rate_limited',
              429,
              extra: {'retryAfterSeconds': 99999999999999},
            )
          : null;
      await enterText(tester, 'code.field', fixtureCode);
      expect(tester.takeException(), isNull);
      expect(
        find.text('Terlalu banyak percobaan. Coba lagi dalam 60 menit.'),
        findsOneWidget,
      );
      expect(find.text('Kirim ulang dalam 60 menit'), findsOneWidget);
    });
  });

  group('L4 a token store that cannot be cleared', () {
    test(
      'ACC-13 SessionManager.end never throws and reports the tokens',
      () async {
        final store = FlakyTokenStore()..failClear = true;
        await store.write(testTokens);
        final marker = _MemoryMarker();
        final session = SessionManager(
          store: store,
          refresh: (_) => throw UnimplementedError(),
          revocation: marker,
        );
        addTearDown(session.dispose);
        await session.load();
        expect(session.isSignedIn, isTrue);
        final errors = <Object>[];
        session.ended.listen((_) {}, onError: errors.add);

        expect(await session.end(SessionEndReason.signedOut), isFalse);
        await pumpEventQueue();
        expect(session.isSignedIn, isFalse);
        expect(errors.single, isA<SessionDataNotCleared>());
        expect((errors.single as SessionDataNotCleared).tokensRemoved, isFalse);
        expect(marker.isSet, isTrue);

        // Next start: the stored tokens are not used.
        final next = SessionManager(
          store: store,
          refresh: (_) => throw UnimplementedError(),
          revocation: marker,
        );
        addTearDown(next.dispose);
        await next.load();
        expect(next.isSignedIn, isFalse);
        expect(marker.isSet, isTrue);

        store.failClear = false;
        await next.load();
        expect(next.isSignedIn, isFalse);
        expect(await store.read(), isNull);
        expect(marker.isSet, isFalse);
      },
    );

    testWidgets('ACC-13 sign-out still ends in the UI with a message, and the '
        'next start does not sign back in', (tester) async {
      final tokens = FlakyTokenStore();
      final phone = newPhone(tokens: tokens);
      await pumpPhone(tester, server: server, phone: phone);
      await _signIn(tester);
      await _createHousehold(tester, 'Ibu');

      tokens.failClear = true;
      await _signOut(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(
        find.textContaining('Sebagian data belum terhapus dari HP ini'),
        findsOneWidget,
      );
      expect(await tokens.read(), isNotNull, reason: 'clear failed');
      expect(phone.store.getString(PreferenceKeys.sessionRevoked), '1');

      // Next start, the store still failing: signed out, nothing requested.
      await closeApp(tester);
      server.requests.clear();
      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(server.requests, isEmpty);

      // The store works again: the tokens are removed for good.
      tokens.failClear = false;
      await closeApp(tester);
      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(await tokens.read(), isNull);
      expect(phone.store.getString(PreferenceKeys.sessionRevoked), isNull);

      // A new sign-in is trusted again at the next start.
      await _signIn(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await closeApp(tester);
      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('ACC-13 a sign-out whose local data cannot be removed still '
        'moves the app to O1 and tells the user', (tester) async {
      final phone = newPhone();
      final container = await pumpPhone(tester, server: server, phone: phone);
      await _signIn(tester);
      await _createHousehold(tester, 'Ibu');
      // Removing local data fails every time.
      container
          .read(sessionManagerProvider)
          .addEndHandler((_) async => throw StateError('disk'));
      await _signOut(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(
        find.textContaining('Sebagian data belum terhapus dari HP ini'),
        findsOneWidget,
      );
    });
  });
}

/// The revocation marker kept in memory.
final class _MemoryMarker implements SessionRevocationMarker {
  bool _set = false;

  @override
  bool get isSet => _set;

  @override
  Future<void> set() async => _set = true;

  @override
  Future<void> clear() async => _set = false;
}
