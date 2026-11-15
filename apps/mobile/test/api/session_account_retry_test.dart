// Security review T-034 M1 (KIT-16, ACC-13, NFR-08): after a 401, the
// silent refresh-and-retry never repeats one account's request with
// another account's token, and a refresh answered after another sign-in
// neither restores the old account nor ends the new one.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keluargamakan/core/api/auth_http_client.dart';
import 'package:keluargamakan/core/api/session_manager.dart';
import 'package:keluargamakan/core/api/token_store.dart';

SessionTokens _t(String account, String access) => SessionTokens(
  accountId: account,
  accessToken: access,
  accessTokenExpiresAt: DateTime.utc(2030),
  refreshToken: 'r-$access',
  refreshTokenExpiresAt: DateTime.utc(2030),
);

http.Response _tokensBody(String access) => http.Response(
  jsonEncode({
    'tokenType': 'Bearer',
    'accessToken': access,
    'accessTokenExpiresAt': '2030-01-01T00:00:00Z',
    'refreshToken': 'r-$access',
    'refreshTokenExpiresAt': '2030-01-01T00:00:00Z',
  }),
  200,
);

const _body = '{"changes":[{"ingredient":{"customName":"Obat Nenek A"}}]}';
final _url = Uri.parse('https://api.test/v1/household/kitchen/sync');

void main() {
  /// A sends; the first answer (401) is held until B has signed in.
  Future<(http.Response, List<String>)> raceSignIn({
    required bool bound,
  }) async {
    final session = SessionManager(
      store: InMemoryTokenStore(_t('A', 'acc-A')),
      refresh: (_) async => http.Response('{}', 500),
    );
    await session.load();
    final first = Completer<void>();
    final release = Completer<void>();
    final seen = <String>[];
    final inner = MockClient((r) async {
      seen.add('${r.headers['authorization']} ${r.body}');
      if (seen.length == 1) {
        first.complete();
        await release.future;
        return http.Response(jsonEncode({'code': 'unauthenticated'}), 401);
      }
      return http.Response('{}', 200);
    });
    final client = AuthenticatingClient(
      inner: inner,
      session: session,
      timeout: const Duration(seconds: 20),
    );
    Future<http.Response> send() => client.post(_url, body: _body);
    final done = bound ? runAsAccount('A', send) : send();
    await first.future;
    await session.end(SessionEndReason.signedOut);
    await session.start(_t('B', 'acc-B'));
    release.complete();
    return (await done, seen);
  }

  test('KIT-16 ACC-13 M1 a sync bound to A that gets 401 after B signed in '
      "is never repeated with B's token", () async {
    final (response, seen) = await raceSignIn(bound: true);
    expect(response.statusCode, 401);
    expect(seen, ['Bearer acc-A $_body']);
    expect(seen.where((s) => s.contains('acc-B')), isEmpty);
  });

  test('ACC-13 M1 an unbound request that gets 401 after another sign-in is '
      "not repeated with the new account's token either", () async {
    final (response, seen) = await raceSignIn(bound: false);
    expect(response.statusCode, 401);
    expect(seen, hasLength(1));
    expect(seen.single, startsWith('Bearer acc-A'));
  });

  test('ACC-13 M1 a refresh answered after another account signed in '
      'neither restores the old tokens nor ends the new session', () async {
    final refreshAnswer = Completer<http.Response>();
    final session = SessionManager(
      store: InMemoryTokenStore(_t('A', 'acc-A')),
      refresh: (_) => refreshAnswer.future,
    );
    await session.load();
    final outcome = session.refreshAfterRejected('acc-A', accountId: 'A');
    await session.end(SessionEndReason.signedOut);
    await session.start(_t('B', 'acc-B'));
    var ended = false;
    session.ended.listen((_) => ended = true);
    // A's refresh fails late: B must stay signed in.
    refreshAnswer.complete(http.Response('{}', 401));
    expect(await outcome, isA<RefreshEndedSession>());
    await Future<void>.delayed(Duration.zero);
    expect(session.current?.accountId, 'B');
    expect(session.current?.accessToken, 'acc-B');
    expect(ended, isFalse);
  });

  test('ACC-13 M1 refreshAfterRejected never hands out another account\'s '
      'tokens', () async {
    final session = SessionManager(
      store: InMemoryTokenStore(_t('B', 'acc-B')),
      refresh: (_) async => _tokensBody('acc-B2'),
    );
    await session.load();
    expect(
      await session.refreshAfterRejected('acc-A', accountId: 'A'),
      isA<RefreshEndedSession>(),
    );
    // The same account still gets the newer tokens without a refresh.
    final same = await session.refreshAfterRejected('acc-old', accountId: 'B');
    expect((same as Refreshed).tokens.accessToken, 'acc-B');
  });

  test('ACC-13 the silent refresh still repeats a request for the same '
      'account', () async {
    final session = SessionManager(
      store: InMemoryTokenStore(_t('A', 'acc-A')),
      refresh: (_) async => _tokensBody('acc-A2'),
    );
    await session.load();
    final seen = <String?>[];
    final inner = MockClient((r) async {
      seen.add(r.headers['authorization']);
      return seen.length == 1
          ? http.Response(jsonEncode({'code': 'access_token_expired'}), 401)
          : http.Response('{}', 200);
    });
    final client = AuthenticatingClient(
      inner: inner,
      session: session,
      timeout: const Duration(seconds: 20),
    );
    final response = await runAsAccount(
      'A',
      () => client.post(_url, body: _body),
    );
    expect(response.statusCode, 200);
    expect(seen, ['Bearer acc-A', 'Bearer acc-A2']);
  });

  test('ACC-13 I1 a new session never joins a refresh still on its way for '
      'the previous one', () async {
    final aAnswer = Completer<http.Response>();
    final asked = <String>[];
    final session = SessionManager(
      store: InMemoryTokenStore(_t('A', 'acc-A')),
      refresh: (refreshToken) {
        asked.add(refreshToken);
        return refreshToken == 'r-acc-A'
            ? aAnswer.future
            : Future.value(_tokensBody('acc-B2'));
      },
    );
    await session.load();
    final forA = session.refreshAfterRejected('acc-A', accountId: 'A');
    await session.end(SessionEndReason.signedOut);
    await session.start(_t('B', 'acc-B'));

    // B's first 401 gets its own refresh, not A's.
    final forB = await session.refreshAfterRejected('acc-B', accountId: 'B');
    expect((forB as Refreshed).tokens.accessToken, 'acc-B2');
    expect(asked, ['r-acc-A', 'r-acc-B']);

    // A's late answer changes nothing for B, and does not clear a refresh
    // B starts afterwards.
    aAnswer.complete(_tokensBody('acc-A2'));
    expect(await forA, isA<RefreshEndedSession>());
    expect(session.current?.accessToken, 'acc-B2');
  });
}
