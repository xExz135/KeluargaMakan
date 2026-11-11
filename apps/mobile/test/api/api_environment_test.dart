// NFR-08 and security review M1: release builds talk to the API over https
// only; debug builds may use http for a local server.

import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_result.dart';

import '../helpers/api_fixtures.dart';

ApiEnvironment _env(String url, {required bool debug}) =>
    ApiEnvironment(Uri.parse(url), debugBuild: debug);

void main() {
  group('release and profile builds', () {
    test('NFR-08 https is accepted', () {
      expect(_env('https://api.example.id', debug: false).isConfigured, isTrue);
      expect(
        _env('https://api.example.id/base/', debug: false).basePath,
        'https://api.example.id/base',
      );
    });

    test('NFR-08 http is refused, even for localhost', () {
      for (final url in [
        'http://api.example.id',
        'http://staging.example.id',
        'http://localhost:3000',
        'http://10.0.2.2:3000',
        'http://127.0.0.1',
      ]) {
        expect(_env(url, debug: false).isConfigured, isFalse, reason: url);
      }
    });
  });

  group('debug builds', () {
    test('NFR-08 http is allowed only for localhost and the emulator '
        'host', () {
      for (final url in [
        'http://localhost:3000',
        'http://127.0.0.1:3000',
        'http://10.0.2.2:3000',
      ]) {
        expect(_env(url, debug: true).isConfigured, isTrue, reason: url);
      }
      for (final url in [
        'http://api.example.id',
        'http://192.168.1.20:3000',
        'http://10.0.2.3',
      ]) {
        expect(_env(url, debug: true).isConfigured, isFalse, reason: url);
      }
    });
  });

  test('NFR-08 other schemes, credentials in the URL and empty values are '
      'refused', () {
    for (final debug in [true, false]) {
      for (final url in [
        '',
        'ftp://api.example.id',
        'api.example.id',
        'https://user:pass@api.example.id',
        'https://',
      ]) {
        expect(_env(url, debug: debug).isConfigured, isFalse, reason: url);
      }
    }
  });

  test('NFR-08 tests and this suite run as debug builds', () {
    expect(ApiEnvironment(Uri.parse('http://localhost')).isConfigured, isTrue);
  });

  test('NFR-08 a refused URL sends nothing', () async {
    final sent = <Uri>[];
    final c = testContainer(
      handler: (r) async {
        sent.add(r.url);
        return jsonResponse(accountJson());
      },
      baseUrl: 'http://api.example.id',
    );
    addTearDown(c.dispose);
    final result = await c
        .read(apiCallerProvider)
        .callNoContent(
          'probe',
          () => c
              .read(apiClientProvider)
              .invokeAPI('/v1/account', 'GET', [], null, {}, {}, null),
        );
    expect(failureOf(result), isA<NotConfiguredFailure>());
    expect(sent, isEmpty);
  });
}
