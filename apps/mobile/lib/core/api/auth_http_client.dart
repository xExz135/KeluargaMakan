// The HTTP client under the generated ApiClient: bearer auth from the
// session, a request timeout, and one silent refresh-and-retry when the API
// says the access token expired (contract-alignment.md 5: "Refresh silently
// once, then repeat the request").

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_problem.dart';
import 'session_manager.dart';

/// Endpoints with `security: []` in the contract. No bearer token is sent.
const _publicPaths = {
  '/v1/auth/code/request',
  '/v1/auth/code/verify',
  '/v1/auth/google',
  '/v1/auth/refresh',
};

/// Adds a timeout to every request and turns redirects off. Timeouts
/// surface as [http.ClientException], so they read as network failures.
///
/// The API never redirects. A redirect means a misconfigured proxy or a
/// captive portal, and following it could carry the bearer token or a
/// sign-in code to another host (security review L3). The 3xx answer is
/// returned as is, and ApiCaller treats it as a failure.
final class TimeoutClient extends http.BaseClient {
  TimeoutClient(this._inner, this.timeout);

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _inner
      .send(request..followRedirects = false)
      .timeout(
        timeout,
        onTimeout: () =>
            throw http.ClientException('Request timed out', request.url),
      );

  @override
  void close() => _inner.close();
}

final class AuthenticatingClient extends http.BaseClient {
  AuthenticatingClient({
    required http.Client inner,
    required this._session,
    required Duration timeout,
  }) : _inner = TimeoutClient(inner, timeout);

  final http.Client _inner;
  final SessionManager _session;

  static bool isPublic(Uri url) => _publicPaths.any(url.path.endsWith);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final tokens = _session.current;
    if (isPublic(request.url) || tokens == null) {
      request.headers.remove('authorization');
      return _inner.send(request);
    }

    // Only plain requests can be repeated; v0.1 sends nothing else.
    final retryBody = request is http.Request ? request.bodyBytes : null;
    request.headers['authorization'] = 'Bearer ${tokens.accessToken}';
    final first = await _inner.send(request);
    if (first.statusCode != 401 || retryBody == null) return first;

    final firstResponse = await http.Response.fromStream(first);
    final code = ApiProblem.parse(
      firstResponse.statusCode,
      utf8.decode(firstResponse.bodyBytes, allowMalformed: true),
    ).code;
    if (code != ApiErrorCode.accessTokenExpired &&
        code != ApiErrorCode.unauthenticated) {
      return _streamed(firstResponse);
    }

    final outcome = await _session.refreshAfterRejected(tokens.accessToken);
    switch (outcome) {
      case Refreshed(:final tokens):
        final retry = _copy(request as http.Request, retryBody)
          ..headers['authorization'] = 'Bearer ${tokens.accessToken}';
        return _inner.send(retry);
      case RefreshEndedSession(:final response):
        return _streamed(response ?? firstResponse);
      case RefreshFailed(:final response):
        return _streamed(response);
    }
  }

  static http.Request _copy(http.Request original, Uint8List body) {
    final copy = original is http.Abortable
        ? http.AbortableRequest(
            original.method,
            original.url,
            abortTrigger: (original as http.Abortable).abortTrigger,
          )
        : http.Request(original.method, original.url);
    copy
      ..headers.addAll(original.headers)
      ..followRedirects = false
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..bodyBytes = body;
    return copy;
  }

  static http.StreamedResponse _streamed(http.Response response) =>
      http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
        contentLength: response.bodyBytes.length,
        headers: response.headers,
        request: response.request,
        reasonPhrase: response.reasonPhrase,
      );

  @override
  void close() => _inner.close();
}
