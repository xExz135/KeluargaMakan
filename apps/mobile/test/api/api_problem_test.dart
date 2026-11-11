// F1 (PR #6 review), contract-alignment.md 5: the problem+json reader.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/api/api_error_text.dart';
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/l10n/generated/app_localizations.dart';

String _body(Map<String, Object?> json) => jsonEncode({
  'type': 'urn:keluargamakan:problem:x',
  'title': 'Developer title',
  'status': 409,
  'detail': 'Developer detail',
  'requestId': 'req-9',
  ...json,
});

void main() {
  group('ApiProblem.parse', () {
    test('ACC-01 a known code is read with its request ID', () {
      final p = ApiProblem.parse(409, _body({'code': 'profile_limit_reached'}));
      expect(p.code, ApiErrorCode.profileLimitReached);
      expect(p.status, 409);
      expect(p.requestId, 'req-9');
    });

    test('ACC-01 an unknown code maps to internal_error', () {
      final p = ApiProblem.parse(409, _body({'code': 'brand_new_code'}));
      expect(p.code, ApiErrorCode.internalError);
    });

    test('ACC-01 a missing or non-string code maps to internal_error', () {
      expect(
        ApiProblem.parse(500, _body({'code': null})).code,
        ApiErrorCode.internalError,
      );
      expect(
        ApiProblem.parse(500, _body({'code': 42})).code,
        ApiErrorCode.internalError,
      );
    });

    test('ACC-01 a body that is not JSON never throws', () {
      final p = ApiProblem.parse(502, '<html>Bad gateway</html>');
      expect(p.code, ApiErrorCode.internalError);
      expect(p.status, 502);
      expect(ApiProblem.parse(500, '').code, ApiErrorCode.internalError);
      expect(ApiProblem.parse(500, '[1,2]').code, ApiErrorCode.internalError);
    });

    test('ACC-01 retryAfterSeconds comes from the body, else from '
        'Retry-After', () {
      expect(
        ApiProblem.parse(
          429,
          _body({'code': 'rate_limited', 'retryAfterSeconds': 90}),
          retryAfterHeader: '5',
        ).retryAfterSeconds,
        90,
      );
      expect(
        ApiProblem.parse(
          429,
          _body({'code': 'rate_limited'}),
          retryAfterHeader: ' 120 ',
        ).retryAfterSeconds,
        120,
      );
      expect(
        ApiProblem.parse(
          429,
          _body({'code': 'rate_limited', 'retryAfterSeconds': -3}),
        ).retryAfterSeconds,
        isNull,
      );
    });

    test('ACC-01 field errors keep the pointer; unknown field codes are '
        'invalid', () {
      final p = ApiProblem.parse(
        400,
        _body({
          'code': 'validation_failed',
          'errors': [
            {'pointer': '/name', 'code': 'too_long'},
            {'pointer': '/ageGroup', 'code': 'required'},
            {'pointer': '/x', 'code': 'something_new'},
            {'code': 'required'},
          ],
        }),
      );
      expect(p.fieldErrors, const [
        ApiFieldError('/name', FieldErrorKind.tooLong),
        ApiFieldError('/ageGroup', FieldErrorKind.required),
        ApiFieldError('/x', FieldErrorKind.invalid),
      ]);
    });

    test('NFR-14 the server title and detail are not kept', () {
      final p = ApiProblem.parse(409, _body({'code': 'consent_required'}));
      expect(p.toString(), isNot(contains('Developer')));
    });
  });

  group('ApiErrorText', () {
    for (final locale in const [Locale('id'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);

      test('NFR-16 [${locale.languageCode}] codes map to localized '
          'strings, never to server text', () {
        final rules = ApiErrorText.of(
          l10n,
          ProblemFailure(
            ApiProblem.parse(503, _body({'code': 'rules_unavailable'})),
          ),
        );
        expect(rules.title, l10n.errorRulesUnavailableTitle);
        expect(rules.body, l10n.errorRulesUnavailableBody);

        final unknown = ApiErrorText.of(
          l10n,
          ProblemFailure(ApiProblem.parse(418, _body({'code': 'teapot'}))),
        );
        expect(unknown.title, l10n.errorGenericTitle);
        expect(unknown.body, l10n.errorGenericBody);

        for (final failure in const [
          NetworkFailure(),
          DecodeFailure('x'),
          NotConfiguredFailure(),
        ]) {
          expect(ApiErrorText.of(l10n, failure).body, l10n.errorGenericBody);
        }

        final signedOut = ApiErrorText.of(
          l10n,
          ProblemFailure(
            ApiProblem.parse(401, _body({'code': 'refresh_token_invalid'})),
          ),
        );
        expect(signedOut.title, l10n.errorApiSignedOut);
        expect(signedOut.body, isNot(contains('Developer')));
      });

      test('NFR-16 [${locale.languageCode}] rate limit rounds up to whole '
          'minutes', () {
        final text = ApiErrorText.of(
          l10n,
          ProblemFailure(
            ApiProblem.parse(
              429,
              _body({'code': 'rate_limited', 'retryAfterSeconds': 61}),
            ),
          ),
        );
        expect(text.body, l10n.errorApiRateLimited(2));
      });

      test('NFR-16 [${locale.languageCode}] field errors', () {
        expect(
          ApiErrorText.field(l10n, FieldErrorKind.tooLong, maxLength: 30),
          l10n.errorFieldTooLong(30),
        );
        expect(
          ApiErrorText.field(l10n, FieldErrorKind.invalid, maxLength: 30),
          l10n.errorFieldInvalid,
        );
      });
    }

    test('NFR-16 retry minutes are at least 1', () {
      expect(ApiErrorText.retryMinutes(null), 1);
      expect(ApiErrorText.retryMinutes(0), 1);
      expect(ApiErrorText.retryMinutes(60), 1);
      expect(ApiErrorText.retryMinutes(61), 2);
    });
  });
}
