// ACC-01, ACC-04, ACC-13: whole flows against a fake API. New account →
// household → shell; returning account → shell; sign out and sign in again
// on another phone (fresh storage) keeps the same account; the session
// ending; startup with a stored session. Contacts and codes never reach
// logs or storage.
// TEST FIXTURE: not real safety or nutrition data. Contacts, codes and names
// are invented.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/app/shell/app_shell.dart';
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/features/auth/name_screen.dart';
import 'package:keluargamakan/features/auth/sign_in_screen.dart';
import 'package:keluargamakan/features/auth/startup_screen.dart';
import 'package:keluargamakan/features/auth/welcome_screen.dart';
import 'package:keluargamakan/features/masak_apa_hari_ini/home_screen.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';

const _phoneTyped = '0812 3456 7890';
const _phoneE164 = '+6281234567890';

/// O1 → O2 → O2a → O2b → verified.
Future<void> signInByPhone(
  WidgetTester tester, {
  String code = fixtureCode,
}) async {
  await tapKey(tester, 'welcome.haveAccount');
  await tapKey(tester, 'signIn.phone');
  await enterText(tester, 'contact.field', _phoneTyped);
  await tapKey(tester, 'contact.send');
  await enterText(tester, 'code.field', code);
}

Future<void> createHousehold(WidgetTester tester, String name) async {
  await enterText(tester, 'name.field', name);
  await tapKey(tester, 'name.continue');
}

Future<void> signOutInSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Pengaturan'));
  await tester.pumpAndSettle();
  await tapKey(tester, 'settings.signOut');
  expect(find.text('Keluar dari akun?'), findsOneWidget);
  await tapKey(tester, 'settings.signOut.confirm');
}

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  final phones = <TestPhone>[];

  TestPhone newPhone() {
    final phone = TestPhone();
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

  testWidgets('ACC-01 ACC-04 a new account creates its household on O3 and '
      'opens the shell', (tester) async {
    final phone = newPhone();
    await pumpPhone(tester, server: server, phone: phone);
    await signInByPhone(tester);

    expect(find.byType(NameScreen), findsOneWidget);
    expect(find.text('Siapa nama panggilan Anda?'), findsOneWidget);
    expect(find.text('Nama ini hanya tampil di aplikasi.'), findsOneWidget);
    FilledButton next() => tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('name.continue')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(next().onPressed, isNull, reason: 'disabled while empty');

    await createHousehold(tester, 'Ibu');

    final post = server.requests.singleWhere(
      (r) => r.method == 'POST' && r.url.path == '/v1/household',
    );
    final body = jsonDecode(post.body) as Map<String, Object?>;
    expect(body['managerProfile'], {'name': 'Ibu'});
    expect(body['language'], 'id');
    expect(
      body['timeZone'],
      isIn(['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura']),
    );
    expect(
      post.headers['idempotency-key'],
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')),
    );
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(server.householdNameOf(server.accountFor(_phoneE164)!), 'Ibu');
  });

  testWidgets('ACC-13 a returning account goes straight to Beranda with a '
      'welcome back, without O3', (tester) async {
    final first = newPhone();
    await pumpPhone(tester, server: server, phone: first);
    await signInByPhone(tester);
    await createHousehold(tester, 'Ibu');
    await closeApp(tester);

    final second = newPhone();
    await pumpPhone(tester, server: server, phone: second);
    await signInByPhone(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NameScreen), findsNothing);
    expect(
      find.text('Selamat datang kembali. Data rumah tangga Anda sudah dimuat.'),
      findsOneWidget,
    );
    expect(server.count('POST', '/v1/household'), 1);
  });

  testWidgets('ACC-13 sign out, then sign in on another phone with fresh '
      'storage: same account, same household, nothing created twice', (
    tester,
  ) async {
    final phoneA = newPhone();
    await pumpPhone(tester, server: server, phone: phoneA);
    await signInByPhone(tester);
    await createHousehold(tester, 'Ibu');
    final account = server.accountFor(_phoneE164);

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk sebagai 0812 •••• 7890'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await signOutInSettings(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(await phoneA.tokens.read(), isNull);
    expect(server.count('POST', '/v1/auth/sign-out'), 1);
    await closeApp(tester);

    final phoneB = newPhone();
    await pumpPhone(tester, server: server, phone: phoneB);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await signInByPhone(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(server.accountFor(_phoneE164), account);
    expect(server.householdNameOf(account!), 'Ibu');
    expect(server.count('POST', '/v1/household'), 1);
    expect((await phoneB.tokens.read())!.accountId, account);

    // And again on the first phone.
    await closeApp(tester);
    await pumpPhone(tester, server: server, phone: phoneA);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await signInByPhone(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('ACC-13 sign out works without internet', (tester) async {
    final phone = newPhone();
    await pumpPhone(tester, server: server, phone: phone);
    await signInByPhone(tester);
    await createHousehold(tester, 'Ibu');

    server.intercept = (r) => throw http.ClientException('offline');
    await signOutInSettings(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(await phone.tokens.read(), isNull);
  });

  testWidgets('ACC-13 security review: when local data cannot be removed at '
      'sign-out the user is told once', (tester) async {
    final phone = newPhone();
    final container = await pumpPhone(tester, server: server, phone: phone);
    await signInByPhone(tester);
    await createHousehold(tester, 'Ibu');
    container
        .read(sessionManagerProvider)
        .addEndHandler((_) async => throw StateError('disk full'));

    await signOutInSettings(tester);
    const message =
        'Anda sudah keluar. Sebagian data belum terhapus dari HP ini. Data '
        'itu dihapus saat aplikasi dibuka lagi.';
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    expect(await phone.tokens.read(), isNull);

    // Not shown a second time.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
  });

  testWidgets('ACC-13 a session the server ended shows "Silakan masuk lagi", '
      'then O2', (tester) async {
    final phone = newPhone();
    await pumpPhone(tester, server: server, phone: phone);
    await signInByPhone(tester);
    await createHousehold(tester, 'Ibu');

    server.intercept = (r) => switch (r.url.path) {
      '/v1/auth/refresh' => FakeServer.problem('refresh_token_invalid', 401),
      '/v1/account' => FakeServer.problem('access_token_expired', 401),
      _ => null,
    };
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Silakan masuk lagi'), findsOneWidget);
    expect(await phone.tokens.read(), isNull);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    // Back from O2 goes to O1, not to the signed-in screens.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  group('startup with a stored session (flow.md 5)', () {
    testWidgets('ACC-13 a cached household opens Beranda without a request', (
      tester,
    ) async {
      final phone = newPhone();
      await pumpPhone(tester, server: server, phone: phone);
      await signInByPhone(tester);
      await createHousehold(tester, 'Ibu');
      await closeApp(tester);
      server.requests.clear();

      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    testWidgets('ACC-13 without a cached household the household is looked '
        'up first', (tester) async {
      final phone = newPhone();
      await pumpPhone(tester, server: server, phone: phone);
      await signInByPhone(tester);
      await createHousehold(tester, 'Ibu');
      await closeApp(tester);
      await phone.db.clearUserData();

      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(server.count('GET', '/v1/household'), greaterThanOrEqualTo(1));
    });

    testWidgets('ACC-04 an account whose household was never created resumes '
        'at O3', (tester) async {
      final phone = newPhone();
      await pumpPhone(tester, server: server, phone: phone);
      await signInByPhone(tester);
      expect(find.byType(NameScreen), findsOneWidget);
      await closeApp(tester);

      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(NameScreen), findsOneWidget);
    });

    testWidgets('NFR-05 no answer while looking up the household: error and '
        '"Coba lagi"', (tester) async {
      final phone = newPhone();
      await pumpPhone(tester, server: server, phone: phone);
      await signInByPhone(tester);
      await createHousehold(tester, 'Ibu');
      await closeApp(tester);
      await phone.db.clearUserData();

      server.intercept = (r) => throw http.ClientException('offline');
      await pumpPhone(tester, server: server, phone: phone);
      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byKey(const Key('startup.error')), findsOneWidget);

      server.intercept = null;
      await tapKey(tester, 'startup.retry');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('O3 states (ACC-04)', () {
    Future<void> toNameScreen(WidgetTester tester) async {
      await pumpPhone(tester, server: server, phone: newPhone());
      await signInByPhone(tester);
      expect(find.byType(NameScreen), findsOneWidget);
    }

    testWidgets('ACC-04 household_exists after a lost answer loads the '
        'household and continues silently', (tester) async {
      await toNameScreen(tester);
      server.intercept = (r) {
        if (r.method != 'POST' || r.url.path != '/v1/household') return null;
        // The household is created, but the answer never arrives.
        server
          ..createHouseholdFor(server.accountFor(_phoneE164)!, 'Ibu')
          ..intercept = null;
        throw http.ClientException('connection reset');
      };
      await createHousehold(tester, 'Ibu');
      expect(find.byKey(const Key('name.offline')), findsOneWidget);

      await tapKey(tester, 'name.continue');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(server.count('GET', '/v1/household'), 1);
    });

    testWidgets('ACC-04 validation_failed shows the field error under the '
        'name', (tester) async {
      await toNameScreen(tester);
      server.intercept = (r) =>
          r.method == 'POST' && r.url.path == '/v1/household'
          ? FakeServer.problem(
              'validation_failed',
              400,
              extra: {
                'errors': [
                  {'pointer': '/managerProfile/name', 'code': 'too_long'},
                ],
              },
            )
          : null;
      await createHousehold(tester, 'Ibu');
      expect(
        find.text('Terlalu panjang. Paling banyak 30 huruf.'),
        findsOneWidget,
      );
      expect(find.byType(NameScreen), findsOneWidget);
    });

    testWidgets('ACC-04 NFR-05 without internet the name is kept and a retry '
        'reuses the same Idempotency-Key', (tester) async {
      await toNameScreen(tester);
      server.intercept = (r) => r.url.path == '/v1/household'
          ? throw http.ClientException('offline')
          : null;
      await createHousehold(tester, 'Ibu');
      expect(find.byKey(const Key('name.offline')), findsOneWidget);
      expect(find.text('Ibu'), findsOneWidget);

      server.intercept = null;
      await tapKey(tester, 'name.continue');
      expect(find.byType(HomeScreen), findsOneWidget);
      final keys = server.requests
          .where((r) => r.method == 'POST' && r.url.path == '/v1/household')
          .map((r) => r.headers['idempotency-key'])
          .toList();
      expect(keys, hasLength(2));
      expect(keys.first, keys.last);
    });

    testWidgets('ACC-04 a changed name gets a new Idempotency-Key', (
      tester,
    ) async {
      await toNameScreen(tester);
      server.intercept = (r) => r.url.path == '/v1/household'
          ? throw http.ClientException('offline')
          : null;
      await createHousehold(tester, 'Ibu');
      server.intercept = null;
      await createHousehold(tester, 'Mama Rina');
      final keys = server.requests
          .where((r) => r.method == 'POST' && r.url.path == '/v1/household')
          .map((r) => r.headers['idempotency-key'])
          .toList();
      expect(keys, hasLength(2));
      expect(keys.first, isNot(keys.last));
    });
  });

  testWidgets('ACC-01 DAT-08 no phone number, email or code reaches the logs '
      'or storage during sign-in', (tester) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      final phone = newPhone();
      await pumpPhone(tester, server: server, phone: phone);
      await tapKey(tester, 'welcome.haveAccount');
      await tapKey(tester, 'signIn.phone');
      await enterText(tester, 'contact.field', _phoneTyped);
      await tapKey(tester, 'contact.send');
      await enterText(tester, 'code.field', '000000');
      await enterText(tester, 'code.field', fixtureCode);
      await createHousehold(tester, 'Ibu');
      expect(find.byType(HomeScreen), findsOneWidget);

      const secrets = [
        '81234567890',
        '0812',
        fixtureCode,
        '000000',
        'nama@contoh.com',
      ];
      final settings = await phone.db.select(phone.db.settings).get();
      final stored = [
        ...logs,
        for (final row in settings) '${row.key}=${row.value}',
        jsonEncode((await phone.tokens.read())!.toJson()),
      ].join('\n');
      for (final secret in secrets) {
        expect(stored, isNot(contains(secret)), reason: secret);
      }
    } finally {
      debugPrint = original;
    }
  });
}
