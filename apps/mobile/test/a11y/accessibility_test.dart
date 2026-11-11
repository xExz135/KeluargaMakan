import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/theme/app_theme.dart';
import 'package:keluargamakan/core/theme/theme_extensions.dart';

import '../helpers/pump_app.dart';

/// Runs the tap-target guidelines named in accessibility.md 10. Contrast is
/// checked exactly from the tokens below: Flutter's textContrastGuideline
/// samples pixels and takes the most frequent dark pixel, which on thin text
/// is an anti-aliased edge (it read #8A8783 for #57534E text), so it reports
/// passing token pairs as failures.
Future<void> expectGuidelines(WidgetTester tester, String where) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// The screen title's text box sits fully inside its app bar.
void expectTitleInsideAppBar(WidgetTester tester, String title) {
  final text = find.descendant(
    of: find.byType(AppBar),
    matching: find.text(title),
  );
  final bar = find.ancestor(of: text, matching: find.byType(AppBar));
  final textRect = tester.getRect(text);
  final barRect = tester.getRect(bar);
  expect(textRect.top, greaterThanOrEqualTo(barRect.top), reason: title);
  expect(textRect.bottom, lessThanOrEqualTo(barRect.bottom), reason: title);
}

void main() {
  setUpAll(loadAppFonts);

  for (final brightness in Brightness.values) {
    for (final size in [TestWindows.phone, TestWindows.tablet]) {
      testWidgets(
        'NFR-15 shell screens meet the tap target and label guidelines '
        '(${brightness.name}, ${size.width.toInt()}dp)',
        (tester) async {
          // A phone-like pixel ratio, so the contrast check samples solid
          // glyph pixels rather than anti-aliased edges.
          await pumpApp(
            tester,
            platformBrightness: brightness,
            size: size,
            devicePixelRatio: 3.0,
          );
          for (final tab in ['Beranda', 'Dapur Saya', 'Resep', 'Keluarga']) {
            await tapNav(tester, tab);
            await expectGuidelines(tester, tab);
          }
          await tester.tap(find.byTooltip('Pengaturan'));
          await tester.pumpAndSettle();
          await expectGuidelines(tester, 'Pengaturan');
          await tester.tap(find.byKey(const Key('settings.theme')));
          await tester.pumpAndSettle();
          await expectGuidelines(tester, 'Tema sheet');
        },
      );
    }
  }

  for (final theme in [AppTheme.light(), AppTheme.dark()]) {
    test('NFR-15 text and background pairs used by the shell reach 4.5:1 '
        '(${theme.brightness.name})', () {
      final c = theme.colorScheme;
      final app = theme.extension<AppColors>()!;
      final pairs = {
        'body on surface': (c.onSurface, c.surface),
        'secondary text on surface': (c.onSurfaceVariant, c.surface),
        'nav label on navigation bar': (c.onSurfaceVariant, c.surfaceContainer),
        'selected nav label on navigation bar': (c.primary, c.surfaceContainer),
        'nav icon on indicator': (c.onPrimaryContainer, c.primaryContainer),
        'hero title on hero': (c.onPrimaryContainer, c.primaryContainer),
        'settings group header': (c.primary, c.surface),
        'sheet text on sheet': (c.onSurface, c.surfaceContainerLow),
        'sheet secondary text': (c.onSurfaceVariant, c.surfaceContainerLow),
        'text on card': (c.onSurface, app.card),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
      }
      // Disabled labels: our 3:1 rule (accessibility.md 4).
      expect(
        contrast(app.onDisabled, app.disabledContainer),
        greaterThanOrEqualTo(3.0),
      );
    });
  }

  testWidgets('NFR-15 at 200% long screen titles wrap inside the app bar', (
    tester,
  ) async {
    await pumpApp(tester, textScale: 2.0);
    await tapNav(tester, 'Keluarga');
    expectTitleInsideAppBar(tester, 'Keluarga Saya');
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    expectTitleInsideAppBar(tester, 'Pengaturan');
    expect(tester.takeException(), isNull);
  });
}
