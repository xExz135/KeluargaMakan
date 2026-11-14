// DAT-08, ACC-13 and security review L2: tokens, refresh tokens, contact
// details and hard-rule contents never reach logs through toString or a
// log call.
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/data/decoders.dart';
import 'package:keluargamakan/data/models/family.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/data/repositories/auth_repository.dart';
import 'package:keluargamakan/features/auth/google_id_token.dart';
import 'package:keluargamakan/features/auth/sign_in_draft.dart';
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

  test('DAT-08 consent models and failures (contract 0.1.2) print no '
      'secrets', () {
    final renewal = decodeProfile(
      profileJson(
        name: 'Nenek Rahasia',
        rules: rulesJson(
          renewalRequired: true,
          items: [freeTextRuleJson(_secretRule)],
        ),
      ),
    );
    expectClean(renewal);
    expectClean(renewal.rules);
    expectClean(renewal.rules.consentSnapshot!);
    expect(renewal.rules.toString(), 'RulesSaved(1 rules, renewal required)');
    final problem = ApiProblem.parse(
      409,
      '{"code":"consent_changed","detail":"$_secretRule","requestId":"r"}',
    );
    expectClean(ConsentChangedFailure(problem));
    expectClean(Err<Object>(ConsentChangedFailure(problem)));
    expectClean(ManagerProfileMustBeAdultFailure(problem));
  });

  test('ACC-01 DAT-08 the sign-in in progress prints no contact details, '
      'and a Google token is never printed', () {
    final challenge = api.SignInCodeChallenge.fromJson({
      'challengeId': '6f1a2b3c-4d5e-4f60-8a7b-9c0d1e2f3a4b',
      'channel': 'phone',
      'codeLength': 6,
      'expiresAt': '2026-11-14T03:10:00Z',
      'resendAvailableAt': '2026-11-14T03:01:00Z',
    })!;
    final draft = SignInDraft(
      channel: api.SignInChannel.phone,
      destination: '+6281200000000',
      maskedDestination: '0812 •••• 0000',
      challenge: challenge,
      resendAvailableAt: DateTime.utc(2026, 11, 14, 3, 1),
    );
    expectClean(draft);
    expect(draft.toString(), isNot(contains('0812')));
    expect(draft.toString(), 'SignInDraft(phone)');
    const token = GoogleIdToken('google-id-token-s3cret');
    expect(token.toString(), isNot(contains('s3cret')));
  });

  test('ACC-01 DAT-08 the sign-in screens log nothing at all', () {
    final calls = RegExp(r'\b(debugPrint|print|log|debugPrintStack)\(');
    final files = Directory('lib/features/auth')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final file in files) {
      expect(
        calls.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
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
