// DAT-08, ACC-13 and security review L2: tokens, refresh tokens, contact
// details and hard-rule contents never reach logs through toString or a
// log call.
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/data/decoders.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/data/repositories/auth_repository.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../helpers/api_fixtures.dart';

const _secretRule = 'TEST FIXTURE secret rule text';

void main() {
  final generatedTokens = api.SessionTokens.fromJson(tokensJson('s3cret'))!;
  final member = decodeProfile(
    profileJson(
      name: 'Nenek Rahasia',
      rules: rulesJson(
        items: [allergyRuleJson(), freeTextRuleJson(_secretRule)],
      ),
    ),
  );

  void expectClean(Object value) {
    final text = value.toString();
    for (final secret in [
      'access-s3cret',
      'refresh-s3cret',
      'access-1',
      'refresh-1',
      _secretRule,
      'peanut',
      'Nenek Rahasia',
      '+6281200000000',
    ]) {
      expect(text, isNot(contains(secret)), reason: '${value.runtimeType}');
    }
  }

  test('DAT-08 the generated models do print secrets, so they must never '
      'be logged directly', () {
    // Guard rail for the test below: if this ever stops printing, the
    // generator changed, and the log-call check still applies.
    expect(generatedTokens.toString(), contains('refresh-s3cret'));
  });

  test('DAT-08 results, sessions and app models print no secrets', () {
    expectClean(Ok(generatedTokens));
    expectClean(Ok(api.SessionRefresh(refreshToken: 'refresh-s3cret')));
    expectClean(Ok(member));
    expectClean(Ok(member.rules));
    expectClean(member);
    expectClean(member.rules);
    expectClean(
      FamilyProfiles(
        members: [member],
        maxProfiles: 12,
        source: const FromNetwork(),
      ),
    );
    expectClean(Refreshed(testTokens));
    expectClean(testTokens);
    expectClean(RefreshFailed(http.Response('refresh-s3cret', 503)));
    expectClean(RefreshEndedSession(http.Response('access-s3cret', 401)));
    expectClean(
      SignedIn(
        account: api.Account.fromJson(accountJson())!,
        isNewAccount: false,
      ),
    );
    expectClean(Ok(decodeHousehold(householdJson())));
    expectClean(const Err<Object>(DecodeFailure('listProfiles')));
    expect(Ok(member).toString(), 'Ok<FamilyMember>');
  });

  test('DAT-08 log calls in lib/ interpolate only the operation name and '
      'error types', () {
    final calls = RegExp(
      r'\b(debugPrint|print|log|debugPrintStack)\(([\s\S]*?)\);',
    );
    final interpolation = RegExp(r'\$\{([^}]*)\}|\$([A-Za-z_]\w*)');
    const allowed = {'operation', 'e.runtimeType'};
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.contains('l10n${Platform.pathSeparator}'));
    var checked = 0;
    for (final file in files) {
      for (final call in calls.allMatches(file.readAsStringSync())) {
        checked++;
        final argument = call.group(2)!.trim();
        expect(
          argument.startsWith("'") || argument.startsWith('"'),
          isTrue,
          reason: '${file.path}: log a string literal, not a value',
        );
        for (final m in interpolation.allMatches(argument)) {
          final expr = m.group(1) ?? m.group(2)!;
          expect(allowed, contains(expr), reason: '${file.path}: \$$expr');
        }
      }
    }
    expect(checked, greaterThan(0));
  });
}
