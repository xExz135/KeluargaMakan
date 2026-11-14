// NFR-15, INT-05, NFR-16: every T-027 screen and its main states at 200%
// text, in both languages, on a phone and a tablet, light and dark: no
// overflow, 48dp tap targets, a label on everything tappable.
// TEST FIXTURE: not real safety or nutrition data.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/storage/key_value_store.dart';
import 'package:keluargamakan/features/auth/startup_screen.dart';

import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';

Future<void> _check(WidgetTester tester, String where) async {
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
  handle.dispose();
}

Future<void> _walk(
  WidgetTester tester, {
  required String lang,
  required Size size,
  required Brightness brightness,
  required double textScale,
}) async {
  final server = FakeServer();
  final phone = TestPhone();
  addTearDown(phone.db.close);
  await phone.store.setString(PreferenceKeys.locale, lang);
  final settingsTooltip = lang == 'id' ? 'Pengaturan' : 'Settings';

  Future<void> pump() => pumpPhone(
    tester,
    server: server,
    phone: phone,
    size: size,
    platformBrightness: brightness,
    textScale: textScale,
    config: {'auth.googleSignInEnabled': true},
  );

  await pump();
  await _check(tester, 'O1');

  await tapKey(tester, 'welcome.start');
  await _check(tester, 'O2');

  await tapKey(tester, 'signIn.email');
  await enterText(tester, 'contact.field', 'nama@');
  await tapKey(tester, 'contact.send');
  await _check(tester, 'O2a email, invalid');
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();

  await tapKey(tester, 'signIn.phone');
  server.intercept = (r) =>
      FakeServer.problem('sign_in_method_unavailable', 503);
  await enterText(tester, 'contact.field', '0812 3456 7890');
  await tapKey(tester, 'contact.send');
  await _check(tester, 'O2a phone, unavailable');

  server.intercept = null;
  await tapKey(tester, 'contact.send');
  await _check(tester, 'O2b');
  await enterText(tester, 'code.field', '000000');
  await _check(tester, 'O2b, wrong code');

  await enterText(tester, 'code.field', fixtureCode);
  await _check(tester, 'O3');
  server.intercept = (r) => throw http.ClientException('offline');
  await enterText(tester, 'name.field', 'Mama Rina');
  await tapKey(tester, 'name.continue');
  await _check(tester, 'O3, no internet');

  server.intercept = null;
  await tapKey(tester, 'name.continue');
  await tester.tap(find.byTooltip(settingsTooltip));
  await tester.pumpAndSettle();
  await _check(tester, 'Settings with Akun');
  await tapKey(tester, 'settings.signOut');
  await _check(tester, 'Sign-out dialog');
  await tapKey(tester, 'settings.signOut.cancel');

  await closeApp(tester);
  await phone.db.clearUserData();
  server.intercept = (r) => throw http.ClientException('offline');
  await pump();
  expect(find.byType(StartupScreen), findsOneWidget);
  await _check(tester, 'Startup error');
}

void main() {
  setUpAll(loadAppFonts);

  for (final lang in ['id', 'en']) {
    for (final size in [TestWindows.phone, TestWindows.tablet]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'NFR-15 INT-05 sign-in screens at 200% ($lang, '
          '${size.width.toInt()}dp, ${brightness.name})',
          (tester) => _walk(
            tester,
            lang: lang,
            size: size,
            brightness: brightness,
            textScale: 2.0,
          ),
        );
      }
    }
  }

  testWidgets('NFR-15 sign-in screens at 100% (id, phone, light)', (tester) {
    return _walk(
      tester,
      lang: 'id',
      size: TestWindows.phone,
      brightness: Brightness.light,
      textScale: 1.0,
    );
  });
}
