// Keluarga Saya screens and states (T-028): F1 card lines per consent
// state, offline and limit states, F2 validation and errors, the manager's
// own profile, F3 sections, F5 sheets and F6 delete.
// TEST FIXTURE: not real safety or nutrition data. Names and rules are
// invented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/theme/theme_extensions.dart';
import 'package:keluargamakan/data/family_profiles_state.dart';
import 'package:keluargamakan/features/keluarga_saya/keluarga_saya_screen.dart';
import 'package:keluargamakan/features/keluarga_saya/widgets/family_widgets.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_server.dart';
import '../helpers/pump_app.dart';
import 'family_test_helpers.dart';

Finder _inCard(String id, Finder matching) =>
    find.descendant(of: find.byKey(Key('family.card.$id')), matching: matching);

void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;
  setUp(() => server = FakeServer());

  group('F1 list', () {
    testWidgets('PRF-01 PRF-18 ACC-08 each card has one rules line from the '
        'consent state, with neutral notes and no safety words', (
      tester,
    ) async {
      await openFamily(
        tester,
        server,
        members: [
          ibu(),
          kakak(rules: [allergyRuleJson(allergen: 'shrimp')]),
          profileJson(
            id: 'p-adik',
            name: 'Adik',
            ageGroup: 'child',
            isManager: false,
            rules: rulesJson(consent: 'none'),
          ),
          profileJson(
            id: 'p-nenek',
            name: 'Nenek',
            ageGroup: 'elderly',
            isManager: false,
            rules: rulesJson(consent: 'declined'),
          ),
          profileJson(
            id: 'p-om',
            name: 'Om',
            isManager: false,
            rules: rulesJson(items: [freeTextRuleJson('nanas')]),
          ),
          profileJson(
            id: 'p-tante',
            name: 'Tante',
            isManager: false,
            rules: rulesJson(consent: 'withdrawn'),
          ),
        ],
      );
      expect(find.text('6 orang'), findsOneWidget);
      expect(_inCard('p-ibu', find.text('Anda')), findsOneWidget);
      expect(
        _inCard('p-ibu', find.text('Belum ada aturan wajib')),
        findsOneWidget,
      );
      expect(_inCard('p-kakak', find.text('Alergi Udang')), findsOneWidget);
      expect(_inCard('p-adik', find.text('Anak')), findsOneWidget);
      expect(
        _inCard(
          'p-adik',
          find.text('Aturan makan belum diisi, jadi belum diperiksa Cek Aman'),
        ),
        findsOneWidget,
      );
      expect(_inCard('p-adik', find.text('Isi aturan makan')), findsOneWidget);
      for (final id in ['p-nenek', 'p-tante']) {
        expect(
          _inCard(
            id,
            find.text(
              'Aturan makan tidak disimpan, jadi tidak diperiksa Cek Aman',
            ),
          ),
          findsOneWidget,
        );
        expect(_inCard(id, find.text('Beri izin')), findsOneWidget);
      }
      expect(
        _inCard('p-om', find.text('Ada aturan yang menunggu dicocokkan')),
        findsOneWidget,
      );
      // The neutral notes use the neutral colors, never a safety color.
      final note = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: _inCard('p-adik', find.byType(NeutralNote)),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final app = AppColors.of(tester.element(find.byType(NeutralNote).first));
      expect((note.decoration as BoxDecoration).color, app.neutralContainer);
      expect(
        find.descendant(
          of: find.byType(NeutralNote).first,
          matching: find.byIcon(Icons.info_outlined),
        ),
        findsOneWidget,
      );
      expectNoSafetyVerdict(tester);
    });

    testWidgets('PRF-01 the card reads as one TalkBack label', (tester) async {
      final handle = tester.ensureSemantics();
      await openFamily(
        tester,
        server,
        members: [
          ibu(),
          profileJson(
            id: 'p-adik',
            name: 'Adik',
            ageGroup: 'child',
            isManager: false,
            rules: rulesJson(consent: 'none'),
          ),
        ],
      );
      expect(
        find.bySemanticsLabel(
          'Adik, Anak (2–12 th), Anak, Aturan makan belum diisi, jadi belum '
          'diperiksa Cek Aman',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('NFR-05 QUESTIONS #39 without internet the cached names show, '
        'rules are not shown as known, and adding waits', (tester) async {
      final phone = await openFamily(
        tester,
        server,
        members: [
          ibu(),
          kakak(rules: [allergyRuleJson()]),
        ],
      );
      expect(find.text('Alergi Kacang tanah'), findsOneWidget);
      server.intercept = (r) => r.url.path.startsWith('/v1/household/profiles')
          ? throw http.ClientException('offline')
          : null;
      await phone.container.read(familyProfilesProvider.notifier).reload();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family.offline')), findsOneWidget);
      expect(find.text('Kakak'), findsOneWidget);
      expect(find.text('Alergi Kacang tanah'), findsNothing);
      expect(find.text('Belum ada aturan wajib'), findsNothing);
      expect(
        find.text('Aturan makan tampil saat ada internet'),
        findsNWidgets(2),
      );
      final add = find.byKey(const Key('family.add'));
      expect(tester.widget<FilledButton>(add).onPressed, isNull);

      // F3 from the cache: rules unknown, nothing editable that needs them.
      await tapText(tester, 'Kakak');
      expect(
        find.text('Aturan makan Kakak tampil saat ada internet.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('member.rules.add')), findsNothing);
      expect(find.byKey(const Key('member.consent.withdraw')), findsNothing);
      expect(find.byKey(const Key('member.delete')), findsNothing);
    });

    testWidgets('PRF-02 at the profile limit adding is disabled with the '
        'reason', (tester) async {
      server.maxProfiles = 12;
      await openFamily(
        tester,
        server,
        members: [
          ibu(),
          for (var i = 1; i < 12; i++)
            profileJson(id: 'p-$i', name: 'Anggota $i', isManager: false),
        ],
      );
      await tester.scrollUntilVisible(
        find.text('Sudah 12 profil, jumlah paling banyak.'),
        200,
      );
      final add = find.byKey(const Key('family.add'));
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
    });

    testWidgets('QUESTIONS #39 a payload this app cannot read is an error, '
        'not an empty family', (tester) async {
      server.intercept = (r) =>
          r.method == 'GET' && r.url.path == '/v1/household/profiles'
          ? FakeServer.json({'items': 'oops', 'maxProfiles': 12})
          : null;
      await openFamily(tester, server);
      expect(find.byKey(const Key('family.error')), findsOneWidget);
      expect(find.text('Ada kendala'), findsOneWidget);
      expect(find.text('Siapa lagi yang makan di rumah?'), findsNothing);
    });

    testWidgets('PRF-01 loading shows skeletons, never an empty family', (
      tester,
    ) async {
      server.delays['/v1/household/profiles'] = const Duration(seconds: 2);
      await openFamily(tester, server, openTab: false);
      await tester.tap(find.text('Keluarga').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SkeletonBlock), findsWidgets);
      expect(find.text('Belum ada aturan wajib'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBlock), findsNothing);
    });

    testWidgets('INT-05 on a tablet "Tambah anggota" is also a FAB', (
      tester,
    ) async {
      await openFamily(
        tester,
        server,
        members: [ibu(), kakak()],
        size: TestWindows.tablet,
      );
      expect(find.byKey(const Key('family.add.fab')), findsOneWidget);
    });
  });

  group('F2 add and edit', () {
    testWidgets('PRF-01 Save waits for a name and an age group; a name the '
        'server refuses shows under the field', (tester) async {
      await openFamily(tester, server);
      await tapKeyed(tester, 'family.add');
      final save = find.descendant(
        of: find.byKey(const Key('profile.save')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('profile.name')), 'Ayah');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tapKeyed(tester, 'profile.age.adult');
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      server.intercept = (r) => r.method == 'POST'
          ? FakeServer.problem(
              'validation_failed',
              400,
              extra: {
                'errors': [
                  {'pointer': '/name', 'code': 'invalid'},
                ],
              },
            )
          : null;
      await tapKeyed(tester, 'profile.save');
      expect(find.text('Isinya belum benar.'), findsOneWidget);
    });

    testWidgets('PRF-01 NFR-05 without internet the form stays with what '
        'was typed, and a retry reuses the Idempotency-Key', (tester) async {
      await openFamily(tester, server);
      await tapKeyed(tester, 'family.add');
      await tester.enterText(find.byKey(const Key('profile.name')), 'Ayah');
      await tapKeyed(tester, 'profile.age.adult');
      server.intercept = (r) =>
          r.method == 'POST' ? throw http.ClientException('offline') : null;
      await tapKeyed(tester, 'profile.save');
      expect(
        find.text('Menyimpan butuh internet. Isian Anda tetap di sini.'),
        findsOneWidget,
      );
      expect(find.text('Ayah'), findsWidgets);
      server.intercept = null;
      await tapKeyed(tester, 'profile.save');
      final sent = requestsTo(server, 'POST', '/v1/household/profiles');
      expect(sent, hasLength(2));
      expect(
        sent[0].headers['idempotency-key'],
        sent[1].headers['idempotency-key'],
      );
    });

    testWidgets('SET-10 a child profile without internet explains why it '
        'cannot be saved', (tester) async {
      await openFamily(tester, server);
      await tapKeyed(tester, 'family.add');
      await tester.enterText(find.byKey(const Key('profile.name')), 'Adik');
      await tapKeyed(tester, 'profile.age.infant');
      server.intercept = (r) => r.url.path.contains('consent-texts')
          ? throw http.ClientException('offline')
          : null;
      await tapKeyed(tester, 'profile.save');
      expect(
        find.text(
          'Profil anak butuh internet supaya konfirmasi orang tua atau wali '
          'bisa dicatat.',
        ),
        findsOneWidget,
      );
      expect(requestsTo(server, 'POST', '/v1/household/profiles'), isEmpty);
    });

    testWidgets('PRF-01 Android back with typed text asks before discarding', (
      tester,
    ) async {
      await openFamily(tester, server);
      await tapKeyed(tester, 'family.add');
      await tester.enterText(find.byKey(const Key('profile.name')), 'Ayah');
      await systemBack(tester);
      expect(find.text('Buang perubahan?'), findsOneWidget);
      await tapKeyed(tester, 'profile.discard.cancel');
      expect(find.text('Anggota baru'), findsOneWidget);
      await systemBack(tester);
      await tapKeyed(tester, 'profile.discard.confirm');
      expect(find.byType(KeluargaSayaScreen), findsOneWidget);
      expect(requestsTo(server, 'POST', '/v1/household/profiles'), isEmpty);
    });

    testWidgets('PRF-01 QUESTIONS #46 the manager\'s own profile offers only '
        'adult groups, shows the server\'s 409, and has no delete', (
      tester,
    ) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Ibu');
      expect(find.byKey(const Key('member.delete')), findsNothing);
      await tapKeyed(tester, 'member.edit');
      expect(find.byKey(const Key('profile.age.adult')), findsOneWidget);
      expect(find.byKey(const Key('profile.age.elderly')), findsOneWidget);
      for (final group in ['infant', 'child', 'teen']) {
        expect(find.byKey(Key('profile.age.$group')), findsNothing);
      }
      expect(
        find.text('Untuk profil pengelola, pilih Dewasa atau Lansia.'),
        findsOneWidget,
      );
      server.intercept = (r) => r.method == 'PATCH'
          ? FakeServer.problem('manager_profile_must_be_adult', 409)
          : null;
      await tapKeyed(tester, 'profile.age.elderly');
      await tapKeyed(tester, 'profile.save');
      expect(
        find.descendant(
          of: find.byKey(const Key('profile.message')),
          matching: find.text(
            'Untuk profil pengelola, pilih Dewasa atau Lansia.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('PRF-01 QUESTIONS #27 editing the name and avatar color sends '
        'only the changes, with no photo option', (tester) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      await tapKeyed(tester, 'member.edit');
      expect(find.byKey(const Key('profile.avatar.7')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('profile.name')), 'Kak Rina');
      await tapKeyed(tester, 'profile.avatar.3');
      await tapKeyed(tester, 'profile.save');
      final patch = bodiesOf(server, 'PATCH', '/profiles/p-kakak').single;
      expect(patch['name'], 'Kak Rina');
      expect(patch['avatar'], {'style': 'initials', 'colorToken': 'avatar_4'});
      expect(patch.containsKey('ageGroup'), isFalse);
      expect(find.text('Kak Rina'), findsWidgets);
    });
  });

  group('F3 sections and F5 sheets', () {
    testWidgets('PRF-05 taste is saved as the whole object', (tester) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      await tapKeyed(tester, 'member.prefs.edit');
      await tapKeyed(tester, 'prefs.spice.spicy');
      await tapKeyed(tester, 'prefs.less.santan');
      await tapKeyed(tester, 'prefs.texture.soupy');
      await tapKeyed(tester, 'sheet.save');
      final body = bodiesOf(server, 'PUT', '/preferences').single;
      expect(body['spiceLevel'], 'spicy');
      expect(body['lessOf'], ['santan']);
      expect(body['textures'], ['soupy']);
      expect(find.text('Kurangi santan'), findsOneWidget);
      expect(find.text('Suka berkuah'), findsOneWidget);
    });

    testWidgets('PRF-07 portions show "bawaan" and "Pakai bawaan" sends null', (
      tester,
    ) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      expect(find.text('bawaan'), findsNWidgets(2));
      await tapKeyed(tester, 'member.portions.edit');
      await tapKeyed(tester, 'portion.meal.large');
      await tapKeyed(tester, 'sheet.save');
      expect(bodiesOf(server, 'PATCH', '/profiles/p-kakak').single, {
        'portionSize': 'large',
      });
      expect(find.text('Besar'), findsOneWidget);
      expect(find.text('bawaan'), findsOneWidget);

      await tapKeyed(tester, 'member.portions.edit');
      await tapKeyed(tester, 'portion.meal.default');
      await tapKeyed(tester, 'sheet.save');
      expect(bodiesOf(server, 'PATCH', '/profiles/p-kakak').last, {
        'portionSize': null,
      });
      expect(find.text('bawaan'), findsNWidgets(2));
    });

    testWidgets('PRF-06 QUESTIONS #49 likes can be removed; adding waits for '
        'search', (tester) async {
      final member = kakak();
      member['likesDislikes'] = {
        'likes': [
          {
            'kind': 'ingredient',
            'refId': 'ing_tempe',
            'displayName': {'id': 'Tempe', 'en': 'Tempeh'},
          },
        ],
        'dislikes': [
          {
            'kind': 'dish',
            'refId': 'dish_pare',
            'displayName': {
              'id': 'Tumis pare',
              'en': 'Stir-fried bitter melon',
            },
          },
        ],
        'updatedAt': '2026-11-01T03:00:00Z',
      };
      await openFamily(tester, server, members: [ibu(), member]);
      await tapText(tester, 'Kakak');
      expect(find.text('Tempe'), findsOneWidget);
      expect(
        find.text('Pencarian belum tersedia. Coba lagi nanti.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tidak suka bukan alergi. Untuk alergi, tambahkan di Aturan wajib.',
        ),
        findsOneWidget,
      );
      await tapKeyed(tester, 'member.likes.edit');
      await tester.tap(find.byTooltip('Hapus Tumis pare'));
      await tester.pumpAndSettle();
      await tapKeyed(tester, 'sheet.save');
      expect(bodiesOf(server, 'PUT', '/likes-dislikes').single, {
        'likes': [
          {'kind': 'ingredient', 'refId': 'ing_tempe'},
        ],
        'dislikes': <Object?>[],
      });
      expect(find.text('Tumis pare'), findsNothing);
    });

    testWidgets('SET-07 deleting a member asks first, then removes them', (
      tester,
    ) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      await tapKeyed(tester, 'member.delete');
      expect(find.text('Hapus profil Kakak?'), findsOneWidget);
      await tapKeyed(tester, 'member.delete.cancel');
      expect(requestsTo(server, 'DELETE', '/profiles/p-kakak'), isEmpty);
      await tapKeyed(tester, 'member.delete');
      await tapKeyed(tester, 'member.delete.confirm');
      expect(requestsTo(server, 'DELETE', '/profiles/p-kakak'), hasLength(1));
      expect(find.byType(KeluargaSayaScreen), findsOneWidget);
      expect(find.text('Profil Kakak dihapus.'), findsOneWidget);
      expect(find.byKey(const Key('family.card.p-kakak')), findsNothing);
    });

    testWidgets('SET-07 deleting without internet keeps the member', (
      tester,
    ) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      server.intercept = (r) =>
          r.method == 'DELETE' ? throw http.ClientException('offline') : null;
      await tapKeyed(tester, 'member.delete');
      await tapKeyed(tester, 'member.delete.confirm');
      expect(find.text('Hapus profil butuh internet.'), findsOneWidget);
      expect(find.text('Kakak'), findsWidgets);
    });

    testWidgets('PRF-03 a rule is added only after the server confirms; a '
        'failure keeps it picked with the reason', (tester) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      await tapKeyed(tester, 'member.rules.add');
      await tapKeyed(tester, 'rules.pick.allergy.egg');
      server.intercept = (r) =>
          r.method == 'POST' ? throw http.ClientException('offline') : null;
      await tapKeyed(tester, 'rules.save');
      expect(
        find.text(
          'Ubah aturan makan butuh internet supaya Cek Aman bisa mengecek '
          'ulang.',
        ),
        findsOneWidget,
      );
      final first = requestsTo(server, 'POST', '/hard-rules').single;
      server.intercept = null;
      await tapKeyed(tester, 'rules.save');
      final second = requestsTo(server, 'POST', '/hard-rules').last;
      expect(
        second.headers['idempotency-key'],
        first.headers['idempotency-key'],
      );
      expect(find.text('Alergi Telur'), findsOneWidget);
    });

    testWidgets('PRF-04 the allergy list that cannot load shows an error and '
        'a retry, never a built-in list', (tester) async {
      server.allergensFail = true;
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      await tapKeyed(tester, 'member.rules.add');
      expect(
        find.text('Daftar alergi belum bisa dimuat. Coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Udang'), findsNothing);
      server.allergensFail = false;
      await tapKeyed(tester, 'rules.allergens.retry');
      expect(find.text('Udang'), findsOneWidget);
      // API order (fixture): peanut first, sesame last.
      final first = tester.getTopLeft(find.text('Kacang tanah'));
      final last = tester.getTopLeft(find.text('Wijen'));
      expect(first.dy <= last.dy, isTrue);
    });

    testWidgets('SET-03 consent text that cannot load records nothing', (
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
      server.intercept = (r) => r.url.path.contains('consent-texts/health')
          ? FakeServer.problem('internal_error', 500)
          : null;
      await tapKeyed(tester, 'family.card.action.p-kakak');
      await tapKeyed(tester, 'rules.pick.halal.null');
      await tapKeyed(tester, 'rules.save');
      expect(
        find.text(
          'Penjelasan izin belum bisa dimuat. Tanpa penjelasan ini, aturan '
          'makan belum bisa disimpan.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('consent.accept')), findsNothing);
      await tapKeyed(tester, 'consent.continueWithout');
      expect(requestsTo(server, 'POST', '/consents/health-data'), isEmpty);
      expect(requestsTo(server, 'POST', '/hard-rules'), isEmpty);
    });

    testWidgets('SET-03 a consent decision without internet is not queued; '
        'resending reuses the key', (tester) async {
      await openFamily(
        tester,
        server,
        members: [
          ibu(),
          kakak(consent: 'none'),
        ],
      );
      await tapKeyed(tester, 'family.card.action.p-kakak');
      await tapKeyed(tester, 'rules.pick.halal.null');
      await tapKeyed(tester, 'rules.save');
      server.intercept = (r) => r.url.path.endsWith('/consents/health-data')
          ? throw http.ClientException('offline')
          : null;
      await tapKeyed(tester, 'consent.accept');
      expect(
        find.text('Izin hanya bisa dicatat saat ada internet.'),
        findsOneWidget,
      );
      expect(requestsTo(server, 'POST', '/hard-rules'), isEmpty);
      server.intercept = null;
      await tapKeyed(tester, 'consent.accept');
      final sent = requestsTo(server, 'POST', '/consents/health-data');
      expect(sent, hasLength(2));
      expect(
        sent[0].headers['idempotency-key'],
        sent[1].headers['idempotency-key'],
      );
      expect(find.text('Halal'), findsOneWidget);
    });

    testWidgets('SET-03 consent_not_active on withdrawal reloads the member', (
      tester,
    ) async {
      await openFamily(tester, server, members: [ibu(), kakak()]);
      await tapText(tester, 'Kakak');
      server.intercept = (r) => r.url.path.endsWith('/withdraw')
          ? FakeServer.problem('consent_not_active', 409)
          : null;
      await tapKeyed(tester, 'member.consent.withdraw');
      await tapKeyed(tester, 'consent.withdraw.confirm');
      expect(
        find.text('Izin ini sudah tidak aktif. Datanya kami muat ulang.'),
        findsOneWidget,
      );
      expect(
        server.requests.where(
          (r) => r.method == 'GET' && r.url.path == '/v1/household/profiles',
        ),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });
  });

  testWidgets('PRF-01 a member removed on another phone shows "not found" '
      'and the list again', (tester) async {
    await openFamily(tester, server, members: [ibu(), kakak()]);
    await tapText(tester, 'Kakak');
    server.profilesByAccount.values.first.removeWhere(
      (p) => p['id'] == 'p-kakak',
    );
    server.intercept = (r) =>
        r.method == 'DELETE' ? FakeServer.problem('not_found', 404) : null;
    await tapKeyed(tester, 'member.delete');
    await tapKeyed(tester, 'member.delete.confirm');
    expect(
      find.text(
        'Data ini sudah tidak ada. Mungkin sudah dihapus dari HP lain.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('family.card.p-kakak')), findsNothing);
  });
}
