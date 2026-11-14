// Keluarga Saya flows against the fake API (T-028): add a member, consent,
// rules, guardian confirmation, re-consent after an age change,
// consent_changed, withdrawal and rules_unavailable.
// TEST FIXTURE: not real safety or nutrition data. Names and rules are
// invented; allergen codes are the contract's enum.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/features/keluarga_saya/member_detail_screen.dart';
import 'package:keluargamakan/features/keluarga_saya/rules_picker_screen.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'family_test_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  testWidgets('PRF-01 PRF-03 PRF-04 ACC-08 SET-03 add an adult, give consent, '
      'add an allergy, then remove it', (tester) async {
    await openFamily(tester, server);
    expect(find.text('Siapa lagi yang makan di rumah?'), findsOneWidget);

    await tapKeyed(tester, 'family.add');
    await tester.enterText(find.byKey(const Key('profile.name')), 'Kakak');
    await tapKeyed(tester, 'profile.age.adult');
    await tapKeyed(tester, 'profile.save');

    // F2r opens at once for the new member.
    expect(find.byType(RulesPickerScreen), findsOneWidget);
    expect(
      find.text('Ada makanan yang tidak boleh Kakak makan?'),
      findsOneWidget,
    );
    // The allergy chips come from the API, in its order.
    expect(indexOfRequest(server, 'GET', '/v1/reference/allergens'), isNot(-1));
    await tapKeyed(tester, 'rules.pick.allergy.shrimp');
    await tapKeyed(tester, 'rules.save');

    // F4c: the server's adult text, the picked rule, nothing sent yet.
    expect(find.text('Boleh kami simpan aturan makan Kakak?'), findsOneWidget);
    expect(find.text('Judul uji health-adult-1'), findsOneWidget);
    expect(find.text('Alergi Udang'), findsWidgets);
    expect(requestsTo(server, 'POST', '/hard-rules'), isEmpty);
    await tapKeyed(tester, 'consent.accept');

    // Consent first, with the precondition; then the rule.
    final consentAt = indexOfRequest(server, 'POST', '/consents/health-data');
    final ruleAt = indexOfRequest(server, 'POST', '/hard-rules');
    expect(consentAt, isNot(-1));
    expect(ruleAt, greaterThan(consentAt));
    final consent = bodiesOf(server, 'POST', '/consents/health-data').single;
    expect(consent['decision'], 'given');
    expect(consent['textVersion'], 'health-adult-1');
    expect(consent['expectedConsent'], {
      'status': 'none',
      'consentRecordId': null,
    });
    expect(
      requestsTo(
        server,
        'POST',
        '/consents/health-data',
      ).single.headers['idempotency-key'],
      isNotEmpty,
    );
    expect(bodiesOf(server, 'POST', '/hard-rules').single, {
      'type': 'allergy',
      'allergen': 'shrimp',
    });

    // F3 shows the saved rule.
    expect(find.byType(MemberDetailScreen), findsOneWidget);
    expect(find.text('Alergi Udang'), findsOneWidget);
    expectNoSafetyVerdict(tester);

    // F4r: remove it.
    await tester.tap(find.byTooltip('Hapus aturan Alergi Udang'));
    await tester.pumpAndSettle();
    expect(
      find.text('Hapus aturan "Alergi Udang" untuk Kakak?'),
      findsOneWidget,
    );
    await tapKeyed(tester, 'rule.remove.confirm');
    expect(requestsTo(server, 'DELETE', '/hard-rules/rule-'), isEmpty);
    expect(
      server.requests.where(
        (r) => r.method == 'DELETE' && r.url.path.contains('/hard-rules/'),
      ),
      hasLength(1),
    );
    expect(find.text('Alergi Udang'), findsNothing);
    expect(
      find.text('Tambahkan aturan wajib kalau ada alergi atau pantangan.'),
      findsOneWidget,
    );

    // Back to the list: both cards say the member has no hard rules.
    await systemBack(tester);
    expect(find.text('Kakak'), findsOneWidget);
    expect(find.text('Belum ada aturan wajib'), findsNWidgets(2));
  });

  testWidgets('SET-10 PRF-18 a child profile needs the guardian confirmation '
      'first, then the child consent text', (tester) async {
    await openFamily(tester, server);
    await tapKeyed(tester, 'family.add');
    await tester.enterText(find.byKey(const Key('profile.name')), 'Adik');
    await tapKeyed(tester, 'profile.age.child');
    await tapKeyed(tester, 'profile.save');

    // F2g: server text, unticked box, confirm disabled until ticked.
    expect(find.text('Konfirmasi orang tua atau wali'), findsOneWidget);
    expect(find.text('Judul uji guardian-1'), findsOneWidget);
    final confirm = find.byKey(const Key('guardian.confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(requestsTo(server, 'POST', '/v1/household/profiles'), isEmpty);

    // Cancel: nothing is created.
    await tapKeyed(tester, 'guardian.cancel');
    expect(requestsTo(server, 'POST', '/v1/household/profiles'), isEmpty);

    await tapKeyed(tester, 'profile.save');
    await tapKeyed(tester, 'guardian.check');
    await tapKeyed(tester, 'guardian.confirm');
    final created = bodiesOf(server, 'POST', '/v1/household/profiles').single;
    expect(created['ageGroup'], 'child');
    expect(created['guardianConfirmation'], {
      'confirmed': true,
      'textVersion': 'guardian-1',
      'language': 'id',
    });

    // F2r "Nanti saja": no consent, no rules; the member is never shown as
    // checked.
    await tapKeyed(tester, 'rules.later');
    expect(requestsTo(server, 'POST', '/consents/health-data'), isEmpty);
    expect(find.text('Aturan makan Adik belum diisi.'), findsOneWidget);
    expect(find.text('Anak'), findsWidgets);

    // Fill in later: the child text and the child note.
    await tapKeyed(tester, 'member.rules.start');
    await tapKeyed(tester, 'rules.pick.halal.null');
    await tapKeyed(tester, 'rules.save');
    expect(
      find.text(
        'Adik masih anak-anak. Sebagai orang tua atau wali, Anda yang '
        'memberi izin ini.',
      ),
      findsOneWidget,
    );
    final textRequest = requestsTo(
      server,
      'GET',
      '/v1/consent-texts/health_data',
    ).last;
    expect(textRequest.url.queryParameters['audience'], 'child');
    await tapKeyed(tester, 'consent.accept');
    expect(
      bodiesOf(server, 'POST', '/consents/health-data').single['textVersion'],
      'health-child-1',
    );
    expect(find.text('Halal'), findsOneWidget);
    expectNoSafetyVerdict(tester);
  });

  testWidgets('SET-10 QUESTIONS #62 an adult changed to a child keeps the '
      'rules and is asked for consent again', (tester) async {
    await openFamily(
      tester,
      server,
      members: [
        ibu(),
        kakak(rules: [allergyRuleJson()]),
      ],
    );
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.edit');
    await tapKeyed(tester, 'profile.age.teen');
    await tapKeyed(tester, 'profile.save');
    await tapKeyed(tester, 'guardian.check');
    await tapKeyed(tester, 'guardian.confirm');
    final patch = bodiesOf(server, 'PATCH', '/profiles/p-kakak').single;
    expect(patch['ageGroup'], 'teen');
    expect(patch['guardianConfirmation'], isNotNull);

    // Same flow: the consent sheet for the child text, with the stored rule.
    expect(find.text('Boleh kami simpan aturan makan Kakak?'), findsOneWidget);
    expect(find.textContaining('tetap dipakai sampai Anda memilih'), findsOne);
    expect(find.text('Judul uji health-child-1'), findsOneWidget);
    // Closed without a decision: the rule stays, new rules wait.
    await tapKeyed(tester, 'consent.close');
    expect(find.text('Alergi Kacang tanah'), findsOneWidget);
    expect(find.byKey(const Key('member.rules.renewal')), findsOneWidget);
    final add = find.byKey(const Key('member.rules.add'));
    expect(tester.widget<FilledButton>(add).onPressed, isNull);

    await tapKeyed(tester, 'member.rules.renew');
    await tapKeyed(tester, 'consent.accept');
    final consent = bodiesOf(server, 'POST', '/consents/health-data').single;
    expect(consent['textVersion'], 'health-child-1');
    expect(consent['expectedConsent'], {
      'status': 'given',
      'consentRecordId': 'consent-1',
    });
    expect(find.byKey(const Key('member.rules.renewal')), findsNothing);
    expect(find.text('Alergi Kacang tanah'), findsOneWidget);
    expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
  });

  testWidgets('SET-03 consent_changed: the member is read again and the '
      'manager decides again with a new key', (tester) async {
    await openFamily(
      tester,
      server,
      members: [
        ibu(),
        kakak(consent: 'none'),
      ],
    );
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.rules.start');
    await tapKeyed(tester, 'rules.pick.vegetarian.null');
    await tapKeyed(tester, 'rules.save');

    // Another phone declines meanwhile.
    server.changeConsentElsewhere('p-kakak', 'declined');
    await tapKeyed(tester, 'consent.accept');
    expect(
      find.text(
        'Izin Kakak baru saja diubah di HP lain. Datanya sudah kami muat '
        'ulang. Mohon baca dan pilih lagi.',
      ),
      findsOneWidget,
    );
    expect(requestsTo(server, 'POST', '/hard-rules'), isEmpty);

    await tapKeyed(tester, 'consent.accept');
    final sent = requestsTo(server, 'POST', '/consents/health-data');
    expect(sent, hasLength(2));
    expect(
      sent[0].headers['idempotency-key'],
      isNot(sent[1].headers['idempotency-key']),
    );
    final second = bodiesOf(server, 'POST', '/consents/health-data')[1];
    expect((second['expectedConsent']! as Map)['status'], 'declined');
    expect(bodiesOf(server, 'POST', '/hard-rules').single, {
      'type': 'vegetarian',
    });
    expect(find.text('Vegetarian'), findsOneWidget);
  });

  testWidgets('SET-03 SET-04 withdrawing consent says the rules are deleted, '
      'and they are gone', (tester) async {
    await openFamily(
      tester,
      server,
      members: [
        ibu(),
        kakak(rules: [allergyRuleJson()]),
      ],
    );
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.consent.withdraw');
    expect(find.text('Tarik izin aturan makan Kakak?'), findsOneWidget);
    expect(find.textContaining('paling lambat 30 hari lagi'), findsOneWidget);
    await tapKeyed(tester, 'consent.withdraw.confirm');

    final body = bodiesOf(server, 'POST', '/withdraw').single;
    expect(body['expectedConsent'], {
      'status': 'given',
      'consentRecordId': 'consent-1',
    });
    expect(
      find.text(
        'Izin ditarik. Aturan makan Kakak tidak dipakai lagi dan dihapus '
        'paling lambat 13 Des 2026.',
      ),
      findsOneWidget,
    );
    expect(find.text('Alergi Kacang tanah'), findsNothing);
    expect(find.byKey(const Key('member.rules.notSaved')), findsOneWidget);
    expect(
      find.text('Aturan lama dihapus paling lambat 13 Des 2026.'),
      findsOneWidget,
    );
    expect(find.text('Beri izin'), findsOneWidget);
  });

  testWidgets('QUESTIONS #39 rules_unavailable shows the error, never "no '
      'rules"', (tester) async {
    server.rulesUnavailable = true;
    await openFamily(tester, server, members: [ibu(), kakak()]);
    expect(find.text('Aturan makan belum bisa dibuka'), findsOneWidget);
    expect(find.text('Belum ada aturan wajib'), findsNothing);
    expect(find.text('Kakak'), findsNothing);

    server.rulesUnavailable = false;
    await tapKeyed(tester, 'family.retry');
    expect(find.text('Kakak'), findsOneWidget);
    expect(find.text('Aturan makan belum bisa dibuka'), findsNothing);
  });

  testWidgets('PRF-08 SAF-09 written text is saved unmapped and the screens '
      'say why every recipe gets Cek label', (tester) async {
    await openFamily(tester, server, members: [ibu(), kakak()]);
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.rules.add');
    expect(find.text('Tambah aturan untuk Kakak'), findsOneWidget);
    await tapKeyed(tester, 'rules.other.open');
    await tester.enterText(find.byKey(const Key('rules.other.field')), 'nanas');
    await tapKeyed(tester, 'rules.other.add');
    expect(
      find.text(
        'Kami belum mengenali "nanas". Sampai tim kami mencocokkannya, semua '
        'resep untuk Kakak diberi tanda Cek label, supaya tidak ada yang '
        'terlewat.',
      ),
      findsOneWidget,
    );
    await tapKeyed(tester, 'rules.save');
    // Consent is already given: no sheet.
    expect(requestsTo(server, 'POST', '/consents/health-data'), isEmpty);
    expect(bodiesOf(server, 'POST', '/hard-rules').single, {
      'type': 'free_text',
      'freeText': 'nanas',
    });

    expect(find.text('nanas'), findsOneWidget);
    expect(
      find.text(
        'Menunggu dicocokkan tim kami. Sementara itu, semua resep untuk '
        'Kakak diberi tanda Cek label.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Kenapa?');
    expect(
      find.textContaining('Daripada menebak, semua resep untuk Kakak'),
      findsOneWidget,
    );
  });

  testWidgets('PRF-03 a doctor\'s restriction needs text and is sent as a '
      'medical exclusion', (tester) async {
    await openFamily(tester, server, members: [ibu(), kakak()]);
    await tapText(tester, 'Kakak');
    await tapKeyed(tester, 'member.rules.add');
    await tapKeyed(tester, 'rules.other.open');
    await tapKeyed(tester, 'rules.other.medical');
    await tapKeyed(tester, 'rules.other.add');
    expect(find.text('Tulis bahan yang tidak boleh dimakan.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('rules.other.field')),
      'durian',
    );
    await tapKeyed(tester, 'rules.other.add');
    await tapKeyed(tester, 'rules.save');
    expect(bodiesOf(server, 'POST', '/hard-rules').single, {
      'type': 'medical_exclusion',
      'freeText': 'durian',
    });
    expect(find.text('Pantangan dokter: durian'), findsOneWidget);
  });

  testWidgets('ACC-08 a declined consent stores no rules and the member '
      'shows "tidak disimpan"', (tester) async {
    await openFamily(
      tester,
      server,
      members: [
        ibu(),
        kakak(consent: 'none'),
      ],
    );
    await tapKeyed(tester, 'family.card.action.p-kakak');
    await tapKeyed(tester, 'rules.pick.allergy.egg');
    await tapKeyed(tester, 'rules.save');
    await tapKeyed(tester, 'consent.decline');
    expect(find.text('Lanjut tanpa menyimpan?'), findsOneWidget);
    await tapKeyed(tester, 'consent.decline.confirm');
    expect(
      bodiesOf(server, 'POST', '/consents/health-data').single['decision'],
      'declined',
    );
    expect(requestsTo(server, 'POST', '/hard-rules'), isEmpty);
    expect(
      find.text('Aturan makan tidak disimpan, jadi tidak diperiksa Cek Aman'),
      findsOneWidget,
    );
    expectNoSafetyVerdict(tester);
  });

  testWidgets('ACC-08 "Tidak ada aturan" records consent with no rules', (
    tester,
  ) async {
    await openFamily(
      tester,
      server,
      members: [
        ibu(),
        kakak(consent: 'none'),
      ],
    );
    await tapKeyed(tester, 'family.card.action.p-kakak');
    await tapKeyed(tester, 'rules.none');
    expect(
      find.text('Anda memilih: Kakak tidak punya aturan makan.'),
      findsOneWidget,
    );
    await tapKeyed(tester, 'consent.accept');
    expect(
      bodiesOf(server, 'POST', '/consents/health-data').single['decision'],
      'given',
    );
    expect(requestsTo(server, 'POST', '/hard-rules'), isEmpty);
    expect(
      find.descendant(
        of: find.byKey(const Key('family.card.p-kakak')),
        matching: find.text('Belum ada aturan wajib'),
      ),
      findsOneWidget,
    );
  });
}
