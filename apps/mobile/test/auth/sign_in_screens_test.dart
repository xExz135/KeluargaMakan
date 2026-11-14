// ACC-01, ACC-02, ACC-09, INT-13: the welcome, sign-in, number or email and
// code screens, each state from contract-alignment.md 5. Fake API only.
// TEST FIXTURE: not real safety or nutrition data. Contacts and codes are
// invented.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/storage/key_value_store.dart';
import 'package:keluargamakan/features/auth/code_entry_screen.dart';
import 'package:keluargamakan/features/auth/contact_entry_screen.dart';
import 'package:keluargamakan/features/auth/google_id_token.dart';
import 'package:keluargamakan/features/auth/name_screen.dart';
import 'package:keluargamakan/features/auth/sign_in_screen.dart';
import 'package:keluargamakan/features/auth/welcome_screen.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';

const _phoneTyped = '0812 3456 7890';
const _phoneE164 = '+6281234567890';

Map<String, Object?> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, Object?>;

http.Request _last(FakeServer server, String path) =>
    server.requests.lastWhere((r) => r.url.path == path);

/// O1 → O2 → O2a phone.
Future<void> openPhone(WidgetTester tester) async {
  await tapKey(tester, 'welcome.start');
  await tapKey(tester, 'signIn.phone');
}

/// O1 → O2 → O2a phone → O2b.
Future<void> openCode(WidgetTester tester) async {
  await openPhone(tester);
  await enterText(tester, 'contact.field', _phoneTyped);
  await tapKey(tester, 'contact.send');
}

final class _FakeGoogle implements GoogleIdTokenSource {
  _FakeGoogle(this.result);

  final GoogleIdTokenResult result;

  @override
  Future<GoogleIdTokenResult> requestIdToken() async => result;
}

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  late TestPhone phone;

  setUp(() {
    server = FakeServer();
    phone = TestPhone();
  });
  tearDown(() => phone.db.close());

  group('O1 welcome and language (ACC-09)', () {
    testWidgets('ACC-09 without a session the app opens on O1 in Bahasa '
        'Indonesia, even on an English phone', (tester) async {
      await pumpPhone(
        tester,
        server: server,
        phone: phone,
        deviceLocale: const Locale('en', 'US'),
      );
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Masak apa hari ini?'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    testWidgets('ACC-09 picking English switches all text at once and is '
        'kept on this phone', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await tester.tap(find.byKey(const Key('language.en')));
      await tester.pumpAndSettle();
      expect(find.text('What to cook today?'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Already have an account? Sign in'), findsOneWidget);
      expect(phone.store.getString(PreferenceKeys.locale), 'en');

      await closeApp(tester);
      await pumpPhone(tester, server: server, phone: phone);
      expect(find.text('Get started'), findsOneWidget);

      await tester.tap(find.byKey(const Key('language.id')));
      await tester.pumpAndSettle();
      expect(find.text('Mulai'), findsOneWidget);
      expect(phone.store.getString(PreferenceKeys.locale), 'id');
    });

    testWidgets('ACC-09 at large text the language choice is a radio list '
        'with the same effect', (tester) async {
      await pumpPhone(tester, server: server, phone: phone, textScale: 2.0);
      expect(find.byType(RadioListTile<Locale>), findsNWidgets(2));
      await tapKey(tester, 'language.en');
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ACC-01 "Mulai" and "Sudah punya akun? Masuk" both open O2', (
      tester,
    ) async {
      await pumpPhone(tester, server: server, phone: phone);
      await tapKey(tester, 'welcome.start');
      expect(find.byType(SignInScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tapKey(tester, 'welcome.haveAccount');
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('INT-02 Android back on O1 leaves the app', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      final handled = await tester.binding.handlePopRoute();
      expect(handled, isFalse);
    });
  });

  group('O2 sign in (ACC-01, ACC-02, INT-13)', () {
    testWidgets('ACC-02 INT-13 the Google button is hidden by default; '
        'phone and email are offered', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await tapKey(tester, 'welcome.start');
      expect(find.text('Simpan dapur Anda'), findsOneWidget);
      expect(find.text('Lanjut dengan Google'), findsNothing);
      expect(find.text('Pakai nomor HP'), findsOneWidget);
      expect(find.text('Pakai email'), findsOneWidget);
    });

    testWidgets('ACC-02 INT-13 with the flag on, Google that cannot run here '
        'says so and moves focus to "Pakai nomor HP"', (tester) async {
      await pumpPhone(
        tester,
        server: server,
        phone: phone,
        config: {'auth.googleSignInEnabled': true},
      );
      await tapKey(tester, 'welcome.start');
      await tapKey(tester, 'signIn.google');
      expect(
        find.text(
          'Masuk dengan Google sedang tidak tersedia. Pakai nomor HP atau '
          'email.',
        ),
        findsOneWidget,
      );
      final phoneButton = tester.widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const Key('signIn.phone')),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(phoneButton.focusNode!.hasFocus, isTrue);
      expect(server.requests, isEmpty);
    });

    testWidgets('ACC-02 INT-13 with the flag on, a Google answer of 503 '
        'sign_in_method_unavailable offers phone or email', (tester) async {
      await pumpPhone(
        tester,
        server: server,
        phone: phone,
        config: {'auth.googleSignInEnabled': true},
        google: _FakeGoogle(const GoogleIdToken('fixture-id-token')),
      );
      await tapKey(tester, 'welcome.start');
      await tapKey(tester, 'signIn.google');
      expect(server.count('POST', '/v1/auth/google'), 1);
      expect(
        find.textContaining('Masuk dengan Google sedang tidak tersedia'),
        findsOneWidget,
      );
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('ACC-02 a rejected Google token keeps the user on O2', (
      tester,
    ) async {
      server.intercept = (r) => r.url.path == '/v1/auth/google'
          ? FakeServer.problem('google_token_invalid', 401)
          : null;
      await pumpPhone(
        tester,
        server: server,
        phone: phone,
        config: {'auth.googleSignInEnabled': true},
        google: _FakeGoogle(const GoogleIdToken('fixture-id-token')),
      );
      await tapKey(tester, 'welcome.start');
      await tapKey(tester, 'signIn.google');
      expect(
        find.textContaining('Masuk dengan Google belum berhasil'),
        findsOneWidget,
      );
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('ACC-02 closing the Google sheet changes nothing', (
      tester,
    ) async {
      await pumpPhone(
        tester,
        server: server,
        phone: phone,
        config: {'auth.googleSignInEnabled': true},
        google: _FakeGoogle(const GoogleSignInCancelled()),
      );
      await tapKey(tester, 'welcome.start');
      await tapKey(tester, 'signIn.google');
      expect(find.byType(SnackBar), findsNothing);
      expect(server.requests, isEmpty);
    });
  });

  group('O2a number or email (ACC-01)', () {
    testWidgets('ACC-01 a phone number typed as "08…" is sent as +62 E.164 '
        'with the app language', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openPhone(tester);
      expect(find.byType(ContactEntryScreen), findsOneWidget);
      expect(find.text('+62 '), findsOneWidget);
      expect(find.text('Contoh: 0812 3456 7890'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('contact.field')),
      );
      expect(field.keyboardType, TextInputType.phone);
      expect(field.autofillHints, [AutofillHints.telephoneNumberNational]);

      await enterText(tester, 'contact.field', _phoneTyped);
      await tapKey(tester, 'contact.send');

      final body = _body(_last(server, '/v1/auth/code/request'));
      expect(body, {
        'channel': 'phone',
        'destination': _phoneE164,
        'language': 'id',
      });
      expect(find.byType(CodeEntryScreen), findsOneWidget);
      expect(
        find.text('Kami kirim kode 6 angka ke 0812 •••• 7890.'),
        findsOneWidget,
      );
    });

    testWidgets('ACC-01 ACC-09 the code message is asked for in English '
        'when the app is in English', (tester) async {
      await phone.store.setString(PreferenceKeys.locale, 'en');
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      expect(_body(_last(server, '/v1/auth/code/request'))['language'], 'en');
      expect(
        find.text('We sent a 6-digit code to 0812 •••• 7890.'),
        findsOneWidget,
      );
    });

    testWidgets('ACC-01 a number that is not Indonesian shows the example '
        'and sends nothing', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openPhone(tester);
      await enterText(tester, 'contact.field', '021 555');
      await tapKey(tester, 'contact.send');
      expect(
        find.text(
          'Nomor HP belum benar. Contoh: 0812 3456 7890',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(server.requests, isEmpty);
    });

    testWidgets('ACC-01 email: email keyboard and autofill, wrong addresses '
        'are caught, a good one gets a code', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await tapKey(tester, 'welcome.start');
      await tapKey(tester, 'signIn.email');
      final field = tester.widget<TextField>(
        find.byKey(const Key('contact.field')),
      );
      expect(field.keyboardType, TextInputType.emailAddress);
      expect(field.autofillHints, [AutofillHints.email]);

      await enterText(tester, 'contact.field', 'nama@');
      await tapKey(tester, 'contact.send');
      expect(
        find.text('Email belum benar. Contoh: nama@contoh.com'),
        findsOneWidget,
      );
      expect(server.requests, isEmpty);

      await enterText(tester, 'contact.field', ' nama@contoh.com ');
      await tapKey(tester, 'contact.send');
      expect(_body(_last(server, '/v1/auth/code/request')), {
        'channel': 'email',
        'destination': 'nama@contoh.com',
        'language': 'id',
      });
      expect(find.textContaining('n•••@contoh.com'), findsOneWidget);
    });

    testWidgets('ACC-01 a 429 shows the wait from Retry-After and disables '
        '"Kirim kode" until it is over', (tester) async {
      server.intercept = (r) => r.url.path == '/v1/auth/code/request'
          ? FakeServer.problem(
              'rate_limited',
              429,
              headers: {'retry-after': '120'},
            )
          : null;
      await pumpPhone(tester, server: server, phone: phone);
      await openPhone(tester);
      await enterText(tester, 'contact.field', _phoneTyped);
      await tapKey(tester, 'contact.send');

      expect(
        find.text('Terlalu banyak percobaan. Coba lagi dalam 2 menit.'),
        findsOneWidget,
      );
      FilledButton send() => tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('contact.send')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(send().onPressed, isNull);

      await tester.pump(const Duration(seconds: 61));
      expect(
        find.text('Terlalu banyak percobaan. Coba lagi dalam 1 menit.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(send().onPressed, isNotNull);
      expect(find.textContaining('Terlalu banyak percobaan'), findsNothing);
    });

    testWidgets('ACC-01 Q16 503 sign_in_method_unavailable shows that sign-in '
        'by code is not available yet', (tester) async {
      server.intercept = (r) => r.url.path == '/v1/auth/code/request'
          ? FakeServer.problem('sign_in_method_unavailable', 503)
          : null;
      await pumpPhone(tester, server: server, phone: phone);
      await openPhone(tester);
      await enterText(tester, 'contact.field', _phoneTyped);
      await tapKey(tester, 'contact.send');
      expect(find.text('Masuk dengan kode belum tersedia'), findsOneWidget);
      expect(
        find.text(
          'Kami belum bisa mengirim kode lewat SMS atau email. Coba lagi '
          'nanti.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ContactEntryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ACC-01 a build without an API shows the same "not available '
        'yet" state and sends nothing', (tester) async {
      await pumpPhone(tester, server: server, phone: phone, baseUrl: '');
      await openPhone(tester);
      await enterText(tester, 'contact.field', _phoneTyped);
      await tapKey(tester, 'contact.send');
      expect(find.byKey(const Key('signIn.unavailable')), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    testWidgets('ACC-01 NFR-05 no internet: the number is kept and the '
        'message says to connect', (tester) async {
      server.intercept = (r) => throw http.ClientException('offline');
      await pumpPhone(tester, server: server, phone: phone);
      await openPhone(tester);
      await enterText(tester, 'contact.field', _phoneTyped);
      await tapKey(tester, 'contact.send');
      expect(
        find.text('Butuh internet untuk mendaftar. Sambungkan lalu coba lagi.'),
        findsOneWidget,
      );
      expect(find.text(_phoneTyped), findsOneWidget);
    });

    testWidgets('INT-02 Android back from O2a returns to O2', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openPhone(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('O2b code (ACC-01)', () {
    testWidgets('ACC-01 the code field is one autofill control with a '
        'one-time-code hint that is not learned or restored', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      final field = tester.widget<TextField>(
        find.byKey(const Key('code.field')),
      );
      expect(field.autofillHints, [AutofillHints.oneTimeCode]);
      expect(field.keyboardType, TextInputType.number);
      expect(field.enableIMEPersonalizedLearning, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.autocorrect, isFalse);
      expect(field.restorationId, isNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Kode, 6 angka')),
        isSemantics(label: 'Kode, 6 angka', isTextField: true),
      );
      // The boxes are drawing only: one control for TalkBack.
      expect(find.bySemanticsLabel(RegExp('Kode')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('NFR-15 an 8-digit code fits a 360dp phone at 200% in both '
        'languages', (tester) async {
      for (final lang in ['id', 'en']) {
        final eight = FakeServer(codeLength: 8)..code = '12345678';
        final p = TestPhone();
        await p.store.setString(PreferenceKeys.locale, lang);
        await pumpPhone(tester, server: eight, phone: p, textScale: 2.0);
        await openCode(tester);
        expect(tester.takeException(), isNull, reason: lang);
        expect(find.bySemanticsLabel(RegExp('8')), findsWidgets);
        await enterText(tester, 'code.field', '12345678');
        expect(find.byType(NameScreen), findsOneWidget, reason: lang);
        await closeApp(tester);
        await p.db.close();
      }
    });

    testWidgets('ACC-01 the last digit submits; a correct code signs in', (
      tester,
    ) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      await enterText(tester, 'code.field', fixtureCode);
      expect(_body(_last(server, '/v1/auth/code/verify'))['code'], fixtureCode);
      // A new account has no household yet: O3.
      expect(find.byType(NameScreen), findsOneWidget);
      expect(await phone.tokens.read(), isNotNull);
    });

    testWidgets('ACC-01 a wrong code clears the boxes and asks again', (
      tester,
    ) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      await enterText(tester, 'code.field', '000000');
      expect(find.text('Kodenya belum cocok. Coba lagi.'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('code.field')),
      );
      expect(field.controller!.text, isEmpty);
      expect(field.enabled, isTrue);

      await enterText(tester, 'code.field', fixtureCode);
      expect(find.byType(NameScreen), findsOneWidget);
    });

    testWidgets('ACC-01 too many wrong codes lock the boxes until a new code '
        'is requested', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      for (var i = 0; i < 3; i++) {
        await enterText(tester, 'code.field', '000000');
      }
      expect(
        find.text('Kode salah terlalu sering. Minta kode baru.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byKey(const Key('code.field'))).enabled,
        isFalse,
      );

      await tapKey(tester, 'code.resend');
      expect(server.count('POST', '/v1/auth/code/request'), 2);
      expect(
        tester.widget<TextField>(find.byKey(const Key('code.field'))).enabled,
        isTrue,
      );
      await enterText(tester, 'code.field', fixtureCode);
      expect(find.byType(NameScreen), findsOneWidget);
    });

    testWidgets('ACC-01 an expired code locks the boxes and offers "Kirim '
        'ulang"', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      server.intercept = (r) => r.url.path == '/v1/auth/code/verify'
          ? FakeServer.problem('code_expired', 400)
          : null;
      await enterText(tester, 'code.field', fixtureCode);
      expect(
        find.text('Kodenya sudah kedaluwarsa. Minta kode baru.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byKey(const Key('code.field'))).enabled,
        isFalse,
      );
      expect(find.text('Kirim ulang'), findsOneWidget);
    });

    testWidgets('ACC-01 "Kirim ulang" counts down to resendAvailableAt, then '
        'sends a new code', (tester) async {
      server.resendAfterSeconds = 60;
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      expect(find.text('Kirim ulang dalam 60 detik'), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
      expect(find.text('Kirim ulang dalam 45 detik'), findsOneWidget);
      await tester.tap(find.byKey(const Key('code.resend')));
      await tester.pump();
      expect(server.count('POST', '/v1/auth/code/request'), 1);

      await tester.pump(const Duration(seconds: 46));
      await tester.pumpAndSettle();
      expect(find.text('Kirim ulang'), findsOneWidget);
      await tapKey(tester, 'code.resend');
      expect(server.count('POST', '/v1/auth/code/request'), 2);
      expect(
        _body(_last(server, '/v1/auth/code/request'))['destination'],
        _phoneE164,
      );
    });

    testWidgets('ACC-01 a 429 on verify blocks the boxes and "Kirim ulang" '
        'for the Retry-After wait', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      server.intercept = (r) => r.url.path == '/v1/auth/code/verify'
          ? FakeServer.problem(
              'rate_limited',
              429,
              extra: {'retryAfterSeconds': 300},
            )
          : null;
      await enterText(tester, 'code.field', fixtureCode);
      expect(
        find.text('Terlalu banyak percobaan. Coba lagi dalam 5 menit.'),
        findsOneWidget,
      );
      expect(find.text('Kirim ulang dalam 5 menit'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('code.field'))).enabled,
        isFalse,
      );

      await tester.pump(const Duration(minutes: 5, seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Kirim ulang'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('code.field'))).enabled,
        isTrue,
      );
    });

    testWidgets('ACC-01 a 429 on resend disables "Kirim ulang" and keeps the '
        'boxes usable', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      server.intercept = (r) => r.url.path == '/v1/auth/code/request'
          ? FakeServer.problem(
              'rate_limited',
              429,
              headers: {'retry-after': '30'},
            )
          : null;
      await tapKey(tester, 'code.resend');
      expect(find.text('Kirim ulang dalam 30 detik'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('code.field'))).enabled,
        isTrue,
      );
    });

    testWidgets('ACC-01 a 503 on verify keeps the digits for "Lanjut"', (
      tester,
    ) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      server.intercept = (r) => r.url.path == '/v1/auth/code/verify'
          ? FakeServer.problem('service_unavailable', 503)
          : null;
      await enterText(tester, 'code.field', fixtureCode);
      expect(find.text('Ada kendala'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('code.field')))
            .controller!
            .text,
        fixtureCode,
      );
      server.intercept = null;
      await tapKey(tester, 'code.continue');
      expect(find.byType(NameScreen), findsOneWidget);
    });

    testWidgets('ACC-01 NFR-05 no internet on verify keeps the digits', (
      tester,
    ) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      server.intercept = (r) => throw http.ClientException('offline');
      await enterText(tester, 'code.field', fixtureCode);
      expect(find.byKey(const Key('signIn.offline')), findsOneWidget);
      expect(find.byType(CodeEntryScreen), findsOneWidget);
    });

    testWidgets('ACC-01 "Ganti nomor atau email" and Android back return to '
        'O2a with the number kept', (tester) async {
      await pumpPhone(tester, server: server, phone: phone);
      await openCode(tester);
      await tapKey(tester, 'code.change');
      expect(find.byType(ContactEntryScreen), findsOneWidget);
      expect(find.text(_phoneTyped), findsOneWidget);

      await tapKey(tester, 'contact.send');
      expect(find.byType(CodeEntryScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ContactEntryScreen), findsOneWidget);
    });
  });
}
