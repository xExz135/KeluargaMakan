// Navigation labels shrink to fit their slot at large text sizes instead of
// breaking mid-word (owner decision 2026-11-11).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/app/shell/bottom_navigation.dart';

import '../helpers/pump_app.dart';

const _labels = {
  'id': ['Beranda', 'Dapur Saya', 'Resep', 'Keluarga'],
  'en': ['Home', 'Dapur Saya', 'Recipes', 'Keluarga'],
};

/// Pixel 8 width, where "Berand / a" was seen on the emulator.
const _pixel8 = Size(411, 914);

/// A medium window (navigation rail, not the expanded tablet).
const _medium = Size(700, 1000);

Finder _navBar() => find.byWidgetPredicate(
  (w) => w is AppBottomNavigation || w is NavigationRail,
);

Finder _navLabel(String label) =>
    find.descendant(of: _navBar(), matching: find.text(label));

/// Number of visual lines the paragraph [label] is laid out on.
int _lines(RenderParagraph p) {
  final length = p.text.toPlainText().length;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

/// The tappable slot of a bottom-bar destination, or the whole rail.
Rect _slot(WidgetTester tester, Finder label) {
  final inkWell = find.ancestor(of: label, matching: find.byType(InkWell));
  if (inkWell.evaluate().isNotEmpty) return tester.getRect(inkWell.first);
  return tester.getRect(find.byType(NavigationRail));
}

void _expectLabelsFit(
  WidgetTester tester,
  List<String> labels, {
  required double textScale,
}) {
  for (final label in labels) {
    final finder = _navLabel(label);
    expect(finder, findsOneWidget, reason: label);
    final paragraph = tester.renderObject<RenderParagraph>(finder);

    // One line, so no mid-word break, and nothing cut off.
    expect(_lines(paragraph), 1, reason: '$label wraps');
    expect(paragraph.didExceedMaxLines, isFalse, reason: '$label cut off');

    // Inside its slot.
    final rect = tester.getRect(finder);
    final slot = _slot(tester, finder);
    expect(rect.left, greaterThanOrEqualTo(slot.left - 0.5), reason: label);
    expect(rect.right, lessThanOrEqualTo(slot.right + 0.5), reason: label);

    // Readable: shrinks only as far as needed, never below the user's
    // 100% size, and never larger than the system size.
    final scale = paragraph.textScaler.scale(1);
    expect(scale, lessThanOrEqualTo(textScale + 1e-9), reason: label);
    expect(scale, greaterThanOrEqualTo(1.0), reason: '$label too small');

    // TalkBack reads the full label.
    expect(tester.getSemantics(finder).label, contains(label), reason: label);
  }
}

void main() {
  setUpAll(loadAppFonts);

  for (final lang in ['id', 'en']) {
    for (final (name, size) in [
      ('phone 360dp', TestWindows.phone),
      ('Pixel 8 411dp', _pixel8),
      ('medium 700dp', _medium),
      ('tablet 1280dp', TestWindows.tablet),
    ]) {
      testWidgets('INT-05 NFR-15 at 200% nav labels fit on one line without a '
          'mid-word break ($lang, $name)', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(
          tester,
          deviceLocale: Locale(lang),
          size: size,
          textScale: 2.0,
        );
        _expectLabelsFit(tester, _labels[lang]!, textScale: 2.0);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }

    testWidgets('INT-05 at 100% nav labels keep the full system size ($lang)', (
      tester,
    ) async {
      await pumpApp(tester, deviceLocale: Locale(lang));
      for (final label in _labels[lang]!) {
        final paragraph = tester.renderObject<RenderParagraph>(
          _navLabel(label),
        );
        expect(paragraph.textScaler.scale(1), 1.0, reason: label);
        expect(_lines(paragraph), 1, reason: label);
      }
    });
  }

  testWidgets('INT-05 bottom labels share one size that does not change '
      'when switching tabs', (tester) async {
    await pumpApp(tester, size: _pixel8, textScale: 2.0);
    double scaleOf(String label) => tester
        .renderObject<RenderParagraph>(_navLabel(label))
        .textScaler
        .scale(1);
    final labels = _labels['id']!;
    final shared = scaleOf(labels.first);
    expect(shared, lessThan(2.0)); // "Dapur Saya" needs to shrink here.
    for (final label in labels) {
      expect(scaleOf(label), shared, reason: label);
    }
    await tapNav(tester, 'Dapur Saya');
    for (final label in labels) {
      expect(scaleOf(label), shared, reason: '$label after switching');
    }
  });

  testWidgets('INT-05 the tablet rail keeps nav labels at the full 200%', (
    tester,
  ) async {
    await pumpApp(tester, size: TestWindows.tablet, textScale: 2.0);
    for (final label in _labels['id']!) {
      final paragraph = tester.renderObject<RenderParagraph>(_navLabel(label));
      expect(paragraph.textScaler.scale(1), 2.0, reason: label);
    }
  });

  testWidgets('INT-02 INT-05 five sections (V2 Plan) still fit at 200% on a '
      '360dp phone', (tester) async {
    await pumpApp(tester, textScale: 2.0, config: {'nav.planTabEnabled': true});
    for (final label in [..._labels['id']!, 'Rencana']) {
      final finder = _navLabel(label);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(_lines(paragraph), 1, reason: label);
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      final rect = tester.getRect(finder);
      final slot = _slot(tester, finder);
      expect(rect.left, greaterThanOrEqualTo(slot.left - 0.5), reason: label);
      expect(rect.right, lessThanOrEqualTo(slot.right + 0.5), reason: label);
    }
    expect(tester.takeException(), isNull);
  });
}
