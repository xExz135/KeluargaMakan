import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/app/shell/app_section.dart';
import 'package:keluargamakan/app/shell/bottom_navigation.dart';
import 'package:keluargamakan/core/config/app_config.dart';
import 'package:keluargamakan/features/dapur_saya/dapur_saya_screen.dart';
import 'package:keluargamakan/features/keluarga_saya/keluarga_saya_screen.dart';
import 'package:keluargamakan/features/masak_apa_hari_ini/home_screen.dart';
import 'package:keluargamakan/features/rencana_mingguan/plan_screen.dart';
import 'package:keluargamakan/features/resep/recipes_screen.dart';
import 'package:keluargamakan/features/settings/settings_screen.dart';

import '../helpers/pump_app.dart';

/// Labels of the bottom bar, left to right.
List<String> bottomLabels(WidgetTester tester) {
  final texts = find.descendant(
    of: find.byType(AppBottomNavigation),
    matching: find.byType(Text),
  );
  final widgets = texts.evaluate().toList()
    ..sort(
      (a, b) => tester
          .getTopLeft(find.byWidget(a.widget))
          .dx
          .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dx),
    );
  return [for (final e in widgets) (e.widget as Text).data!];
}

void main() {
  setUpAll(loadAppFonts);

  group('INT-02 navigation sections', () {
    testWidgets('INT-02 V1 shows four sections in order and hides Plan', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(bottomLabels(tester), [
        'Beranda',
        'Dapur Saya',
        'Resep',
        'Keluarga',
      ]);
      expect(find.text('Rencana'), findsNothing);
    });

    test('INT-02 Plan stays hidden with local defaults', () {
      expect(AppSection.visible(const AppConfig()), [
        AppSection.home,
        AppSection.kitchen,
        AppSection.recipes,
        AppSection.family,
      ]);
    });

    testWidgets(
      'INT-02 with nav.planTabEnabled there are at most five sections and Plan '
      'sits between Resep and Keluarga',
      (tester) async {
        await pumpApp(tester, config: {'nav.planTabEnabled': true});
        final labels = bottomLabels(tester);
        expect(labels.length, lessThanOrEqualTo(AppSection.maxSections));
        expect(labels, [
          'Beranda',
          'Dapur Saya',
          'Resep',
          'Rencana',
          'Keluarga',
        ]);
        await tapNav(tester, 'Rencana');
        expect(find.byType(PlanScreen), findsOneWidget);
      },
    );

    testWidgets('INT-02 each tab opens its root screen', (tester) async {
      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tapNav(tester, 'Dapur Saya');
      expect(find.byType(DapurSayaScreen), findsOneWidget);

      await tapNav(tester, 'Resep');
      expect(find.byType(RecipesScreen), findsOneWidget);

      await tapNav(tester, 'Keluarga');
      expect(find.byType(KeluargaSayaScreen), findsOneWidget);
      expect(find.text('Keluarga Saya'), findsOneWidget);

      await tapNav(tester, 'Beranda');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('INT-01 Beranda leads with "Masak apa hari ini?"', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('Masak apa hari ini?'), findsOneWidget);
      // The hero spans the content width inside the 16dp phone gutters.
      final hero = find
          .ancestor(
            of: find.text('Masak apa hari ini?'),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getRect(hero).left, 16);
      expect(tester.getSize(hero).width, TestWindows.phone.width - 32);
    });

    testWidgets('INT-02 back from a non-Home tab root returns to Beranda', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapNav(tester, 'Resep');
      expect(find.byType(RecipesScreen), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RecipesScreen), findsNothing);
    });

    testWidgets('INT-02 back from Settings returns to the tab it came from', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapNav(tester, 'Dapur Saya');
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DapurSayaScreen), findsOneWidget);
    });

    testWidgets('INT-02 Settings opens from every tab root on phones', (
      tester,
    ) async {
      await pumpApp(tester);
      for (final label in ['Beranda', 'Dapur Saya', 'Resep', 'Keluarga']) {
        await tapNav(tester, label);
        await tester.tap(find.byTooltip('Pengaturan'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget, reason: label);
        expect(find.byType(BackButton), findsOneWidget, reason: label);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
      'INT-02 tablets use a navigation rail with labels and Settings at the '
      'bottom',
      (tester) async {
        await pumpApp(tester, size: TestWindows.tablet);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(AppBottomNavigation), findsNothing);
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.destinations, hasLength(4));
        expect(rail.labelType, NavigationRailLabelType.all);

        // One Settings button: in the rail, not repeated in the app bar.
        expect(find.byTooltip('Pengaturan'), findsOneWidget);
        await tester.tap(find.byTooltip('Pengaturan'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
      },
    );
  });

  testWidgets(
    'SAF-02 shell placeholders show no Cek Aman state on any screen',
    (tester) async {
      const stateWords = [
        'Aman',
        'Tidak aman',
        'Cek label',
        'Safe',
        'Not safe',
      ];
      for (final locale in const [Locale('id'), Locale('en')]) {
        await pumpApp(tester, deviceLocale: locale);
        final labels = bottomLabels(tester);
        for (final label in labels) {
          await tapNav(tester, label);
          for (final word in stateWords) {
            expect(find.text(word), findsNothing, reason: '$label: $word');
            expect(
              find.textContaining(word, findRichText: true),
              findsNothing,
              reason: '$label: $word',
            );
          }
        }
      }
    },
  );
}
