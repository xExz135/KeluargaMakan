import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';
import 'package:keluargamakan/core/cek_aman/safety_style.dart';
import 'package:keluargamakan/core/theme/app_theme.dart';
import 'package:keluargamakan/core/theme/theme_extensions.dart';
import 'package:keluargamakan/features/masak_apa_hari_ini/home_screen.dart';
import 'package:keluargamakan/features/settings/settings_screen.dart';

import '../helpers/pump_app.dart';

ThemeData themeOf(WidgetTester tester, Type screen) =>
    Theme.of(tester.element(find.byType(screen)));

/// Effective text scale of the rendered text [text].
double renderedScale(WidgetTester tester, String text) => tester
    .renderObject<RenderParagraph>(find.text(text).first)
    .textScaler
    .scale(1);

void main() {
  setUpAll(loadAppFonts);

  group('INT-05 light and dark themes', () {
    test('INT-05 ColorSchemes are built from tokens.json, no seed', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;
      // A sample of roles across the scheme; a seed-derived scheme would
      // not produce these exact values.
      expect(light.primary, const Color(0xFF047857));
      expect(light.secondaryContainer, const Color(0xFFE7E5E4));
      expect(light.tertiary, const Color(0xFF0E7490));
      expect(light.surface, const Color(0xFFFAFAF9));
      expect(light.surfaceContainer, const Color(0xFFF5F5F4));
      expect(light.surfaceContainerHigh, const Color(0xFFF0EFEE));
      expect(light.inverseSurface, const Color(0xFF292524));
      expect(light.error, const Color(0xFFB91C1C));
      expect(dark.primary, const Color(0xFF34D399));
      expect(dark.surface, const Color(0xFF0C0A09));
      expect(dark.surfaceContainerLowest, const Color(0xFF080706));
      expect(dark.surfaceContainer, const Color(0xFF1C1917));
      expect(dark.onSurface, const Color(0xFFF5F5F4));
      expect(dark.inversePrimary, const Color(0xFF065F46));
      for (final scheme in [light, dark]) {
        expect(scheme.surfaceTint, Colors.transparent);
      }
    });

    test('INT-05 themes use Material 3, the bundled font and the type '
        'scale', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(theme.visualDensity, VisualDensity.standard);
      final t = theme.textTheme;
      expect(t.bodyLarge?.fontFamily, 'PlusJakartaSans');
      expect(t.bodyLarge?.fontSize, 16);
      expect(t.labelLarge?.fontSize, 16);
      expect(t.headlineMedium?.fontWeight, FontWeight.w800);
      expect(t.titleSmall?.fontSize, 14);
      expect(t.bodySmall?.fontSize, 12);
      for (final style in [t.displayLarge, t.bodyMedium, t.labelSmall]) {
        expect(style?.letterSpacing, 0);
      }
    });

    test('INT-05 AppColors, AppText and AppSpacing are registered', () {
      for (final (theme, card, onDisabled) in [
        (AppTheme.light(), const Color(0xFFFFFFFF), const Color(0xFF6B6560)),
        (AppTheme.dark(), const Color(0xFF1C1917), const Color(0xFF8F8984)),
      ]) {
        final app = theme.extension<AppColors>()!;
        expect(app.card, card);
        expect(app.onDisabled, onDisabled);
        expect(app.avatarBackgrounds, hasLength(8));
        expect(theme.cardTheme.color, card);
        expect(theme.extension<AppText>()!.cookTimer.fontFeatures, isNotEmpty);
        expect(theme.extension<AppSpacing>(), isNotNull);
      }
    });

    test('NFR-15 disabled controls use disabledContainer and onDisabled', () {
      final theme = AppTheme.light();
      final app = theme.extension<AppColors>()!;
      const disabled = {WidgetState.disabled};
      final filled = theme.filledButtonTheme.style!;
      expect(filled.backgroundColor?.resolve(disabled), app.disabledContainer);
      expect(filled.foregroundColor?.resolve(disabled), app.onDisabled);
      expect(
        theme.outlinedButtonTheme.style!.foregroundColor?.resolve(disabled),
        app.onDisabled,
      );
      expect(
        theme.textButtonTheme.style!.foregroundColor?.resolve(disabled),
        app.onDisabled,
      );
      expect(theme.disabledColor, app.onDisabled);
    });

    test('INT-03 safety colors are registered, distinct and not the error '
        'red', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final safety = debugSafetyColors(theme);
        final error = theme.colorScheme.error;
        expect(safety['notSafeIcon'], isNot(error));
        expect(safety['notSafeBorder'], isNot(error));
        expect({
          safety['safeContainer'],
          safety['notSafeContainer'],
          safety['checkContainer'],
        }, hasLength(3));
        // Aman green is not the brand emerald (tokens.md 1.4).
        expect(safety['safeIcon'], isNot(theme.colorScheme.primary));
      }
      final light = debugSafetyColors(AppTheme.light());
      expect(light['onSafeContainer'], const Color(0xFF14532D));
      expect(light['onNotSafeContainer'], const Color(0xFF881337));
      expect(light['onCheckContainer'], const Color(0xFF78350F));
      expect(
        debugSafetyColors(AppTheme.dark())['onCheckContainer'],
        const Color(0xFFFDE68A),
      );
    });

    testWidgets('INT-05 the theme follows the system by default', (
      tester,
    ) async {
      await pumpApp(tester, platformBrightness: Brightness.dark);
      expect(themeOf(tester, HomeScreen).brightness, Brightness.dark);
      expect(
        themeOf(tester, HomeScreen).colorScheme.surface,
        const Color(0xFF0C0A09),
      );
    });

    testWidgets('INT-05 choosing Terang or Gelap in Settings applies and is '
        'kept', (tester) async {
      final store = await pumpApp(tester, platformBrightness: Brightness.dark);
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings.theme')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terang'));
      await tester.pumpAndSettle();
      expect(themeOf(tester, SettingsScreen).brightness, Brightness.light);
      expect(store.getString(PreferenceKeys.themeMode), 'light');

      await tester.tap(find.byKey(const Key('settings.theme')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(themeOf(tester, SettingsScreen).brightness, Brightness.dark);

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, store: store);
      expect(themeOf(tester, HomeScreen).brightness, Brightness.dark);
    });
  });

  group('INT-05 NFR-15 system font scaling to 200%', () {
    const cases = [
      (Locale('id'), TestWindows.phone, Brightness.light),
      (Locale('en'), TestWindows.phone, Brightness.dark),
      (Locale('id'), TestWindows.tablet, Brightness.dark),
      (Locale('en'), TestWindows.tablet, Brightness.light),
    ];
    for (final (locale, size, brightness) in cases) {
      testWidgets(
        'INT-05 NFR-15 every shell screen lays out at 200% without overflow '
        '(${locale.languageCode}, ${size.width.toInt()}dp, ${brightness.name})',
        (tester) async {
          await pumpApp(
            tester,
            deviceLocale: locale,
            size: size,
            textScale: 2.0,
            platformBrightness: brightness,
          );
          final isId = locale.languageCode == 'id';
          final tabs = isId
              ? ['Beranda', 'Dapur Saya', 'Resep', 'Keluarga']
              : ['Home', 'Dapur Saya', 'Recipes', 'Keluarga'];
          for (final tab in tabs) {
            await tapNav(tester, tab);
            expect(tester.takeException(), isNull, reason: tab);
          }

          // Not clamped: tab labels and titles render at the full 200%.
          expect(renderedScale(tester, tabs.first), 2.0);
          expect(renderedScale(tester, 'Keluarga Saya'), 2.0);

          await tapNav(tester, tabs.first);
          await tester.tap(find.byTooltip(isId ? 'Pengaturan' : 'Settings'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(renderedScale(tester, isId ? 'Pengaturan' : 'Settings'), 2.0);

          await tester.tap(find.byKey(const Key('settings.theme')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            renderedScale(tester, isId ? 'Ikuti sistem' : 'Follow system'),
            2.0,
          );
        },
      );
    }
  });
}
