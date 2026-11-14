// NFR-15 INT-05 Keluarga Saya at 200% text: every new screen in both
// languages, on a phone and a tablet, light and dark, without overflow,
// with 48 dp targets and labeled controls.
// TEST FIXTURE: not real safety or nutrition data.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'family_test_helpers.dart';

Future<void> _guidelines(WidgetTester tester, String where) async {
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

/// Scrolls every list on screen to its end, so every section is laid out
/// at 200% (an overflow there throws). Tap targets are checked at the top:
/// the guideline also measures rows cut off by the scroll edge.
Future<void> _scrollToEndWithoutOverflow(
  WidgetTester tester,
  String where,
) async {
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.axis == Axis.vertical) {
      position.jumpTo(position.maxScrollExtent);
    }
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: where);
}

void main() {
  setUpAll(loadAppFonts);

  for (final language in ['id', 'en']) {
    for (final size in [TestWindows.phone, TestWindows.tablet]) {
      for (final brightness in Brightness.values) {
        final label = '$language, ${size.width.toInt()}dp, ${brightness.name}';
        testWidgets('NFR-15 INT-05 Keluarga Saya screens at 200% ($label)', (
          tester,
        ) async {
          final server = FakeServer();
          await openFamily(
            tester,
            server,
            textScale: 2.0,
            size: size,
            brightness: brightness,
            language: language,
            members: [
              ibu(),
              kakak(
                rules: [
                  allergyRuleJson(allergen: 'tree_nut'),
                  freeTextRuleJson('udang rebon kering'),
                ],
              ),
              profileJson(
                id: 'p-adik',
                name: 'Adik Bungsu Kesayangan',
                ageGroup: 'teen',
                isManager: false,
                rules: rulesJson(consent: 'none'),
              ),
            ],
          );
          await _guidelines(tester, 'F1 $label');
          await _scrollToEndWithoutOverflow(tester, 'F1 end $label');

          // F3 with every section.
          await tapText(tester, 'Kakak');
          await _guidelines(tester, 'F3 $label');
          await _scrollToEndWithoutOverflow(tester, 'F3 end $label');

          // F5 taste sheet.
          await tapKeyed(tester, 'member.prefs.edit');
          await _guidelines(tester, 'F5 $label');
          await tester.tap(find.byIcon(Icons.close).last);
          await tester.pumpAndSettle();

          // F4 add rule, then with the written-rule field open.
          await tapKeyed(tester, 'member.rules.add');
          await _guidelines(tester, 'F4 $label');
          await tapKeyed(tester, 'rules.other.open');
          await _scrollToEndWithoutOverflow(tester, 'F4 end $label');
          await systemBack(tester);

          // F2 edit (manager-free form) and back.
          await tapKeyed(tester, 'member.edit');
          await _guidelines(tester, 'F2 $label');
          await systemBack(tester);
          await systemBack(tester);

          // F2r and F4c for a child without consent.
          await tapKeyed(tester, 'family.card.action.p-adik');
          await _guidelines(tester, 'F2r $label');
          await tapKeyed(tester, 'rules.pick.halal.null');
          await tapKeyed(tester, 'rules.save');
          await _guidelines(tester, 'F4c $label');
          await _scrollToEndWithoutOverflow(tester, 'F4c end $label');
          await tapKeyed(tester, 'consent.close');
          await systemBack(tester);

          // F2 add, then F2g for a child.
          await tapKeyed(tester, 'family.add');
          await tester.enterText(find.byKey(const Key('profile.name')), 'Cucu');
          await tapKeyed(tester, 'profile.age.infant');
          await _guidelines(tester, 'F2 add $label');
          await tapKeyed(tester, 'profile.save');
          await _guidelines(tester, 'F2g $label');
          await tapKeyed(tester, 'guardian.cancel');
        });
      }
    }
  }
}
