import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/l10n/app_locale.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';
import 'package:keluargamakan/features/settings/settings_screen.dart';

import '../helpers/pump_app.dart';

Map<String, Object?> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

void main() {
  setUpAll(loadAppFonts);

  group('NFR-16 ACC-09 app language follows the device', () {
    testWidgets('NFR-16 Indonesian device shows Bahasa Indonesia', (
      tester,
    ) async {
      await pumpApp(tester, deviceLocale: const Locale('id', 'ID'));
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Resep'), findsOneWidget);
      expect(find.text('Masak apa hari ini?'), findsOneWidget);
    });

    testWidgets('NFR-16 English device shows English', (tester) async {
      await pumpApp(tester, deviceLocale: const Locale('en', 'US'));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('What to cook today?'), findsOneWidget);
      // Feature names stay in Bahasa Indonesia in English (copy deck rule).
      expect(find.text('Dapur Saya'), findsOneWidget);
    });

    testWidgets(
      'NFR-16 any other device language falls back to Bahasa Indonesia',
      (tester) async {
        await pumpApp(tester, deviceLocale: const Locale('ja', 'JP'));
        expect(find.text('Beranda'), findsOneWidget);
      },
    );

    test('NFR-16 locale resolution: English only for English devices', () {
      expect(
        AppLocales.resolve(const [Locale('en', 'GB')]),
        AppLocales.english,
      );
      expect(AppLocales.resolve(const [Locale('id')]), AppLocales.indonesian);
      expect(AppLocales.resolve(const [Locale('jv')]), AppLocales.indonesian);
      expect(AppLocales.resolve(const []), AppLocales.indonesian);
      expect(AppLocales.resolve(null), AppLocales.indonesian);
      expect(AppLocales.supported.first, AppLocales.indonesian);
    });
  });

  group('NFR-16 ACC-09 language switch in Settings', () {
    testWidgets('NFR-16 switching to English applies at once and is kept', (
      tester,
    ) async {
      final store = await pumpApp(tester);
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings.language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Applied immediately, sheet closed.
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(store.getString(PreferenceKeys.locale), 'en');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // A fresh start on an Indonesian device keeps the choice.
      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, store: store);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('NFR-16 switching back to Bahasa Indonesia', (tester) async {
      final store = await pumpApp(
        tester,
        store: InMemoryKeyValueStore({PreferenceKeys.locale: 'en'}),
      );
      expect(find.text('Home'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(store.getString(PreferenceKeys.locale), 'id');
    });
  });

  group('NFR-16 string catalog', () {
    test('NFR-16 Indonesian and English ARB files have the same keys', () {
      final id = _arb('app_id.arb');
      final en = _arb('app_en.arb');
      expect(id['@@locale'], 'id');
      expect(en['@@locale'], 'en');
      expect(_messageKeys(en).toSet(), _messageKeys(id).toSet());
      for (final key in _messageKeys(id)) {
        expect((id[key] as String).trim(), isNotEmpty, reason: 'id $key');
        expect((en[key] as String).trim(), isNotEmpty, reason: 'en $key');
        expect(id['@$key'], isA<Map<String, Object?>>(), reason: '@$key');
      }
    });

    test('NFR-16 no hard-coded UI text in lib/', () {
      // A string literal passed straight to a text-bearing widget or
      // property. All UI text must come from AppLocalizations.
      final literalText = RegExp(
        r'''(\bText\(|\bTooltip\(|tooltip:|label:|title:|subtitle:|hintText:|labelText:|helperText:|semanticsLabel:|semanticLabel:|message:)\s*(const\s+)?(Text\()?\s*['"]''',
      );
      final offenders = <String>[];
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.replaceAll(r'\', '/').contains('/generated/'));
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (literalText.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
